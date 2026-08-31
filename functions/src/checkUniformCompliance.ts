/**
 * Compares a user-submitted photo against the accessories the system
 * already expects for their branch/rank/gender/dress code — the exact
 * same list `composeUniformModel` resolves to build the 3D GLB — and
 * asks a Claude vision model to report what's correctly worn and what
 * isn't.
 *
 * This is intentionally NOT a pixel/geometry comparison against the
 * composed GLB: aligning a real photo's camera angle against a 3D
 * render is a hard problem on its own (see
 * `ChangeRequest/2026-07-30_ai-uniform-compliance-check.md` for the
 * alternatives considered). Instead the model gets:
 *   - the user's photo,
 *   - the resolved expected-accessory list (display name + category),
 *   - a best-effort reference image per accessory (from
 *     `accessory_library/{id}.image_url`), when fetchable,
 * and returns a structured verdict via forced tool-use so the response
 * shape is guaranteed rather than parsed out of prose.
 *
 * Nothing is persisted — the result is returned directly to the caller
 * and discarded once the client is done with it.
 */

import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import { z } from "zod";

import Anthropic from "@anthropic-ai/sdk";

import {
  AccessoryRecord,
  Branch,
  DressRequirementRecord,
  Gender,
  RankCode,
  ResolvedAccessory,
  ResolverProfile,
  resolveAccessorySplit,
} from "./dress_accessory_resolver";

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

const DRESS_CODES = ["No1", "No2", "No3", "No4", "No5"] as const;
type DressCode = (typeof DRESS_CODES)[number];

const MODEL = "claude-sonnet-5";
const MAX_REFERENCE_IMAGES = 8;

const Request = z.object({
  dressCode: z.enum(DRESS_CODES),
  photoBase64: z.string().min(100),
  mimeType: z.enum(["image/jpeg", "image/png"]),
});

const ComplianceItemStatus = z.enum([
  "correct",
  "missing",
  "incorrect",
  "uncertain",
]);

export const ComplianceResponse = z.object({
  overallScore: z.number().min(0).max(100),
  summary: z.string().min(1),
  items: z.array(
    z.object({
      accessoryId: z.string(),
      displayName: z.string(),
      status: ComplianceItemStatus,
      note: z.string(),
    }),
  ),
});

export type ComplianceResponse = z.infer<typeof ComplianceResponse>;

