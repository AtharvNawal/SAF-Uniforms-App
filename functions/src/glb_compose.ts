/**
 * GLB composition helpers used by `composeUniformModel`.
 *
 * The Phase-2 merger is split into pure-ish helpers over `@gltf-transform`
 * `Document` instances so each piece is unit-testable in isolation.
 *
 * High-level flow (from composeUniformModel):
 *
 *   1. `createComposeIO()` — NodeIO with Draco + EXT_texture_webp
 *      registered, ready to read & write Phase-2 outputs.
 *   2. `mergeUniform(body, uniform)` — pulls the uniform's mesh + skeleton
 *      into the body Document.
 *   3. `detachNodeByName(body, "hair")` — when any headdress is mounted, the
 *      hair sub-mesh is removed so a beret / turban doesn't z-fight scalp
 *      geometry.
 *   4. `attachAccessory(body, acc, socketName, offsetMeters)` — merges
 *      each accessory and re-parents its root node under the named
 *      socket bone with the given local-space offset.
 *   5. `bakeNameTag(body, "name_tag_mat", fullName)` — composites the
 *      user's surname onto the name-tag material's base-color texture
 *      via `sharp`.
 *   6. `compressForWeb(body)` — Draco mesh compression + WebP texture
 *      compression via gltf-transform's transforms.
 *
 * All helpers fail soft: they return a structured result so callers can
 * log + continue with a partial composition rather than throwing for a
 * single missing socket / material / texture.
 */

import { Document, NodeIO, Node, Scene } from "@gltf-transform/core";
import {
  EXTTextureWebP,
  KHRDracoMeshCompression,
  KHRTextureTransform,
} from "@gltf-transform/extensions";
import {
  dedup,
  draco,
  mergeDocuments,
  prune,
  textureCompress,
} from "@gltf-transform/functions";
import sharp from "sharp";

/**
 * Material name the merger expects to find on the body GLB. The artist
 * delivery contract pins this to a dedicated `name_tag` mesh node carrying
 * a single `name_tag_mat` material whose base-color texture is the bake
 * target. The placeholder body generator in
 * `tool/generate_placeholder_bodies.py` satisfies the same contract.
 */
export const NAME_TAG_MATERIAL = "name_tag_mat";

/** Mesh node name that the hair-detach step targets when a headdress is mounted. */
export const HAIR_NODE = "hair";

/**
 * Mesh node name that the feet-detach step targets when footwear is
 * mounted. The body GLB ships with the bare-foot vertices sliced out as
 * a separate `feet` node (the body's monolithic Tripo mesh was split
 * offline at y=0.10m). Detaching this node before the shoe accessory
 * attaches prevents skin-coloured toes from poking through the shoe
 * mesh.
 */
export const FEET_NODE = "feet";

/**
 * Build a NodeIO that can both read existing Draco-compressed inputs and
 * write Draco + WebP-compressed outputs.
 *
 * The Draco encoder/decoder modules are heavy (each loads a wasm blob);
 * we build the IO once per Cloud Function invocation and reuse it for
 * every read + the final write.
 */
export async function createComposeIO(): Promise<NodeIO> {
  // `draco3dgltf` is CommonJS; the createEncoder / createDecoder fns
  // each return a Promise of the wasm module instance.
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const draco3d = require("draco3dgltf");
  const [encoder, decoder] = await Promise.all([
    draco3d.createEncoderModule(),
    draco3d.createDecoderModule(),
  ]);
  return new NodeIO()
    // KHRTextureTransform: artist figures (RSAF No.4) tile their fabric /
    // skin normal + roughness maps with it; an unregistered extension is
    // silently dropped on read, which made the weave 14x too coarse.
    .registerExtensions([KHRDracoMeshCompression, EXTTextureWebP, KHRTextureTransform])
    .registerDependencies({
      "draco3d.encoder": encoder,
      "draco3d.decoder": decoder,
    });
}

/**
 * Walks every scene + every node subtree and returns the first node whose
 * `getName()` matches. Returns `null` when the name doesn't appear anywhere.
 */
