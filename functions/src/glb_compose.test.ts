/**
 * Tests for `glb_compose.ts` — runs under Node 20's built-in test
 * runner (no Jest / Mocha dep).
 *
 * Build first (`npm run build`), then `node --test lib`.
 *
 * Tests construct in-memory `Document` instances rather than reading
 * GLB bytes from disk so the fixtures are fully self-contained. The
 * Phase-2 merger only depends on the scene-graph shape (named nodes,
 * named materials, base-color textures) — not on the rigging or
 * skinning details — so an in-memory fixture exercises every code
 * path that matters.
 */

import { strict as assert } from "node:assert";
import { test } from "node:test";

import { Document } from "@gltf-transform/core";
import sharp from "sharp";

import { NodeIO } from "@gltf-transform/core";

import {
  attachAccessory,
  bakeNameTag,
  compressForWeb,
  consolidateBuffersToOne,
  consolidateScenesToOne,
  detachNodeByName,
  FEET_NODE,
  findNodeByName,
  HAIR_NODE,
  mergeUniform,
  NAME_TAG_MATERIAL,
} from "./glb_compose";

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

function buildBodyFixture(): Document {
  const doc = new Document();
  const scene = doc.createScene("body_scene");
  for (const name of ["head", HAIR_NODE, "torso", FEET_NODE]) {
    const n = doc.createNode(name);
    scene.addChild(n);
  }
  // Sockets the merger looks up by name.
  for (const socket of [
    "head_top",
    "left_chest_pocket",
    "right_chest_pocket",
    "belt_center",
  ]) {
    const n = doc.createNode(socket);
    scene.addChild(n);
  }
  return doc;
}

function buildAccessoryFixture(rootName: string): Document {
  const doc = new Document();
  const scene = doc.createScene("acc_scene");
  const root = doc.createNode(rootName);
  scene.addChild(root);
  return doc;
}

async function tinyWhitePng(): Promise<Uint8Array> {
  const buf = await sharp({
    create: {
      width: 16,
      height: 16,
      channels: 3,
      background: { r: 255, g: 255, b: 255 },
    },
  })
    .png()
    .toBuffer();
  return new Uint8Array(buf);
}

// ---------------------------------------------------------------------------
// findNodeByName
// ---------------------------------------------------------------------------

test("findNodeByName: returns top-level scene-root node", () => {
  const doc = buildBodyFixture();
  const node = findNodeByName(doc, "head");
  assert.ok(node);
  assert.equal(node!.getName(), "head");
});

test("findNodeByName: returns nested descendant", () => {
  const doc = new Document();
  const scene = doc.createScene("s");
  const parent = doc.createNode("parent");
  const child = doc.createNode("deep_node");
  parent.addChild(child);
  scene.addChild(parent);

  const found = findNodeByName(doc, "deep_node");
  assert.ok(found);
  assert.equal(found!.getName(), "deep_node");
});

test("findNodeByName: returns null on miss", () => {
  const doc = buildBodyFixture();
  assert.equal(findNodeByName(doc, "nonexistent_socket"), null);
});

// ---------------------------------------------------------------------------
// detachNodeByName
// ---------------------------------------------------------------------------

test("detachNodeByName: removes the FEET_NODE when footwear mounts", () => {
  const doc = buildBodyFixture();
  // Sanity: fixture sets up `feet` as a sibling of `body` / `head`.
  assert.ok(findNodeByName(doc, FEET_NODE), "fixture has feet node");
  assert.equal(detachNodeByName(doc, FEET_NODE), true);
  assert.equal(findNodeByName(doc, FEET_NODE), null);
});

test("detachNodeByName: removes a top-level scene-root node", () => {
  const doc = buildBodyFixture();
  assert.equal(detachNodeByName(doc, HAIR_NODE), true);
  assert.equal(findNodeByName(doc, HAIR_NODE), null);
});

test("detachNodeByName: returns false when node is absent", () => {
  const doc = buildBodyFixture();
  assert.equal(detachNodeByName(doc, "no_such_node"), false);
});

// ---------------------------------------------------------------------------
// mergeUniform
// ---------------------------------------------------------------------------

test("mergeUniform: appends source's nodes to target", () => {
  const body = buildBodyFixture();
  const uniform = new Document();
  const uniformScene = uniform.createScene("u");
  uniformScene.addChild(uniform.createNode("uniform_mesh"));

  mergeUniform(body, uniform);

  assert.ok(findNodeByName(body, "uniform_mesh"));
  // Body fixture nodes still present.
  assert.ok(findNodeByName(body, "head"));
  assert.ok(findNodeByName(body, "head_top"));
});

