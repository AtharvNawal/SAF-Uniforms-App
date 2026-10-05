/**
 * Tests for the baked-slot helpers in `glb_compose.ts` — how a unified
 * dressed figure (e.g. RSAF No.4) declares the accessories it already
 * models, and how compose decides what to skip / swap.
 *
 * Build first (`npm run build`), then `node --test lib`.
 */

import { strict as assert } from "node:assert";
import { test } from "node:test";

import { Document } from "@gltf-transform/core";
import sharp from "sharp";

import {
  BAKED_SLOTS_EXTRAS_KEY,
  BakedSlot,
  bakeNameTag,
  detachNodeByName,
  findNodeByName,
  planBakedDetaches,
  planBakedSkips,
  readBakedSlots,
  slotOf,
} from "./glb_compose";

const SLOTS: Record<string, BakedSlot> = {
  headdress: { node: "beret", accessory: "rsaf_beret" },
  cap_badge: { node: "beret_badge", accessory: "rsaf_cap_badge_sltc_me6_below" },
  rank_epaulette_chest: { node: "rank_tab", accessory: "rsaf_no4_rank_epaulette" },
  footwear: { node: "boots", accessory: "safety_boots" },
  socks: { node: "boots", accessory: null },
  belt: { node: "shirt_hem", accessory: null },
  saf_badge: { node: "wing_badge_assembly", accessory: "saf_badges_chest", optional: true },
};

/** Figure with beret ▸ beret_badge, rank_tab, boots, shirt_hem. */
function figure(): Document {
  const doc = new Document();
  const scene = doc.createScene("s");
  const root = doc.createNode("field_uniform");
  const beret = doc.createNode("beret");
  beret.addChild(doc.createNode("beret_badge"));
  for (const n of [beret, doc.createNode("rank_tab"), doc.createNode("boots"), doc.createNode("shirt_hem"),
    doc.createNode("wing_badge_assembly")]) {
    root.addChild(n);
  }
  scene.addChild(root);
  doc.getRoot().setExtras({ [BAKED_SLOTS_EXTRAS_KEY]: SLOTS });
  return doc;
}

function plan(doc: Document, accs: Array<[string, string, boolean]>) {
  const list = accs.map(([id, category, mandatory]) => ({ id, category, mandatory }));
  const slots = readBakedSlots(doc);
  const exists = (n: string) => findNodeByName(doc, n) !== null;
  const detach = planBakedDetaches(slots, list, exists);
  for (const n of detach) detachNodeByName(doc, n);
  const skip = planBakedSkips(slots, list, exists);
  return { detach, attach: list.map((a) => a.id).filter((id) => !skip.has(id)) };
}

const STANDARD: Array<[string, string, boolean]> = [
  ["rsaf_beret", "headdress_beret", true],
  ["rsaf_cap_badge_sltc_me6_below", "cap_badge", true],
  ["rsaf_no4_rank_epaulette", "rank_epaulette_chest", true],
  ["no4_belt_black", "belt", true],
  ["black_socks", "socks", true],
  ["safety_boots", "footwear", true],
  ["rsaf_vocation_badge", "vocation_badge", false],
];

test("readBakedSlots: absent extras → {} (pre-existing bodies unaffected)", () => {
  assert.deepEqual(readBakedSlots(new Document()), {});
  assert.deepEqual(readBakedSlots(figure()), SLOTS);
});

test("slotOf: every headdress variant shares one slot", () => {
  assert.equal(slotOf("headdress_beret"), "headdress");
  assert.equal(slotOf("headdress_sikh_turban"), "headdress");
  assert.equal(slotOf("cap_badge"), "cap_badge");
});

test("standard profile: everything built-in is skipped, only extras attach", () => {
  const r = plan(figure(), STANDARD);
  assert.deepEqual(r.detach, ["wing_badge_assembly"]);
  assert.deepEqual(r.attach, ["rsaf_vocation_badge"]);
});