export function findNodeByName(doc: Document, name: string): Node | null {
  for (const scene of doc.getRoot().listScenes()) {
    for (const child of scene.listChildren()) {
      const hit = walkForName(child, name);
      if (hit) return hit;
    }
  }
  return null;
}

function walkForName(node: Node, name: string): Node | null {
  if (node.getName() === name) return node;
  for (const child of node.listChildren()) {
    const hit = walkForName(child, name);
    if (hit) return hit;
  }
  return null;
}

/**
 * Removes the first node whose name matches from its parent (scene or node).
 * Returns `true` when a node was detached.
 */
export function detachNodeByName(doc: Document, name: string): boolean {
  for (const scene of doc.getRoot().listScenes()) {
    for (const child of scene.listChildren()) {
      if (child.getName() === name) {
        scene.removeChild(child);
        return true;
      }
    }
  }
  // Walk node subtrees for nested matches.
  const target = findNodeByName(doc, name);
  if (!target) return false;
  const parent = target.getParentNode();
  if (parent) {
    parent.removeChild(target);
    return true;
  }
  // Top-level node attached to a scene we somehow missed — fall through.
  for (const scene of doc.getRoot().listScenes()) {
    if (scene.listChildren().includes(target)) {
      scene.removeChild(target);
      return true;
    }
  }
  return false;
}

/**
 * Merges every scene-root from `uniformDoc` into `bodyDoc`'s root scene.
 * Wraps `mergeDocuments` so callers don't need to import gltf-transform/functions
 * directly. Idempotent in the sense that calling it twice merges twice
 * (no built-in dedup) — callers should not invoke it for the same source
 * document repeatedly.
 */
export function mergeUniform(bodyDoc: Document, uniformDoc: Document): void {
  mergeDocuments(bodyDoc, uniformDoc);
}

export interface AccessoryAttachResult {
  attached: boolean;
  /** When `attached === false`, why the attempt was skipped. */
  reason?: string;
  /** Number of new top-level nodes that were re-parented under the socket. */
  rootsAttached: number;
  /** Names of the body sockets the accessory was actually attached to. */
  sockets: string[];
}

export interface AttachOptions {
  /**
   * When true, the accessory is attached under BOTH the left and right
   * version of the named socket — same mesh, identity transform on both
   * sides. Symmetric accessories (chevrons, belt buckles) read correctly
   * on both arms / both feet. Asymmetric ones (single-sided shoes) render
   * the same shape on both sides, which is acceptable for placeholder
   * assets until a proper L/R pair is authored.
   *
   * Pass 5 previously applied `scale=[-1, 1, 1]` to the right-side
   * wrapper for an X-axis mirror. The negative scale inverts triangle
   * winding, and with the default material's back-face culling the
   * mirrored copy rendered invisible from the viewer's front. Removed
   * in pass 6 — both copies now attach with identity scale.
   */
  mirror?: boolean;
}

/**
 * Maps a paired-alias / generic socket name to the canonical
 * left/right body-socket pair. The accessory_library schema uses generic
 * names like `shoulder_seam` together with `mirror_left_right: true` to
 * indicate "attach this on both shoulders"; the body-authoring contract
 * exposes specific names like `left_shoulder_seam` / `right_shoulder_seam`.
 * This map bridges the two.
 *
 * Library-side suffix-matching covers both paired aliases (`shoulder_seam`,
 * `collar_point`) and bare body-socket names (`left_shoulder_seam`) when
 * the library happens to set mirror=true on a side-specific anchor — we
 * want to attach to both regardless.
 */