// ---------------------------------------------------------------------------
// attachAccessory
// ---------------------------------------------------------------------------

test("attachAccessory: re-parents merged accessory root under named socket", () => {
  const body = buildBodyFixture();
  const acc = buildAccessoryFixture("beret_root");

  const result = attachAccessory(body, acc, "head_top", [0, 0.013, 0]);
  assert.equal(result.attached, true);
  assert.equal(result.rootsAttached, 1);

  const accRoot = findNodeByName(body, "beret_root");
  assert.ok(accRoot);
  // Parent should be the head_top socket (a Node), not a Scene.
  const parent = accRoot!.getParentNode();
  assert.ok(parent);
  assert.equal(parent!.getName(), "head_top");
  // Translation is the offset we passed.
  const t = accRoot!.getTranslation();
  assert.equal(t[1].toFixed(4), "0.0130");
});

test("attachAccessory: returns attached=false when socket is missing", () => {
  const body = buildBodyFixture();
  const acc = buildAccessoryFixture("ribbon_root");

  const result = attachAccessory(body, acc, "no_such_socket", [0, 0, 0]);
  assert.equal(result.attached, false);
  assert.match(result.reason ?? "", /socket node/);
  assert.equal(result.rootsAttached, 0);
  // Accessory must not have been merged.
  assert.equal(findNodeByName(body, "ribbon_root"), null);
});

test("attachAccessory: mirror=true attaches an identity-scale copy under both left/right sockets", () => {
  // Add the left + right shoulder sockets to the body fixture so the
  // mirror resolution has both targets available.
  const body = buildBodyFixture();
  const scene = body.getRoot().listScenes()[0];
  for (const name of ["left_shoulder_seam", "right_shoulder_seam"]) {
    if (!findNodeByName(body, name)) scene.addChild(body.createNode(name));
  }

  const acc = buildAccessoryFixture("epaulette_root");
  const result = attachAccessory(
    body,
    acc,
    "shoulder_seam",
    [0, 0.01, 0],
    { mirror: true },
  );
  assert.equal(result.attached, true);
  assert.equal(result.rootsAttached, 2, "expected one root attached per side");
  assert.deepEqual(result.sockets.sort(), [
    "left_shoulder_seam",
    "right_shoulder_seam",
  ]);

  // Both copies of the accessory root should now exist as children of
  // the respective sockets.
  const leftSocket = findNodeByName(body, "left_shoulder_seam");
  const rightSocket = findNodeByName(body, "right_shoulder_seam");
  assert.ok(leftSocket && rightSocket);
  const leftKids = leftSocket!
    .listChildren()
    .filter((n) => n.getName() === "epaulette_root");
  const rightKids = rightSocket!
    .listChildren()
    .filter((n) => n.getName() === "epaulette_root");
  assert.equal(leftKids.length, 1, "left socket has exactly one accessory child");
  assert.equal(rightKids.length, 1, "right socket has exactly one accessory child");

  // Both copies attach with identity scale. Pass-5 previously applied
  // scale=[-1, 1, 1] on the right copy for an X-mirror, but the
  // resulting inverted winding combined with default back-face culling
  // hid the right-side mesh. Pass-6 removed the negative scale.
  assert.deepEqual(
    leftKids[0].getScale(),
    [1, 1, 1],
    "left side scale identity",
  );
  assert.deepEqual(
    rightKids[0].getScale(),
    [1, 1, 1],
    "right side scale identity (no negative-scale mirror)",
  );
});

test("attachAccessory: mirror=true with one missing socket falls through gracefully (partial success)", () => {
  const body = buildBodyFixture();
  // Body fixture has no shoulder sockets at all → both sides missing.
  const acc = buildAccessoryFixture("epaulette_root");
  const result = attachAccessory(
    body,
    acc,
    "shoulder_seam",
    [0, 0, 0],
    { mirror: true },
  );
  assert.equal(result.attached, false);
  assert.equal(result.rootsAttached, 0);
  assert.deepEqual(result.sockets, []);
  assert.match(result.reason ?? "", /not found/);
});

