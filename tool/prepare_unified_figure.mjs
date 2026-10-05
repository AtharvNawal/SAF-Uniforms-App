#!/usr/bin/env node
/**
 * Operator-only: make an artist-delivered *dressed figure* GLB (body +
 * uniform + modelled accessories in one file) ready for the
 * `composeUniformModel` "unified" path (`models/bodies/{branch}_{dress}_{gender}.glb`).
 *
 * Unlike `tool/inject_sockets.py` (which flattens a raw Tripo body into one
 * mesh), this works on the existing scene graph, so every node, material
 * and texture survives untouched. It:
 *
 *   1. Adds the 15 standard socket nodes + `name_tag`, measured from the
 *      figure's own parts (names in the config's `parts`). Sockets that a
 *      *replacement* accessory may attach to (`head_top`, `cap_band_front`,
 *      `belt_center`) are solved so that accessory — with its library
 *      `render_logic` offset and its real GLB bounds — lands exactly where
 *      the figure's built-in part sits (config `replacement_alignment`).
 *   2. Renames the name-tape material to `name_tag_mat`, replaces its image
 *      with a blank tape (sampled fill + border) and flips its V coordinates,
 *      so `bakeNameTag` writes the wearer's surname upright.
 *   3. Writes `extras.saf_baked_slots` on the GLB root (config `baked_slots`)
 *      — which accessories the figure already models, so compose skips or
 *      swaps them instead of doubling them up. Parts built from several
 *      sibling nodes (a rank tab + its insignia) are first wrapped in one
 *      group node (config `groups`) so they detach together.
 *
 * Usage (from the repo root; needs `cd functions && npm install` once):
 *   node tool/prepare_unified_figure.mjs --config assets/3d/figures/rsaf_no4.json \
 *        --in assets/3d_raw/rsaf_no4_male_source.glb --out assets/3d/bodies/rsaf_no4_male.glb
 *
 * Then upload with `tool/upload_models.py --only 'bodies/rsaf_no4_*'`.
 */
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(path.join(REPO, "functions", "package.json"));
const { NodeIO, getBounds } = require("@gltf-transform/core");
const { ALL_EXTENSIONS } = require("@gltf-transform/extensions");
const sharp = require("sharp");

const BAKED_SLOTS_EXTRAS_KEY = "saf_baked_slots"; // mirrors functions/src/glb_compose.ts
const NAME_TAG_MATERIAL = "name_tag_mat"; // mirrors functions/src/glb_compose.ts

function log(msg) {
  console.log(`[prepare_unified_figure] ${msg}`);
}

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i += 2) out[argv[i].replace(/^--/, "")] = argv[i + 1];
  if (!out.config || !out.in || !out.out) {
    console.error("usage: node tool/prepare_unified_figure.mjs --config <figure.json> --in <raw.glb> --out <prepared.glb>");
    process.exit(2);
  }
  return out;
}