const PAIRED_SOCKETS: Record<string, [string, string]> = {
  shoulder_seam: ["left_shoulder_seam", "right_shoulder_seam"],
  collar_point: ["left_collar_tip", "right_collar_tip"],
  collar_tip: ["left_collar_tip", "right_collar_tip"],
  sleeve_upper: ["left_sleeve_upper", "right_sleeve_upper"],
  chest_pocket: ["left_chest_pocket", "right_chest_pocket"],
  ankle: ["left_ankle", "right_ankle"],
  foot_top: ["left_foot_top", "right_foot_top"],
  left_shoulder_seam: ["left_shoulder_seam", "right_shoulder_seam"],
  right_shoulder_seam: ["left_shoulder_seam", "right_shoulder_seam"],
  left_collar_tip: ["left_collar_tip", "right_collar_tip"],
  right_collar_tip: ["left_collar_tip", "right_collar_tip"],
  left_sleeve_upper: ["left_sleeve_upper", "right_sleeve_upper"],
  right_sleeve_upper: ["left_sleeve_upper", "right_sleeve_upper"],
  left_chest_pocket: ["left_chest_pocket", "right_chest_pocket"],
  right_chest_pocket: ["left_chest_pocket", "right_chest_pocket"],
  left_ankle: ["left_ankle", "right_ankle"],
  right_ankle: ["left_ankle", "right_ankle"],
  left_foot_top: ["left_foot_top", "right_foot_top"],
  right_foot_top: ["left_foot_top", "right_foot_top"],
};

/**
 * Resolves the input socket name to the list of sockets the merger
 * should actually attach to. Single-socket for the default path; the
 * left+right pair when `mirror` is true and the socket has a known
 * paired counterpart.
 */
function resolveTargetSockets(
  socketName: string,
  mirror: boolean,
): string[] {
  if (!mirror) return [socketName];
  const pair = PAIRED_SOCKETS[socketName];
  return pair ? [...pair] : [socketName];
}

/**
 * Merges `accDoc` into `target` and re-parents the new top-level nodes
 * under the resolved body socket(s), applying `offsetMeters` as a local
 * translation on each root.
 *
 * When `options.mirror === true` and `socketName` resolves to a known
 * paired socket (e.g. `shoulder_seam` → `left_shoulder_seam` +
 * `right_shoulder_seam`), the accessory is merged twice — once per side
 * — and the right-side copy gets a negative-X scale so symmetric meshes
 * mirror correctly.
 *
 * Returns `{ attached: false, ... }` only when *every* target socket is
 * missing. A partial success (left attached, right missing) returns
 * `attached: true` with `sockets` listing only the side that landed.
 * The caller logs + continues rather than throwing.
 */
export function attachAccessory(
  target: Document,
  accDoc: Document,
  socketName: string,
  offsetMeters: [number, number, number],
  options: AttachOptions = {},
): AccessoryAttachResult {
  const { mirror = false } = options;
  const targetSockets = resolveTargetSockets(socketName, mirror);

  // Resolve socket nodes ahead of time so we can short-circuit when
  // none exist — and so partial successes report the side(s) that landed.
  const resolved: Array<{ name: string; node: Node }> = [];
  for (let i = 0; i < targetSockets.length; i++) {
    const name = targetSockets[i];
    const node = findNodeByName(target, name);
    if (node) {
      resolved.push({ name, node });
    }
  }

  if (resolved.length === 0) {
    return {
      attached: false,
      reason: `socket node${targetSockets.length > 1 ? "s" : ""} "${targetSockets.join('", "')}" not found`,
      rootsAttached: 0,
      sockets: [],
    };
  }

  let totalRoots = 0;
  const attachedSockets: string[] = [];
  for (const r of resolved) {
    // Snapshot scene roots BEFORE the merge so the new roots are
    // identifiable by exclusion. We re-snapshot per pass because the
    // previous pass added its own new roots under a socket — those
    // are no longer "scene roots", so a fresh snapshot still works.
    const scenes = target.getRoot().listScenes();
    const beforeRoots = new Set<Node>();
    for (const scene of scenes) {
      for (const child of scene.listChildren()) beforeRoots.add(child);
    }

    mergeDocuments(target, accDoc);

    const newRoots: Array<{ scene: Scene; node: Node }> = [];
    for (const scene of target.getRoot().listScenes()) {
      for (const child of scene.listChildren()) {
        if (!beforeRoots.has(child)) {
          newRoots.push({ scene, node: child });
        }
      }
    }
    if (newRoots.length === 0) continue;

    for (const { scene, node } of newRoots) {
      scene.removeChild(node);
      r.node.addChild(node);
      node.setTranslation(offsetMeters);
    }
    totalRoots += newRoots.length;
    attachedSockets.push(r.name);
  }

  return {
    attached: totalRoots > 0,
    rootsAttached: totalRoots,
    sockets: attachedSockets,
    ...(totalRoots === 0 && { reason: "merge produced no new scene-root nodes" }),
  };
}