function dressDocId(code: DressCode): string {
  return {
    No1: "no_1_dress_requirements",
    No2: "no_2_dress_requirements",
    No3: "no_3_dress_requirements",
    No4: "no_4_dress_requirements",
    No5: "no_5_dress_requirements",
  }[code];
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

interface ProfileDoc {
  branch: Branch;
  rank: RankCode;
  gender: Gender;
  isSikh: boolean;
  dressAccessoryChecks: Record<string, string[]>;
}

// TRIAL ONLY — the "Profile document is missing" / "missing required
// fields" guards below are commented out so this function can be
// exercised without completing the Configuration wizard first. Falls
// back to a fixed army/specialist/male profile instead of rejecting.
// Re-enable the throws before any real use: without them, a compliance
// check silently runs against a fabricated profile instead of the
// user's actual branch/rank, so results are not meaningful. See the
// conversation this was added in and
// ChangeRequest/2026-08-11_config-profile-save-failure-fix.md for why
// these guards exist in the first place.
const _TRIAL_DEFAULT_PROFILE: Pick<ProfileDoc, "branch" | "rank"> = {
  branch: "army",
  rank: "CPL",
};

function readProfile(raw: Record<string, unknown> | undefined): ProfileDoc {
  // if (!raw) {
  //   throw new HttpsError("not-found", "Profile document is missing.");
  // }
  raw = raw ?? {};
  const branch = (raw["branch"] as Branch) ?? _TRIAL_DEFAULT_PROFILE.branch;
  const rank = (raw["rank"] as RankCode) ?? _TRIAL_DEFAULT_PROFILE.rank;
  // if (!branch || !rank) {
  //   throw new HttpsError(
  //     "failed-precondition",
  //     "Profile is missing required fields (branch / rank).",
  //   );
  // }
  return {
    branch,
    rank,
    gender: (raw["gender"] as Gender) ?? "male",
    isSikh: (raw["isSikh"] as boolean | undefined) ?? false,
    dressAccessoryChecks: normaliseDressChecks(raw["dressAccessoryChecks"]),
  };
}

/**
 * Best-effort fetch of an accessory's reference image from Storage.
 * Returns `null` (never throws) so a single bad/missing image degrades
 * to a text-only description for that accessory instead of failing the
 * whole compliance check.
 */
async function tryFetchReferenceImage(
  bucketName: string,
  accessoryId: string,
): Promise<{ data: string; mimeType: "image/png" } | null> {
  const objectPath = `accessories/${accessoryId}/image.png`;
  try {
    const file = getStorage().bucket(bucketName).file(objectPath);
    const [exists] = await file.exists();
    if (!exists) return null;
    const [buffer] = await file.download();
    return { data: buffer.toString("base64"), mimeType: "image/png" };
  } catch (e) {
    logger.warn("tryFetchReferenceImage failed", {
      accessoryId,
      objectPath,
      error: (e as Error).message,
    });
    return null;
  }
}

const REPORT_TOOL_NAME = "report_compliance";

const REPORT_TOOL: Anthropic.Tool = {
  name: REPORT_TOOL_NAME,
  description:
    "Report the uniform compliance verdict for the submitted photo, one entry per expected accessory.",
  input_schema: {
    type: "object",
    properties: {
      overallScore: {
        type: "number",
        description: "Overall compliance score 0-100.",
      },
      summary: {
        type: "string",
        description: "One or two sentence plain-English verdict.",
      },
      items: {
        type: "array",
        items: {
          type: "object",
          properties: {
            accessoryId: { type: "string" },
            displayName: { type: "string" },
            status: {
              type: "string",
              enum: ["correct", "missing", "incorrect", "uncertain"],
            },
            note: {
              type: "string",
              description: "Why this status was given.",
            },
          },
          required: ["accessoryId", "displayName", "status", "note"],
        },
      },
    },
    required: ["overallScore", "summary", "items"],
  },
};

export function buildPromptText(expected: ResolvedAccessory[]): string {
  const lines = expected.map((a) => {
    const name = a.record.display_name ?? a.id;
    const category = a.record.category ?? "unknown";
    return `- id="${a.id}" name="${name}" category="${category}"`;
  });
  return (
    "You are inspecting a photo of a Singapore Armed Forces (SAF) soldier " +
    "for uniform compliance. The first image is the photo to inspect. Any " +
    "subsequent images are reference photos of the specific accessories " +
    "expected on this uniform (each reference image is preceded by a text " +
    "label naming the accessory it shows).\n\n" +
    "Expected accessories for this dress code:\n" +
    `${lines.join("\n")}\n\n` +
    "For EVERY expected accessory listed above, decide whether it is " +
    "clearly present and correctly worn (\"correct\"), clearly absent " +
    "(\"missing\"), present but wrong in some way — wrong position, wrong " +
    "item, damaged, mis-worn — (\"incorrect\"), or impossible to judge " +
    "from this photo, e.g. occluded/out of frame/blurry (\"uncertain\"). " +
    "Do not invent accessories that were not listed. Call the " +
    `${REPORT_TOOL_NAME} tool with your verdict.`
  );
}

export const checkUniformCompliance = onCall(
  {
    region: "asia-southeast1",
    secrets: [ANTHROPIC_API_KEY],
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (req) => {
    if (!req.auth) {
      logger.warn("checkUniformCompliance: rejected (no auth)");
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }
    const uid = req.auth.uid;

    const parsed = Request.safeParse(req.data);
    if (!parsed.success) {
      logger.warn("checkUniformCompliance: rejected (bad request)", {
        uid,
        issue: parsed.error.message,
      });
      throw new HttpsError("invalid-argument", parsed.error.message);
    }
    const { dressCode, photoBase64, mimeType } = parsed.data;

    logger.info("checkUniformCompliance: start", { uid, dressCode });

    try {
      const db = getFirestore();

      const profileSnap = await db.doc(`users/${uid}/profile/current`).get();
      const profile = readProfile(
        profileSnap.data() as Record<string, unknown>,
      );

      const dressDoc = dressDocId(dressCode);
      const dressChecks = profile.dressAccessoryChecks[dressDoc] ?? [];

      const reqSnap = await db.doc(`dress_requirements/${dressDoc}`).get();
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
      const checkedSet = new Set(dressChecks);
      const optionalChecked = split.optional.filter((a) =>
        checkedSet.has(a.id),
      );
      const expected: ResolvedAccessory[] = [
        ...split.mandatory,
        ...optionalChecked,
      ];

      logger.debug("checkUniformCompliance: resolved accessories", {
        uid,
        dressCode,
        accessoryIds: expected.map((a) => a.id),
      });

      if (expected.length === 0) {
        logger.warn("checkUniformCompliance: no expected accessories", {
          uid,
          dressCode,
        });
      }

      const bucketName = getStorage().bucket().name;
      const referenceImages: {
        accessoryId: string;
        displayName: string;
        data: string;
        mimeType: "image/png";
      }[] = [];
      for (const a of expected.slice(0, MAX_REFERENCE_IMAGES)) {
        const img = await tryFetchReferenceImage(bucketName, a.id);
        if (img) {
          referenceImages.push({
            accessoryId: a.id,
            displayName: a.record.display_name ?? a.id,
            ...img,
          });
        }
      }

      // TRIAL ONLY — skip the actual Claude vision call and return a
      // canned PASS result built from the real resolved accessory list.
      // Lets the rest of the app flow (capture -> result screen) be
      // tested without depending on Anthropic being reachable, without
      // spending API credits, and with a predictable result. Re-enable
      // the real call below before any real use — this never actually
      // judges the photo. See the conversation this was added in.
      const _TRIAL_SKIP_AI_VERDICT = true;
      if (_TRIAL_SKIP_AI_VERDICT) {
        const trialResult: ComplianceResponse = {
          overallScore: 100,
          summary: "TRIAL MODE — AI verdict skipped, this is a canned result.",
          items: expected.map((a) => ({
            accessoryId: a.id,
            displayName: a.record.display_name ?? a.id,
            status: "correct",
            note: "TRIAL MODE — not actually inspected.",
          })),
        };
        logger.info("checkUniformCompliance: TRIAL — skipped AI verdict", {
          uid,
          dressCode,
          itemCount: trialResult.items.length,
        });
        return trialResult;
      }

      const anthropic = new Anthropic({ apiKey: ANTHROPIC_API_KEY.value() });

      const content: Anthropic.MessageParam["content"] = [
        { type: "text", text: buildPromptText(expected) },
        {
          type: "image",
          source: { type: "base64", media_type: mimeType, data: photoBase64 },
        },
      ];
      for (const ref of referenceImages) {
        content.push({
          type: "text",
          text: `Reference image for accessory "${ref.displayName}" (id="${ref.accessoryId}"):`,
        });
        content.push({
          type: "image",
          source: {
            type: "base64",
            media_type: ref.mimeType,
            data: ref.data,
          },
        });
      }

      const message = await anthropic.messages.create({
        model: MODEL,
        max_tokens: 2048,
        tools: [REPORT_TOOL],
        tool_choice: { type: "tool", name: REPORT_TOOL_NAME },
        messages: [{ role: "user", content }],
      });

      const toolUse = message.content.find(
        (b): b is Anthropic.ToolUseBlock => b.type === "tool_use",
      );
      if (!toolUse) {
        throw new Error("Model response did not include a tool_use block.");
      }

      const result = ComplianceResponse.parse(toolUse.input);

      logger.info("checkUniformCompliance: ok", {
        uid,
        dressCode,
        overallScore: result.overallScore,
        itemCount: result.items.length,
      });

      return result;
    } catch (e) {
      const err = e as Error;
      logger.error("checkUniformCompliance: failed", {
        uid,
        dressCode,
        error: err.message,
        stack: err.stack,
      });
      throw new HttpsError(
        "internal",
        "Uniform compliance check failed. Please try again.",
      );
    }
  },
);
