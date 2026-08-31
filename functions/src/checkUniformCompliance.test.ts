/**
 * Tests for `checkUniformCompliance.ts`'s pure, network-free surfaces:
 * the response-validation zod schema and the prompt-text builder.
 *
 * No real Anthropic API call is made here — the whole point of forcing
 * tool-use + zod-validating the result server-side is that the model's
 * output shape is never trusted blindly, so that's exactly what these
 * tests exercise with fixture payloads standing in for tool-call output.
 */

import { strict as assert } from "node:assert";
import { test } from "node:test";

import { buildPromptText, ComplianceResponse } from "./checkUniformCompliance";
import { AccessoryRecord, ResolvedAccessory } from "./dress_accessory_resolver";

function accessory(
  id: string,
  displayName: string,
  category = "headdress_beret",
): ResolvedAccessory {
  const record: AccessoryRecord = {
    id,
    display_name: displayName,
    category,
  };
  return { id, record };
}

test("ComplianceResponse: accepts a well-formed tool-call payload", () => {
  const payload = {
    overallScore: 75,
    summary: "Beret is correctly worn; name tag missing.",
    items: [
      {
        accessoryId: "army_beret",
        displayName: "Army Beret",
        status: "correct",
        note: "Visible on head, correct angle.",
      },
      {
        accessoryId: "name_tag_standard",
        displayName: "Name Tag",
        status: "missing",
        note: "No name tag visible on chest pocket.",
      },
    ],
  };
  const parsed = ComplianceResponse.parse(payload);
  assert.equal(parsed.overallScore, 75);
  assert.equal(parsed.items.length, 2);
  assert.equal(parsed.items[0]?.status, "correct");
});

test("ComplianceResponse: rejects an out-of-range overallScore", () => {
  const payload = {
    overallScore: 140,
    summary: "x",
    items: [],
  };
  assert.throws(() => ComplianceResponse.parse(payload));
});

test("ComplianceResponse: rejects an unknown status value", () => {
  const payload = {
    overallScore: 50,
    summary: "x",
    items: [
      {
        accessoryId: "a",
        displayName: "A",
        status: "probably_fine", // not one of the 4 allowed enum values
        note: "n",
      },
    ],
  };
  assert.throws(() => ComplianceResponse.parse(payload));
});

test("ComplianceResponse: rejects a missing required field", () => {
  const payload = {
    overallScore: 50,
    // summary omitted
    items: [],
  };
  assert.throws(() => ComplianceResponse.parse(payload));
});

test("buildPromptText: lists every expected accessory id and name", () => {
  const expected = [
    accessory("army_beret", "Army Beret"),
    accessory("name_tag_standard", "Name Tag", "name_tag"),
  ];
  const text = buildPromptText(expected);
  assert.match(text, /id="army_beret"/);
  assert.match(text, /name="Army Beret"/);
  assert.match(text, /id="name_tag_standard"/);
  assert.match(text, /category="name_tag"/);
});

test("buildPromptText: empty expected list still produces valid instructions", () => {
  const text = buildPromptText([]);
  assert.match(text, /report_compliance/);
  assert.doesNotMatch(text, /id="/);
});
