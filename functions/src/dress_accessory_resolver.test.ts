/**
 * Parity tests for `dress_accessory_resolver.ts` — the same No.4 / No.3
 * scenarios as `test/data/reference_data_integrity_test.dart`, run over
 * the real seed snapshot in `assets/data/` so the Dart resolver and this
 * port can't silently drift.
 *
 * Build first (`npm run build`), then `node --test lib`.
 */

import { strict as assert } from "node:assert";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { test } from "node:test";

import {
  AccessoryRecord,
  Branch,
  DressRequirementRecord,
  Gender,
  RankCode,
  resolveAccessorySplit,
} from "./dress_accessory_resolver";

const DATA_DIR = resolve(__dirname, "..", "..", "assets", "data");
const library = (
  JSON.parse(readFileSync(resolve(DATA_DIR, "accessory_library.v1.json"), "utf8")) as {
    accessories: AccessoryRecord[];
  }
).accessories;
const requirements = new Map<string, DressRequirementRecord>(
  (
    JSON.parse(readFileSync(resolve(DATA_DIR, "dress_requirements.v1.json"), "utf8")) as {
      dressRequirements: DressRequirementRecord[];
    }
  ).dressRequirements.map((r) => [r.id, r]),
);

function ids(
  dressId: string,
  branch: Branch,
  opts: { rank?: RankCode; gender?: Gender; isSikh?: boolean; mandatoryOnly?: boolean } = {},
): Set<string> {
  const split = resolveAccessorySplit(requirements.get(dressId)!, library, {
    branch,
    rank: opts.rank ?? "CPL",
    gender: opts.gender ?? "male",
    isSikh: opts.isSikh ?? false,
  });
  return new Set([
    ...split.mandatory.map((a) => a.id),
    ...(opts.mandatoryOnly ? [] : split.optional.map((a) => a.id)),
  ]);
}

const NO4 = "no_4_dress_requirements";
const NO3 = "no_3_dress_requirements";

for (const branch of ["army", "navy", "rsaf", "dis"] as Branch[]) {
  test(`No.4 ${branch}: beret (men + ladies), chest rank tab, tags, one pair of boots`, () => {
    for (const gender of ["male", "female", "maternity"] as Gender[]) {
      const m = ids(NO4, branch, { gender, mandatoryOnly: true });
      assert.ok(m.has(`${branch}_beret`), `${branch}/${gender} beret`);
      assert.ok(m.has(`${branch}_no4_rank_epaulette`));
      assert.ok(m.has("name_tag_standard"));
      assert.ok(m.has("singapore_tag"));
      const footwear = library.filter((a) => m.has(a.id) && a.category === "footwear");
      assert.equal(footwear.length, 1, `${branch}/${gender} exactly one mandatory footwear`);
    }
  });
}

test("No.4 Officer Cadet gets the cadet/trainee rank tab", () => {
  const m = ids(NO4, "army", { rank: "OCT" });
  assert.ok(m.has("army_no4_rank_epaulette_cadet_trainee"));
  assert.ok(!m.has("army_no4_rank_epaulette"));
});

test("No.4 Army Sikh COL: col_me7 turban + badge, field turban optional", () => {
  const m = ids(NO4, "army", { rank: "COL", isSikh: true });
  assert.ok(m.has("army_sikh_turban_col_me7_above"));
  assert.ok(m.has("army_cap_badge_col_me7"));
  assert.ok(m.has("sikh_field_turban_green"));
  assert.ok(!m.has("army_beret"));
});

test("No.4 BG+ cap badges", () => {
  assert.ok(ids(NO4, "rsaf", { rank: "BG" }).has("rsaf_cap_badge_bg_me8_above_beret"));
  assert.ok(ids(NO4, "dis", { rank: "BG" }).has("dis_cap_badge_bg_me8_radm_above"));
});

test("No.3 DIS headdress (unisex beret) resolves", () => {
  assert.ok(ids(NO3, "dis").has("dis_beret"));
  assert.ok(ids(NO3, "dis", { isSikh: true }).has("dis_sikh_turban"));
});

test("No.3 Army is unchanged by the No.4 keys", () => {
  const m = ids(NO3, "army");
  assert.ok(m.has("army_beret"));
  assert.ok(m.has("army_enlistee_insignia"));
  assert.ok(!m.has("singapore_tag"));
  const lady = ids(NO3, "army", { gender: "female" });
  assert.ok(lady.has("army_ladies_hat_specialist_enlistee_me1_me2"));
  assert.ok(!lady.has("army_beret"));
});
