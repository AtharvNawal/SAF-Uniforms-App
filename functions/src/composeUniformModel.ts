/**
 * Composes a per-user 3D uniform model on the server.
 *
 * Pipeline:
 *   1. Authn / authz / shape validation.
 *   2. Read the user's `users/{uid}/profile/current` document.
 *   3. Recompute the canonical `profileHash` server-side; reject mismatches.
 *   4. Idempotency short-circuit: if `generatedDresses[dressCode]` already
 *      has a matching hash and a Storage object, return the existing URL.
 *   5. Resolve the accessory list (port of `DressAccessoryResolver`).
 *   6. Download the body / uniform / accessory GLBs from Storage.
 *      Missing assets fall back to `models/placeholder.glb`.
 *   7. Merge them into a single Document with @gltf-transform.
 *   8. Write the composed GLB to `user_models/{uid}/{dressCode}.glb`.
 *   9. Update Firestore generatedDresses[dressCode] with the new
 *      `modelUrl` + `profileHash` + `builtAt` + `schemaVersion`, and
 *      clear `generationStartedAt` / `error`.
 *
 * Phase 1 leaves the heavy compression (Draco, KTX2) and the name-tag
 * texture bake as TODOs — the placeholder GLBs are small enough that
 * we don't need them yet, and the pipeline ships end-to-end without.
 */

import { randomUUID } from "crypto";

import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { z } from "zod";

import { Document } from "@gltf-transform/core";

import {
  AccessoryRecord,
  DressRequirementRecord,
  ResolverProfile,
  Branch,
  Gender,
  RankCode,
  resolveAccessorySplit,
  ResolvedAccessory,
} from "./dress_accessory_resolver";
import { computeProfileHash, MODEL_BUNDLE_VERSION } from "./profile_hash";
import {
  attachAccessory,
  bakeNameTag,
  compressForWeb,
  createComposeIO,
  detachNodeByName,
  FEET_NODE,
  HAIR_NODE,
  mergeUniform,
  NAME_TAG_MATERIAL,
} from "./glb_compose";

const SCHEMA_VERSION = 1;

const DRESS_CODES = ["No1", "No2", "No3", "No4", "No5"] as const;
type DressCode = (typeof DRESS_CODES)[number];

const Request = z.object({
  dressCode: z.enum(DRESS_CODES),
  profileHash: z.string().min(8).max(64),
});

/** Map `DressCode` wire name → `dress_requirements` doc id. */
function dressDocId(code: DressCode): string {
  return {
    No1: "no_1_dress_requirements",
    No2: "no_2_dress_requirements",
    No3: "no_3_dress_requirements",
    No4: "no_4_dress_requirements",
    No5: "no_5_dress_requirements",
  }[code];
}

/** Lowercase token used in Storage paths, e.g. `no3`. */
function dressSlug(code: DressCode): string {
  return code.toLowerCase();
}

/** Body-asset filename token. Maternity uses its own body. */
function bodyKey(gender: Gender): string {
  if (gender === "maternity") return "female_maternity";
  return gender === "female" ? "female" : "male";
}

/**
 * Coerces a possibly-missing centimetre offset from `accessory.render_logic`
 * into metres. Strings are tolerated because Firestore numeric fields can
 * round-trip as either `number` or `string` depending on how they were
 * authored.
 */
function cmToMeters(raw: unknown): number {
  const n =
    typeof raw === "number"
      ? raw
      : typeof raw === "string"
        ? Number(raw)
        : 0;
  return Number.isFinite(n) ? n / 100 : 0;
}

/**
 * Returns the surname portion of `fullName` for the name-tag bake.
 * SAF doctrine puts the surname (in caps) on the chest patch; the rest
 * of the name is irrelevant to the embroidered tag. The picker is
 * intentionally simple: the last whitespace-separated token, uppercased.
 * Falls back to the trimmed input when no whitespace is present.
 */
function pickSurname(fullName: string): string {
  const trimmed = fullName.trim();
  if (!trimmed) return "";
  const parts = trimmed.split(/\s+/);
  return (parts[parts.length - 1] ?? trimmed).toUpperCase();
}