/**
 * Composites the `fullName` text onto the base-color texture of the
 * material named `materialName` and writes the result back into the GLB.
 *
 * Implementation notes:
 * - We use sharp's SVG-input pathway to render the text as a transparent
 *   overlay, then composite it onto the existing base-color image. Sharp
 *   has no native text-on-raster API; SVG is the documented workaround.
 * - When the material has no existing base-color texture, we synthesize a
 *   1024×256 white background. (Real artist deliveries always ship a
 *   texture; the fallback exists so the placeholder generator's output
 *   keeps working even if a future change strips the texture.)
 *
 * Returns `false` when the material isn't found, so callers can degrade
 * gracefully (no name tag rather than failed composition).
 */
export async function bakeNameTag(
  doc: Document,
  materialName: string,
  fullName: string,
): Promise<boolean> {
  const material = doc
    .getRoot()
    .listMaterials()
    .find((m) => m.getName() === materialName);
  if (!material) return false;

  const baseTexture = material.getBaseColorTexture();
  let baseImage: Buffer;
  let width = 1024;
  let height = 256;
  if (baseTexture) {
    const existing = baseTexture.getImage();
    if (existing) {
      baseImage = Buffer.from(existing);
      const size = baseTexture.getSize();
      if (size) {
        [width, height] = size;
      }
    } else {
      baseImage = await sharp({
        create: {
          width,
          height,
          channels: 3,
          background: { r: 245, g: 245, b: 245 },
        },
      })
        .png()
        .toBuffer();
    }
  } else {
    baseImage = await sharp({
      create: {
        width,
        height,
        channels: 3,
        background: { r: 245, g: 245, b: 245 },
      },
    })
      .png()
      .toBuffer();
  }

  // Render text as SVG and let sharp rasterise it. The font size is sized
  // to ~50% of the texture height so the surname fills the patch. Text
  // colour follows the tape: dark text on light tapes (the placeholder
  // bodies' white patch), white text on dark tapes (RSAF No.4 figure).
  const fontSize = Math.round(height * 0.55);
  const textFill = (await meanLuminance(baseImage)) < 110
    ? "rgb(238,238,232)"
    : "rgb(15,15,15)";
  const safeText = escapeXmlText(fullName.toUpperCase());
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <rect width="100%" height="100%" fill="rgba(0,0,0,0)"/>
    <text x="50%" y="50%" font-family="sans-serif" font-size="${fontSize}" font-weight="700"
          fill="${textFill}" text-anchor="middle" dominant-baseline="middle"
          letter-spacing="6">${safeText}</text>
  </svg>`;

  const composed = await sharp(baseImage)
    .composite([{ input: Buffer.from(svg) }])
    .png()
    .toBuffer();

  if (baseTexture) {
    baseTexture.setImage(new Uint8Array(composed));
    baseTexture.setMimeType("image/png");
  } else {
    const tex = doc
      .createTexture(`${materialName}_baked`)
      .setImage(new Uint8Array(composed))
      .setMimeType("image/png");
    material.setBaseColorTexture(tex);
  }
  return true;
}

/** Mean Rec.601 luminance (0-255) of an encoded image. */
async function meanLuminance(image: Buffer): Promise<number> {
  const { channels } = await sharp(image).stats();
  const [r, g, b] = [channels[0], channels[1] ?? channels[0], channels[2] ?? channels[0]];
  return 0.299 * r.mean + 0.587 * g.mean + 0.114 * b.mean;
}

function escapeXmlText(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

/**
 * Collapses every scene in `doc` into the first scene by re-parenting
 * each extra scene's children under it, then disposes the now-empty
 * scenes. Required because `mergeDocuments` keeps source scenes as
 * separate Scene objects on the target Document — a body + uniform + N
 * accessories produces N+2 scenes. glTF renderers (model-viewer included)
 * render only the default scene, so the uniform + accessory geometry in
 * the secondary scenes ends up either invisible or rendered through a
 * code path the renderer doesn't guarantee to compose with the body's
 * coordinate frame.
 *
 * After this helper runs, all geometry lives under the primary scene's
 * hierarchy and inherits the body's frame.
 *
 * Returns the scene count after consolidation (always 0 or 1).
 */
export function consolidateScenesToOne(doc: Document): number {
  const scenes = doc.getRoot().listScenes();
  if (scenes.length <= 1) return scenes.length;
  const primary = scenes[0];
  for (let i = 1; i < scenes.length; i++) {
    for (const child of scenes[i].listChildren()) {
      primary.addChild(child);
    }
    scenes[i].dispose();
  }
  // Ensure the document's default scene points at the primary, in case
  // something on the way through reassigned it.
  doc.getRoot().setDefaultScene(primary);
  return doc.getRoot().listScenes().length;
}

/**
 * Reassigns every accessor in `doc` to a single (the first) Buffer and
 * disposes the others. Required before `NodeIO.writeBinary(doc)` because
 * the GLB writer enforces "GLB must have 0–1 buffers" — `mergeDocuments`
 * in upstream code accumulates one buffer per merged source, so a body
 * + N accessories produces N+1 buffers.
 *
 * Image data on textures is NOT touched here — gltf-transform's writer
 * marshals texture bytes through its resource map at write-time and
 * doesn't carry image data on a separate user-visible Buffer that would
 * need re-binding.
 *
 * Returns the buffer count after consolidation (0 or 1).
 */
export function consolidateBuffersToOne(doc: Document): number {
  const buffers = doc.getRoot().listBuffers();
  if (buffers.length <= 1) return buffers.length;
  const primary = buffers[0];
  for (const accessor of doc.getRoot().listAccessors()) {
    if (accessor.getBuffer() !== primary) {
      accessor.setBuffer(primary);
    }
  }
  for (let i = 1; i < buffers.length; i++) {
    buffers[i].dispose();
  }
  return doc.getRoot().listBuffers().length;
}

export interface CompressionOptions {
  /** Apply Draco mesh compression. Default: true. */
  applyDraco?: boolean;
  /** Apply WebP texture compression. Default: true. */
  applyWebp?: boolean;
  /** WebP quality 1-100. Default: 80. */
  webpQuality?: number;
}

/**
 * Runs `dedup` + `prune` (always safe), then optionally Draco mesh
 * compression and WebP texture compression. Each compression pass is
 * try/catch'd so a failure in one (e.g. Draco runtime missing) doesn't
 * lose the cheaper passes — the caller still gets a valid, optimised GLB.
 *
 * The `dedup` + `prune` passes alone typically halve the GLB size by
 * collapsing duplicate accessors / materials introduced during merge.
 */
export async function compressForWeb(
  doc: Document,
  options: CompressionOptions = {},
): Promise<{ dracoApplied: boolean; webpApplied: boolean }> {
  const {
    applyDraco = true,
    applyWebp = true,
    webpQuality = 80,
  } = options;

  await doc.transform(dedup(), prune());

  let dracoApplied = false;
  if (applyDraco) {
    try {
      await doc.transform(draco());
      dracoApplied = true;
    } catch {
      // Swallow — caller logs at the call site via the return value.
    }
  }

  let webpApplied = false;
  if (applyWebp) {
    try {
      await doc.transform(
        textureCompress({
          encoder: sharp,
          targetFormat: "webp",
          quality: webpQuality,
        }),
      );
      webpApplied = true;
    } catch {
      // ignore
    }
  }

  // FINAL: collapse N scenes (one per merged document) → 1 so the
  // renderer's default-scene-only behavior shows every accessory
  // attached during compose. Then collapse N buffers → 1 so the GLB
  // writer accepts the document (it enforces 0–1 buffers).
  // Both MUST run last: some transforms (Draco) may create new accessors
  // that should be reassigned to the primary buffer.
  consolidateScenesToOne(doc);
  consolidateBuffersToOne(doc);

  return { dracoApplied, webpApplied };
}


// ---------------------------------------------------------------------------
// Baked slots — accessories already modelled into a unified dressed figure
// ---------------------------------------------------------------------------

/** Root `extras` key a unified figure uses to declare its built-in parts. */
export const BAKED_SLOTS_EXTRAS_KEY = "saf_baked_slots";

/**
 * One built-in part of a unified figure. `node` is the scene node holding
 * it; `accessory` is the accessory_library id it represents, or `null` when
 * the slot is merely *covered* (socks inside boots, a belt under an
 * untucked shirt) and nothing should ever attach there. `optional` marks a
 * part doctrine only shows when held (a chest wing badge): it is removed
 * unless the profile includes an accessory for that slot.
 */
export interface BakedSlot {
  node: string;
  accessory: string | null;
  optional?: boolean;
}

/** Accessory as seen by the baked-slot planner. */
export interface SlotAccessory {
  id: string;
  category: string;
  mandatory: boolean;
}

/**
 * Reads `extras.saf_baked_slots` from the GLB root. Returns `{}` for every
 * figure that doesn't declare one (all pre-existing bodies), which makes
 * the planners below no-ops.
 */
export function readBakedSlots(doc: Document): Record<string, BakedSlot> {
  const raw = (doc.getRoot().getExtras() as Record<string, unknown>)[BAKED_SLOTS_EXTRAS_KEY];
  if (!raw || typeof raw !== "object") return {};
  const out: Record<string, BakedSlot> = {};
  for (const [slot, value] of Object.entries(raw as Record<string, unknown>)) {
    if (!value || typeof value !== "object") continue;
    const v = value as Record<string, unknown>;
    if (typeof v["node"] !== "string") continue;
    out[slot] = {
      node: v["node"] as string,
      accessory: typeof v["accessory"] === "string" ? (v["accessory"] as string) : null,
      ...(v["optional"] === true && { optional: true }),
    };
  }
  return out;
}

/**
 * Slot an accessory category competes for. Every headdress variant
 * (beret, Sikh turban, ladies' hat, jockey cap, …) shares one head.
 */
export function slotOf(category: string): string {
  return category.startsWith("headdress") ? "headdress" : category;
}

/**
 * Built-in nodes to remove:
 * - a *mandatory* accessory for the slot differs from what the figure
 *   carries — e.g. a Sikh profile's turban replaces the modelled beret, a
 *   COL's cap badge replaces the default one. Optional alternatives never
 *   trigger a swap (a ticked "combat boots" must not strip the modelled
 *   boots);
 * - an `optional` built-in part the profile doesn't include (no chest wing
 *   badge unless the wearer ticked one).
 */
export function planBakedDetaches(
  slots: Record<string, BakedSlot>,
  accessories: SlotAccessory[],
  nodeExists: (name: string) => boolean,
): string[] {
  const detach: string[] = [];
  for (const baked of Object.entries(slots)) {
    const [slot, v] = baked;
    if (!v.optional || !nodeExists(v.node)) continue;
    if (!accessories.some((a) => slotOf(a.category) === slot) && !detach.includes(v.node)) {
      detach.push(v.node);
    }
  }
  for (const acc of accessories) {
    const baked = slots[slotOf(acc.category)];
    if (!baked || baked.accessory === null || !acc.mandatory) continue;
    if (baked.accessory !== acc.id && nodeExists(baked.node) && !detach.includes(baked.node)) {
      detach.push(baked.node);
    }
  }
  return detach;
}

/**
 * Accessory ids to skip because the figure already shows them. Call after
 * the detaches from `planBakedDetaches` have been applied: a slot whose
 * node is gone (detached directly, or as a child of a detached node — the
 * beret's badge goes with the beret) is open again and its accessory
 * attaches normally.
 */
export function planBakedSkips(
  slots: Record<string, BakedSlot>,
  accessories: SlotAccessory[],
  nodeExists: (name: string) => boolean,
): Set<string> {
  const skip = new Set<string>();
  for (const acc of accessories) {
    const baked = slots[slotOf(acc.category)];
    if (!baked) continue;
    if (baked.accessory === null || nodeExists(baked.node)) skip.add(acc.id);
  }
  return skip;
}