test("attachAccessory: mirror=false on a paired-alias socket name still does single-socket attach", () => {
  const body = buildBodyFixture();
  const scene = body.getRoot().listScenes()[0];
  scene.addChild(body.createNode("left_shoulder_seam"));
  scene.addChild(body.createNode("right_shoulder_seam"));

  const acc = buildAccessoryFixture("badge_root");
  // mirror=false → the literal "shoulder_seam" name is looked up;
  // it doesn't exist as a literal node, so the call should fail.
  const result = attachAccessory(body, acc, "shoulder_seam", [0, 0, 0], {
    mirror: false,
  });
  assert.equal(result.attached, false);
  // The accessory must NOT have been merged when the literal lookup fails.
  assert.equal(findNodeByName(body, "badge_root"), null);
});

// ---------------------------------------------------------------------------
// bakeNameTag
// ---------------------------------------------------------------------------

test("bakeNameTag: replaces existing base-color texture image bytes", async () => {
  const doc = new Document();
  doc.createScene("s");
  const mat = doc.createMaterial(NAME_TAG_MATERIAL);
  const seedImage = await tinyWhitePng();
  const tex = doc
    .createTexture("base")
    .setImage(seedImage)
    .setMimeType("image/png");
  mat.setBaseColorTexture(tex);

  const baked = await bakeNameTag(doc, NAME_TAG_MATERIAL, "TAN");
  assert.equal(baked, true);

  const after = tex.getImage();
  assert.ok(after);
  // The new bytes should differ from the seed (text composited on top).
  assert.notEqual(after!.byteLength, seedImage.byteLength);
  // Must still be a PNG (signature: 0x89 0x50 0x4E 0x47).
  assert.equal(after![0], 0x89);
  assert.equal(after![1], 0x50);
  assert.equal(after![2], 0x4e);
  assert.equal(after![3], 0x47);
});

test("bakeNameTag: returns false when material is absent", async () => {
  const doc = new Document();
  doc.createScene("s");
  const result = await bakeNameTag(doc, "no_such_material", "TAN");
  assert.equal(result, false);
});

test("bakeNameTag: synthesises a texture when material has no base-color texture", async () => {
  const doc = new Document();
  doc.createScene("s");
  doc.createMaterial(NAME_TAG_MATERIAL);

  const baked = await bakeNameTag(doc, NAME_TAG_MATERIAL, "OOI");
  assert.equal(baked, true);

  const mat = doc
    .getRoot()
    .listMaterials()
    .find((m) => m.getName() === NAME_TAG_MATERIAL);
  const tex = mat!.getBaseColorTexture();
  assert.ok(tex);
  const img = tex!.getImage();
  assert.ok(img);
  assert.equal(img![0], 0x89); // PNG signature
});

// ---------------------------------------------------------------------------
// compressForWeb
// ---------------------------------------------------------------------------

test("compressForWeb: runs dedup+prune on an empty document without throwing", async () => {
  const doc = new Document();
  doc.createScene("s");
  const result = await compressForWeb(doc, {
    applyDraco: false,
    applyWebp: false,
  });
  assert.equal(result.dracoApplied, false);
  assert.equal(result.webpApplied, false);
});

// ---------------------------------------------------------------------------
// consolidateBuffersToOne — required before NodeIO.writeBinary, which
// rejects multi-buffer documents with "GLB must have 0–1 buffers".
// ---------------------------------------------------------------------------

test("consolidateBuffersToOne: collapses N buffers from mergeDocuments to 1", () => {
  const a = new Document();
  const sceneA = a.createScene("a");
  const accA = a
    .createAccessor()
    .setType("VEC3")
    .setArray(new Float32Array([0, 0, 0, 1, 1, 1]))
    .setBuffer(a.createBuffer("a"));
  const meshA = a
    .createMesh()
    .addPrimitive(a.createPrimitive().setAttribute("POSITION", accA));
  sceneA.addChild(a.createNode("a_node").setMesh(meshA));

  const b = new Document();
  const sceneB = b.createScene("b");
  const accB = b
    .createAccessor()
    .setType("VEC3")
    .setArray(new Float32Array([2, 2, 2, 3, 3, 3]))
    .setBuffer(b.createBuffer("b"));
  const meshB = b
    .createMesh()
    .addPrimitive(b.createPrimitive().setAttribute("POSITION", accB));
  sceneB.addChild(b.createNode("b_node").setMesh(meshB));

  mergeUniform(a, b);
  assert.equal(a.getRoot().listBuffers().length, 2, "before: 2 buffers");

  const finalCount = consolidateBuffersToOne(a);
  assert.equal(finalCount, 1, "after: 1 buffer");
  assert.equal(a.getRoot().listAccessors().length, 2, "accessors preserved");
});