/**
 * Maps an accessory's `render_logic` blob to the body socket name the
 * merger should attach under. Handles three schema cases the
 * accessory_library uses interchangeably:
 *
 * - **Direct `anchor`** (most accessories): just return it.
 * - **`side: "left" | "right"`** (lanyards): map to the left/right
 *   shoulder seam — lanyards drape from one shoulder.
 * - **No anchor / side at all** (medal_ribbons, saf_badges_chest,
 *   foreign_badges, name_tag_*): return `null`. Caller logs + skips.
 */
function resolveAccessoryAnchor(
  renderLogic: Record<string, unknown>,
): string | null {
  const anchor = renderLogic["anchor"];
  if (typeof anchor === "string" && anchor.length > 0) return anchor;
  const side = renderLogic["side"];
  if (side === "right") return "right_shoulder_seam";
  if (side === "left") return "left_shoulder_seam";
  return null;
}

interface ProfileDoc {
  branch: Branch;
  rank: RankCode;
  gender: Gender;
  dressCode: DressCode;
  isSikh: boolean;
  fullName: string;
  vocation: string;
  medalRowCount: number;
  selectedBadgeIds: string[];
  selectedAccessoryIds: string[];
  dressAccessoryChecks: Record<string, string[]>;
  generatedDresses: Record<string, Record<string, unknown>>;
}

function readProfile(raw: Record<string, unknown> | undefined): ProfileDoc {
  if (!raw) {
    throw new HttpsError("not-found", "Profile document is missing.");
  }
  const branch = raw["branch"] as Branch;
  const rank = raw["rank"] as RankCode;
  const gender = (raw["gender"] as Gender) ?? "male";
  const dressCode = raw["dressCode"] as DressCode;
  if (!branch || !rank || !dressCode) {
    throw new HttpsError(
      "failed-precondition",
      "Profile is missing required fields (branch / rank / dressCode).",
    );
  }
  return {
    branch,
    rank,
    gender,
    dressCode,
    isSikh: (raw["isSikh"] as boolean | undefined) ?? false,
    fullName: (raw["fullName"] as string | undefined) ?? "",
    vocation: (raw["vocation"] as string | undefined) ?? "Infantry",
    medalRowCount: Number(raw["medalRowCount"] ?? 0),
    selectedBadgeIds: ((raw["selectedBadgeIds"] as string[]) ?? []).slice(),
    selectedAccessoryIds: ((raw["selectedAccessoryIds"] as string[]) ?? []).slice(),
    dressAccessoryChecks: normaliseDressChecks(raw["dressAccessoryChecks"]),
    generatedDresses:
      (raw["generatedDresses"] as Record<string, Record<string, unknown>>) ??
      {},
  };
}

function normaliseDressChecks(raw: unknown): Record<string, string[]> {
  if (!raw || typeof raw !== "object") return {};
  const out: Record<string, string[]> = {};
  for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
    if (Array.isArray(v)) {
      out[k] = v.filter((x): x is string => typeof x === "string");
    }
  }
  return out;
}

/**
 * Loads a GLB from Storage. Returns `null` when the object is missing
 * so callers can fall back to a placeholder.
 */
async function tryLoadGlb(bucketName: string, objectPath: string):
  Promise<Buffer | null> {
  const file = getStorage().bucket(bucketName).file(objectPath);
  try {
    const [exists] = await file.exists();
    if (!exists) return null;
    const [buffer] = await file.download();
    return buffer;
  } catch (e) {
    logger.warn("tryLoadGlb failed", { objectPath, error: (e as Error).message });
    return null;
  }
}