const round = (v) => v.map((x) => Math.round(x * 10000) / 10000);
const centre = (b) => [0, 1, 2].map((i) => (b.min[i] + b.max[i]) / 2);

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const config = JSON.parse(fs.readFileSync(args.config, "utf8"));
  const library = new Map(
    JSON.parse(fs.readFileSync(path.join(REPO, "assets/data/accessory_library.v1.json"), "utf8"))
      .accessories.map((a) => [a.id, a]),
  );
  const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
  const doc = await io.read(args.in);
  const root = doc.getRoot();
  const scene = root.getDefaultScene() ?? root.listScenes()[0];

  const nodes = new Map(root.listNodes().map((n) => [n.getName(), n]));
  const part = (key) => {
    const name = config.parts[key] ?? key;
    const n = nodes.get(name);
    if (!n) throw new Error(`figure has no node "${name}" (config parts.${key})`);
    return getBounds(n);
  };

  // ---- 1. Sockets ----
  const head = part("head");
  const shoulders = part("shoulders");
  const sockets = {};
  for (const side of ["left", "right"]) {
    const collar = part(`collar_${side}`);
    sockets[`${side}_collar_tip`] = [centre(collar)[0], collar.min[1], collar.max[2]];
    const pocket = part(`pocket_${side}`);
    sockets[`${side}_chest_pocket`] = [centre(pocket)[0], pocket.max[1], pocket.max[2]];
    const sx = side === "left" ? shoulders.min[0] : shoulders.max[0];
    sockets[`${side}_shoulder_seam`] = [sx * 0.85, shoulders.max[1], 0];
    const patch = part(`sleeve_patch_${side}`);
    const patchX = side === "left" ? patch.min[0] : patch.max[0];
    // Sleeve accessories carry offset_y_cm ≈ +4 (patch centre 4 cm above the socket).
    sockets[`${side}_sleeve_upper`] = [patchX, centre(patch)[1] - 0.04, centre(patch)[2]];
    const boot = part(`boot_${side}`);
    sockets[`${side}_ankle`] = [centre(boot)[0], 0.10, 0];
    sockets[`${side}_foot_top`] = [centre(boot)[0], 0.03, 0.08];
  }
  sockets.head_top = [centre(head)[0], head.max[1] + 0.03, centre(head)[2]];
  sockets.cap_band_front = [0, head.max[1] - 0.06, head.max[2]];
  sockets.belt_center = [0, 1.0, 0.14];
  const tape = part("name_tape");
  sockets.name_tag = [centre(tape)[0], centre(tape)[1], tape.max[2]];

  // Replacement-aligned sockets: socket = target − render_logic offset − GLB anchor point.
  for (const [socket, spec] of Object.entries(config.replacement_alignment ?? {})) {
    const acc = library.get(spec.accessory);
    if (!acc) throw new Error(`replacement_alignment.${socket}: unknown accessory ${spec.accessory}`);
    const rl = acc.render_logic ?? {};
    const off = [rl.offset_x_cm ?? 0, rl.offset_y_cm ?? 0, rl.offset_z_cm ?? 0].map((c) => c / 100);
    const accDoc = await io.read(path.join(REPO, "assets/3d/accessories", `${spec.accessory}.glb`));
    const accScene = accDoc.getRoot().listScenes()[0];
    const ab = getBounds(accScene);
    const target = getBounds(nodes.get(spec.node));
    let pos;
    if (spec.mode === "top") {
      // Accessory's top meets the built-in part's top (headdress).
      const xz = spec.xz_node ? centre(getBounds(nodes.get(spec.xz_node))) : centre(target);
      const ac = centre(ab);
      pos = [xz[0] - ac[0] - off[0], target.max[1] - ab.max[1] - off[1], xz[2] - ac[2] - off[2]];
    } else {
      const tc = centre(target);
      const ac = centre(ab);
      pos = [0, 1, 2].map((i) => tc[i] - ac[i] - off[i]);
    }
    sockets[socket] = pos;
    log(`aligned ${socket} for ${spec.accessory} onto ${spec.node}`);
  }

  for (const [name, pos] of Object.entries(sockets)) {
    if (nodes.has(name)) throw new Error(`figure already has a node named "${name}"`);
    scene.addChild(doc.createNode(name).setTranslation(round(pos)));
    log(`socket ${name.padEnd(20)} ${round(pos).join(", ")}`);
  }

  // ---- 2. Name tape → bakeable name_tag_mat ----
  const tapeMat = root.listMaterials().find((m) => m.getName() === config.name_tape_material);
  if (!tapeMat) throw new Error(`no material "${config.name_tape_material}"`);
  const tex = tapeMat.getBaseColorTexture();
  if (tex) {
    const { data, info } = await sharp(Buffer.from(tex.getImage())).removeAlpha().raw()
      .toBuffer({ resolveWithObject: true });
    const px = (x, y) => Array.from(data.subarray((y * info.width + x) * 3, (y * info.width + x) * 3 + 3));
    const border = px(2, 2);
    const fill = px(Math.floor(info.width * 0.03), Math.floor(info.height / 2));
    const inset = Math.max(2, Math.round(info.height * 0.035));
    const blank = await sharp({
      create: { width: info.width, height: info.height, channels: 3, background: { r: border[0], g: border[1], b: border[2] } },
    }).composite([{
      input: await sharp({
        create: { width: info.width - 2 * inset, height: info.height - 2 * inset, channels: 3,
          background: { r: fill[0], g: fill[1], b: fill[2] } },
      }).png().toBuffer(),
      left: inset, top: inset,
    }]).png().toBuffer();
    tex.setImage(new Uint8Array(blank)).setMimeType("image/png");
    log(`name tape blanked (${info.width}x${info.height}, fill ${fill}, border ${border})`);
  }
  // The delivered texture is stored upside down to suit these UVs; flip V so
  // an upright image (what bakeNameTag renders) reads upright on the model.
  for (const mesh of root.listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      if (prim.getMaterial() !== tapeMat) continue;
      const uv = prim.getAttribute("TEXCOORD_0");
      if (!uv) continue;
      const flipped = uv.getArray().slice();
      for (let i = 1; i < flipped.length; i += 2) flipped[i] = 1 - flipped[i];
      uv.setArray(flipped);
    }
  }
  tapeMat.setName(NAME_TAG_MATERIAL);
  log(`material ${config.name_tape_material} → ${NAME_TAG_MATERIAL}`);

  // ---- 3. Groups + baked-slot declaration ----
  for (const [group, members] of Object.entries(config.groups ?? {})) {
    const ms = members.map((m) => {
      const n = nodes.get(m);
      if (!n) throw new Error(`groups.${group}: figure has no node "${m}"`);
      return n;
    });
    const parent = ms[0].getParentNode();
    if (!parent || ms.some((m) => m.getParentNode() !== parent)) {
      throw new Error(`groups.${group}: members must share one parent node`);
    }
    // Identity transform under the same parent keeps every member's world position.
    const g = doc.createNode(group);
    parent.addChild(g);
    for (const m of ms) {
      parent.removeChild(m);
      g.addChild(m);
    }
    nodes.set(group, g);
    log(`group ${group} = ${members.join(" + ")}`);
  }
  for (const [slot, v] of Object.entries(config.baked_slots)) {
    if (!nodes.has(v.node)) throw new Error(`baked_slots.${slot}: figure has no node "${v.node}"`);
    if (v.accessory !== null && !library.has(v.accessory)) {
      throw new Error(`baked_slots.${slot}: unknown accessory ${v.accessory}`);
    }
  }
  root.setExtras({ ...root.getExtras(), [BAKED_SLOTS_EXTRAS_KEY]: config.baked_slots });

  fs.mkdirSync(path.dirname(args.out), { recursive: true });
  await io.write(args.out, doc);
  log(`wrote ${args.out} (${(fs.statSync(args.out).size / 1e6).toFixed(2)} MB)`);
}

main().catch((e) => {
  console.error(`[prepare_unified_figure] failed: ${e.stack ?? e}`);
  process.exit(1);
});