test("consolidateBuffersToOne + NodeIO.writeBinary succeeds where it previously errored", async () => {
  const a = new Document();
  const sceneA = a.createScene("a");
  const accA = a
    .createAccessor()
    .setType("VEC3")
    .setArray(new Float32Array([0, 0, 0, 1, 1, 1]))
    .setBuffer(a.createBuffer("a"));
  sceneA.addChild(
    a
      .createNode("a_node")
      .setMesh(
        a
          .createMesh()
          .addPrimitive(a.createPrimitive().setAttribute("POSITION", accA)),
      ),
  );

  const b = new Document();
  const sceneB = b.createScene("b");
  const accB = b
    .createAccessor()
    .setType("VEC3")
    .setArray(new Float32Array([2, 2, 2, 3, 3, 3]))
    .setBuffer(b.createBuffer("b"));
  sceneB.addChild(
    b
      .createNode("b_node")
      .setMesh(
        b
          .createMesh()
          .addPrimitive(b.createPrimitive().setAttribute("POSITION", accB)),
      ),
  );

  mergeUniform(a, b);

  // Confirm the pre-fix write actually fails with the production-shape
  // error message — guards us against regression if upstream gltf-transform
  // ever relaxes the check (in which case this test fails LOUDLY and we
  // can drop the consolidation step).
  const io = new NodeIO();
  await assert.rejects(
    io.writeBinary(a),
    /GLB must have 0[–-]1 buffers/,
    "pre-fix write should fail with the multi-buffer error",
  );

  consolidateBuffersToOne(a);

  // Post-fix: write succeeds.
  const out = await io.writeBinary(a);
  assert.ok(out.byteLength > 0, "non-empty GLB written");
});

test("consolidateBuffersToOne: no-op when document already has ≤1 buffer", () => {
  const doc = new Document();
  doc.createScene("s");
  // No buffer at all
  assert.equal(consolidateBuffersToOne(doc), 0);

  doc
    .createAccessor()
    .setType("VEC3")
    .setArray(new Float32Array([0, 0, 0]))
    .setBuffer(doc.createBuffer());
  // Single buffer
  assert.equal(consolidateBuffersToOne(doc), 1);
});

// ---------------------------------------------------------------------------
// consolidateScenesToOne — mergeDocuments leaves source scenes as separate
// Scene objects on the target. The default-scene-only renderer convention
// means uniform + accessory geometry ends up out of frame unless we collapse
// scenes before write.
// ---------------------------------------------------------------------------

test("consolidateScenesToOne: collapses N scenes into the first scene", () => {
  const a = new Document();
  const sceneA = a.createScene("a");
  sceneA.addChild(a.createNode("a_root"));
  const b = new Document();
  const sceneB = b.createScene("b");
  sceneB.addChild(b.createNode("b_root"));

  mergeUniform(a, b);
  assert.equal(a.getRoot().listScenes().length, 2, "pre: 2 scenes");

  const final = consolidateScenesToOne(a);
  assert.equal(final, 1, "post: 1 scene");
  const primary = a.getRoot().listScenes()[0];
  const childNames = primary.listChildren().map((c) => c.getName()).sort();
  assert.deepEqual(childNames, ["a_root", "b_root"], "both roots under primary");
});

test("consolidateScenesToOne: no-op when document already has ≤1 scene", () => {
  const doc = new Document();
  // No scene at all
  assert.equal(consolidateScenesToOne(doc), 0);
  doc.createScene("only");
  assert.equal(consolidateScenesToOne(doc), 1);
});

test("consolidateScenesToOne: full compose pipeline yields a single scene", async () => {
  const body = buildBodyFixture();
  const uniform = buildAccessoryFixture("uniform_mesh");
  const beret = buildAccessoryFixture("beret_mesh");
  const chevron = buildAccessoryFixture("chevron_mesh");

  mergeUniform(body, uniform);
  attachAccessory(body, beret, "head_top", [0, 0.02, 0]);
  attachAccessory(body, chevron, "left_chest_pocket", [0, 0, 0]);

  assert.ok(
    body.getRoot().listScenes().length >= 2,
    "pre-compress: multiple scenes from merges",
  );

  await compressForWeb(body, { applyDraco: false, applyWebp: false });
  assert.equal(
    body.getRoot().listScenes().length,
    1,
    "post-compress: exactly one scene",
  );
});