export const composeUniformModel = onCall(
  {
    region: "asia-southeast1",
    memory: "2GiB",
    timeoutSeconds: 120,
    maxInstances: 50,
    // Required so the underlying Cloud Run service is invokable by
    // anonymous HTTPS callers (the Firebase callable client sends a
    // Bearer ID token in the body, not as Cloud Run auth — Firebase
    // Auth is enforced inside the function via `req.auth`). Without
    // this, requests fail at the Cloud Run layer with
    // `UNAUTHENTICATED` before the function code ever runs. Firebase
    // normally sets this automatically on first create, but if the
    // first deploy failed at the build stage (as ours did due to the
    // Cloud Build IAM gap), the auto-grant is skipped and a redeploy
    // alone won't fix it. Declaring it here makes the binding part
    // of the function's desired state.
    invoker: "public",
  },
  async (req) => {
    // Diagnostic: dump what the callable wrapper handed us. If the
    // client sent an Authorization header with a Firebase ID token,
    // `req.auth` should be populated with `{uid, token}`. Headers
    // are also dumped (with the actual JWT redacted) so we can
    // distinguish "no header sent" from "header sent but rejected".
    const headers = req.rawRequest?.headers ?? {};
    const authHeaderRaw = (headers["authorization"] ??
      headers["Authorization"]) as string | undefined;
    const authHeader = authHeaderRaw
      ? authHeaderRaw.length > 30
        ? `${authHeaderRaw.slice(0, 14)}…${authHeaderRaw.slice(-6)} (${authHeaderRaw.length} chars)`
        : authHeaderRaw
      : "(none)";
    logger.info("composeUniformModel: incoming", {
      hasReqAuth: !!req.auth,
      reqAuthUid: req.auth?.uid ?? null,
      authHeaderPreview: authHeader,
      hasAppCheck: !!req.app,
      origin: headers["origin"] ?? null,
      ua: (headers["user-agent"] as string | undefined)?.slice(0, 80) ?? null,
    });

    if (!req.auth) {
      logger.warn("composeUniformModel: rejected (no auth)", {
        ua: (headers["user-agent"] as string | undefined)?.slice(0, 80) ?? null,
      });
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }
    const uid = req.auth.uid;

    const parsed = Request.safeParse(req.data);
    if (!parsed.success) {
      logger.warn("composeUniformModel: rejected (bad request)", {
        uid,
        issue: parsed.error.message,
      });
      throw new HttpsError("invalid-argument", parsed.error.message);
    }
    const { dressCode, profileHash: clientHash } = parsed.data;

    const db = getFirestore();
    const profileRef = db.doc(`users/${uid}/profile/current`);
    const profileSnap = await profileRef.get();
    const profile = readProfile(profileSnap.data() as Record<string, unknown>);

    const dressDoc = dressDocId(dressCode);
    const dressChecks = profile.dressAccessoryChecks[dressDoc] ?? [];

    const expectedHash = computeProfileHash({
      branch: profile.branch,
      rank: profile.rank,
      gender: profile.gender,
      dressCode,
      isSikh: profile.isSikh,
      fullName: profile.fullName,
      vocation: profile.vocation,
      medalRowCount: profile.medalRowCount,
      selectedBadgeIds: profile.selectedBadgeIds,
      selectedAccessoryIds: profile.selectedAccessoryIds,
      dressChecks,
    });

    if (expectedHash !== clientHash) {
      // The most common cause is that the Flutter app's binary still has
      // an older kModelBundleVersion baked in — the Dart constant is
      // compile-time, so editing profile_hash.dart without
      // rebuild+reinstall leaves the existing install on the previous
      // bundle. Surface both hashes + the server bundle so operators can
      // tell at a glance.
      logger.warn(
        "composeUniformModel: rejected (hash mismatch — client likely stale; rebuild Flutter app to pick up new kModelBundleVersion)",
        {
          uid,
          dressCode,
          clientHash,
          expectedHash,
          serverBundle: MODEL_BUNDLE_VERSION,
        },
      );
      throw new HttpsError(
        "failed-precondition",
        `Stale request: client hash ${clientHash} but server hash ${expectedHash}.`,
      );
    }

    // Idempotency: if the cached entry already matches, skip the work.
    const existing = profile.generatedDresses[dressDoc];
    const existingUrl = existing?.["modelUrl"] as string | undefined;
    const existingHash = existing?.["profileHash"] as string | undefined;
    const existingSchema = existing?.["schemaVersion"] as number | undefined;
    if (
      existingUrl &&
      existingHash === expectedHash &&
      existingSchema === SCHEMA_VERSION
    ) {
      logger.info("composeUniformModel: cache hit", { uid, dressCode });
      return {
        modelUrl: existingUrl,
        profileHash: expectedHash,
        schemaVersion: SCHEMA_VERSION,
      };
    }

    // Mark in-flight on the server side too (in case the client never
    // optimistically set it). Visible to the hydrated-profile stream.
    await profileRef.set(
      {
        generatedDresses: {
          [dressDoc]: {
            generationStartedAt: Date.now(),
            error: null,
          },
        },
      },
      { merge: true },
    );

    try {
      // Resolve which accessory ids apply to this profile.
      const reqRef = db.doc(`dress_requirements/${dressDoc}`);
      const reqSnap = await reqRef.get();
      const reqRaw = reqSnap.data() as Record<string, unknown> | undefined;
      const requirement: DressRequirementRecord = {
        id: dressDoc,
        branch_overrides:
          (reqRaw?.["branch_overrides"] as Record<
            string,
            Record<string, unknown>
          >) ?? {},
      };

      const libSnap = await db.collection("accessory_library").get();
      const library: AccessoryRecord[] = libSnap.docs.map((d) => ({
        id: d.id,
        ...(d.data() as Omit<AccessoryRecord, "id">),
      }));

      const resolverProfile: ResolverProfile = {
        branch: profile.branch,
        rank: profile.rank,
        gender: profile.gender,
        isSikh: profile.isSikh,
      };
      const split = resolveAccessorySplit(requirement, library, resolverProfile);

      // Mandatory accessories are always included; optional accessories
      // are only included when the user has ticked them in the
      // wardrobe checklist.
      const checkedSet = new Set(dressChecks);
      const optionalChecked = split.optional.filter((a) => checkedSet.has(a.id));

      logger.info("composeUniformModel: resolved", {
        uid,
        dressCode,
        accessoryCount: split.mandatory.length + optionalChecked.length,
        bundleVersion: MODEL_BUNDLE_VERSION,
      });

      // Asset library lives in the default bucket.
      const bucket = getStorage().bucket();
      const bucketName = bucket.name;
      const io = await createComposeIO();

      // PHASE 2 COMPOSITION pipeline:
      //   body  ── mergeUniform(uniform)?  ── attachAccessory(...)  ── bakeNameTag  ── compressForWeb
      //
      // Preferred "unified" path: a single GLB at
      //   models/bodies/{branch}_{dressCode}_{gender}.glb
      // carries the full dressed figure (shirt + trousers + body + sockets),
      // so the mergeUniform step is skipped entirely. The legacy "separate"
      // path (generic naked body at models/bodies/{gender}_apose.glb plus a
      // shirt-only overlay at models/uniforms/...) is used as a fallback for
      // branches / dress-codes that have not yet been re-generated as unified
      // figures.
      //
      // Each step is wrapped in a try/catch so a single bad artist
      // delivery (missing socket, malformed GLB, sharp failure)
      // degrades gracefully rather than failing the whole composition.
      const unifiedBodyPath = `models/bodies/${profile.branch}_${dressSlug(dressCode)}_${bodyKey(profile.gender)}.glb`;
      const legacyBodyPath = `models/bodies/${bodyKey(profile.gender)}_apose.glb`;
      const uniformPath = `models/uniforms/${profile.branch}_${dressSlug(dressCode)}_${bodyKey(profile.gender)}.glb`;

      // Compose the full ordered list of accessories that should land on
      // the model: mandatory (always) + optional that the user ticked.
      const includeAccessories: ResolvedAccessory[] = [
        ...split.mandatory,
        ...optionalChecked,
      ];

      // ---- 1. Body ----
      // Unified dressed-figure takes precedence. Falls back to the legacy
      // generic naked body when no branch-dress-gender-specific figure exists.
      let bodyBytes = await tryLoadGlb(bucketName, unifiedBodyPath);
      const isUnified = bodyBytes !== null;
      if (!isUnified) {
        bodyBytes = await tryLoadGlb(bucketName, legacyBodyPath);
      }
      if (!bodyBytes) {
        logger.warn("body GLB missing; falling back to placeholder", {
          unifiedBodyPath,
          legacyBodyPath,
        });
        bodyBytes = await tryLoadGlb(bucketName, "models/placeholder.glb");
      }
      if (!bodyBytes) {
        const emptyDoc = new Document();
        emptyDoc.createScene("empty");
        bodyBytes = Buffer.from(await io.writeBinary(emptyDoc));
      }
      const bodyDoc = await io.readBinary(new Uint8Array(bodyBytes));

      logger.info("composeUniformModel: planned assets", {
        uid,
        bodyPath: isUnified ? unifiedBodyPath : legacyBodyPath,
        isUnified,
        uniformPath: isUnified
          ? "(skipped — baked into unified figure)"
          : uniformPath,
        accessoryPaths: includeAccessories.map(
          (a) => `models/accessories/${a.id}.glb`,
        ),
      });

      // ---- 2. Uniform merge (legacy path only) ----
      // Skipped when a unified dressed-figure was found above, since the
      // shirt and trousers are already part of that mesh.
      if (!isUnified) {
        try {
          const uniformBytes = await tryLoadGlb(bucketName, uniformPath);
          if (uniformBytes) {
            const uniformDoc = await io.readBinary(new Uint8Array(uniformBytes));
            mergeUniform(bodyDoc, uniformDoc);
          } else {
            logger.warn("uniform GLB missing; body-only composition", {
              uniformPath,
            });
          }
        } catch (e) {
          logger.warn("uniform merge failed; body-only composition", {
            uniformPath,
            error: (e as Error).message,
          });
        }
      }

      // ---- 3. Headdress check + hair detach ----
      const headdressMounted = includeAccessories.some(
        (a) =>
          (a.record.render_logic?.["anchor"] as string | undefined) ===
          "head_top",
      );
      if (headdressMounted) {
        const detached = detachNodeByName(bodyDoc, HAIR_NODE);
        logger.info("hair detach (headdress mounted)", {
          headdressMounted,
          detached,
        });
      }

      // ---- 3b. Footwear check + feet detach ----
      // The body GLB ships with the bare-foot vertices sliced out as a
      // dedicated `feet` sub-mesh node. When any footwear accessory is
      // about to mount we drop those toes so skin-coloured geometry
      // doesn't poke through the shoe mesh.
      const feetCovered = includeAccessories.some(
        (a) => (a.record.category ?? "") === "footwear",
      );
      if (feetCovered) {
        const detached = detachNodeByName(bodyDoc, FEET_NODE);
        logger.info("feet detach (footwear mounted)", {
          feetCovered,
          detached,
        });
      }

      // ---- 4. Per-accessory merge + re-parent under socket ----
      for (const acc of includeAccessories) {
        // Filter: name-tag accessories are handled by the bake step
        // below (sharp composites the surname onto the body's
        // name_tag_mat material). Attaching a separate name-tag GLB
        // here would z-fight with the baked patch on the body.
        if ((acc.record.category ?? "") === "name_tag") {
          logger.info("skipping name_tag accessory (handled by bake step)", {
            accId: acc.id,
          });
          continue;
        }

        const accPath = `models/accessories/${acc.id}.glb`;
        try {
          const accBytes = await tryLoadGlb(bucketName, accPath);
          if (!accBytes) {
            logger.warn("accessory GLB missing; skipping", {
              accId: acc.id,
              accPath,
            });
            continue;
          }
          const accDoc = await io.readBinary(new Uint8Array(accBytes));
          const renderLogic =
            (acc.record.render_logic as Record<string, unknown> | undefined) ??
            {};
          const socketName = resolveAccessoryAnchor(renderLogic);
          if (!socketName) {
            logger.warn(
              "accessory has no render_logic.anchor / side; skipping",
              { accId: acc.id, renderLogicKeys: Object.keys(renderLogic) },
            );
            continue;
          }
          const offsetMeters: [number, number, number] = [
            cmToMeters(renderLogic["offset_x_cm"]),
            cmToMeters(renderLogic["offset_y_cm"]),
            cmToMeters(renderLogic["offset_z_cm"]),
          ];
          const mirror = renderLogic["mirror_left_right"] === true;
          const result = attachAccessory(
            bodyDoc,
            accDoc,
            socketName,
            offsetMeters,
            { mirror },
          );
          if (result.attached) {
            logger.info(
              `accessory ${mirror ? "mirrored" : "attached"}: ${acc.id}`,
              {
                accId: acc.id,
                socketName,
                sockets: result.sockets,
                mirror,
                rootsAttached: result.rootsAttached,
              },
            );
          } else {
            logger.warn("accessory attach failed", {
              accId: acc.id,
              socketName,
              mirror,
              reason: result.reason,
            });
          }
        } catch (e) {
          logger.warn("accessory load/merge threw; skipping", {
            accId: acc.id,
            error: (e as Error).message,
          });
        }
      }

      // ---- 5. Name-tag bake ----
      if (profile.fullName) {
        try {
          const surname = pickSurname(profile.fullName);
          const baked = await bakeNameTag(bodyDoc, NAME_TAG_MATERIAL, surname);
          logger.info("name tag bake", {
            material: NAME_TAG_MATERIAL,
            surname,
            baked,
          });
        } catch (e) {
          logger.warn("name tag bake failed", {
            error: (e as Error).message,
          });
        }
      }

      // ---- 6. Compression (best-effort) ----
      let compressionResult = { dracoApplied: false, webpApplied: false };
      try {
        compressionResult = await compressForWeb(bodyDoc);
      } catch (e) {
        logger.warn("compressForWeb threw; uploading uncompressed", {
          error: (e as Error).message,
        });
      }
      logger.info("compression result", compressionResult);

      const composedBytes = await io.writeBinary(bodyDoc);

      // Upload to Storage with a download token so the client can
      // fetch via the public download URL pattern (matches the
      // existing accessory image convention).
      const token = randomUUID();
      const objectPath = `user_models/${uid}/${dressCode}.glb`;
      const file = bucket.file(objectPath);
      await file.save(Buffer.from(composedBytes), {
        contentType: "model/gltf-binary",
        metadata: {
          cacheControl: "private, max-age=86400",
          metadata: {
            firebaseStorageDownloadTokens: token,
            profileHash: expectedHash,
            schemaVersion: String(SCHEMA_VERSION),
            bundleVersion: String(MODEL_BUNDLE_VERSION),
          },
        },
      });
      const downloadUrl =
        `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
        encodeURIComponent(objectPath) +
        `?alt=media&token=${token}`;

      // Update Firestore atomically: write the new entry verbatim so
      // any stale fields (error, generationStartedAt) are cleared.
      const newEntry = {
        builtAt: Date.now(),
        modelUrl: downloadUrl,
        profileHash: expectedHash,
        schemaVersion: SCHEMA_VERSION,
      };
      const otherDresses: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(profile.generatedDresses)) {
        if (k !== dressDoc) otherDresses[k] = v;
      }
      await profileRef.set(
        {
          generatedDresses: {
            ...otherDresses,
            [dressDoc]: newEntry,
          },
        },
        { merge: true },
      );

      logger.info("composeUniformModel: done", {
        uid,
        dressCode,
        bytes: composedBytes.byteLength,
        accessoryCount: includeAccessories.length,
      });

      return {
        modelUrl: downloadUrl,
        profileHash: expectedHash,
        schemaVersion: SCHEMA_VERSION,
      };
    } catch (e) {
      logger.error("composeUniformModel: failed", {
        uid,
        dressCode,
        error: (e as Error).message,
      });
      // Persist the error on the entry so the UI can surface it.
      await profileRef.set(
        {
          generatedDresses: {
            [dressDoc]: {
              error: (e as Error).message,
              generationStartedAt: null,
            },
          },
        },
        { merge: true },
      );
      throw new HttpsError("internal", `Compose failed: ${(e as Error).message}`);
    }
  },
);