test("Sikh COL: turban replaces beret, and the badge goes with it", () => {
  const doc = figure();
  const r = plan(doc, [
    ["rsaf_sikh_turban", "headdress_sikh_turban", true],
    ["rsaf_cap_badge_col_me7", "cap_badge", true],
    ...STANDARD.slice(2),
  ]);
  assert.ok(r.detach.includes("beret"));
  assert.equal(findNodeByName(doc, "beret"), null);
  assert.equal(findNodeByName(doc, "beret_badge"), null);
  assert.deepEqual(r.attach, ["rsaf_sikh_turban", "rsaf_cap_badge_col_me7", "rsaf_vocation_badge"]);
});

test("Sikh standard rank: built-in badge id matches but its node left with the beret → attaches", () => {
  const r = plan(figure(), [
    ["rsaf_sikh_turban", "headdress_sikh_turban", true],
    ["rsaf_cap_badge_sltc_me6_below", "cap_badge", true],
  ]);
  assert.deepEqual(r.attach, ["rsaf_sikh_turban", "rsaf_cap_badge_sltc_me6_below"]);
});

test("COL (not Sikh): only the badge is swapped, beret stays", () => {
  const doc = figure();
  const r = plan(doc, [["rsaf_beret", "headdress_beret", true], ["rsaf_cap_badge_col_me7", "cap_badge", true]]);
  assert.deepEqual(r.detach, ["wing_badge_assembly", "beret_badge"]);
  assert.ok(findNodeByName(doc, "beret"));
  assert.deepEqual(r.attach, ["rsaf_cap_badge_col_me7"]);
});

test("Officer Cadet: cadet rank tab replaces the built-in tab", () => {
  const r = plan(figure(), [["rsaf_no4_rank_epaulette_cadet_trainee", "rank_epaulette_chest", true]]);
  assert.deepEqual(r.detach, ["wing_badge_assembly", "rank_tab"]);
  assert.deepEqual(r.attach, ["rsaf_no4_rank_epaulette_cadet_trainee"]);
});

test("optional alternative in an occupied slot never strips the built-in part", () => {
  const doc = figure();
  const r = plan(doc, [["safety_boots", "footwear", true], ["combat_boots", "footwear", false]]);
  assert.deepEqual(r.detach, ["wing_badge_assembly"]);
  assert.ok(findNodeByName(doc, "boots"));
  assert.deepEqual(r.attach, []);
});

/** [min, max] of the red channel — the tape fill and the text stroke. */
test("optional built-in part: removed by default, kept when the wearer ticked it", () => {
  const off = figure();
  plan(off, STANDARD);
  assert.equal(findNodeByName(off, "wing_badge_assembly"), null);

  const on = figure();
  const r = plan(on, [...STANDARD, ["saf_badges_chest", "saf_badge", false]]);
  assert.ok(findNodeByName(on, "wing_badge_assembly"));
  assert.ok(!r.attach.includes("saf_badges_chest"), "kept built-in part, nothing attached on top");
});

async function redRange(doc: Document, mat: string): Promise<[number, number]> {
  const img = doc.getRoot().listMaterials().find((m) => m.getName() === mat)!.getBaseColorTexture()!.getImage()!;
  const { channels } = await sharp(Buffer.from(img)).stats();
  return [channels[0].min, channels[0].max];
}

async function tapeDoc(rgb: number): Promise<Document> {
  const doc = new Document();
  const png = await sharp({ create: { width: 512, height: 96, channels: 3, background: { r: rgb, g: rgb, b: rgb } } })
    .png().toBuffer();
  const tex = doc.createTexture("t").setImage(new Uint8Array(png)).setMimeType("image/png");
  doc.createMaterial("name_tag_mat").setBaseColorTexture(tex);
  return doc;
}

test("bakeNameTag: white text on a dark tape, dark text on a light tape", async () => {
  const dark = await tapeDoc(20);
  assert.ok(await bakeNameTag(dark, "name_tag_mat", "TAN"));
  const [, darkMax] = await redRange(dark, "name_tag_mat");
  assert.ok(darkMax > 200, `expected light text on a dark tape, brightest pixel ${darkMax}`);

  const light = await tapeDoc(245);
  assert.ok(await bakeNameTag(light, "name_tag_mat", "TAN"));
  const [lightMin] = await redRange(light, "name_tag_mat");
  assert.ok(lightMin < 60, `expected dark text on a light tape, darkest pixel ${lightMin}`);
});
