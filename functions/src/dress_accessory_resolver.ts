/**
 * TypeScript port of `lib/features/checklist/domain/services/dress_accessory_resolver.dart`.
 *
 * The Cloud Function resolves the same accessory list as the Flutter
 * client so that the composed 3D model exactly matches what the user
 * sees on the Wardrobe / Checklist screens. Any change here must be
 * mirrored in the Dart resolver.
 */

export type Gender = "male" | "female" | "maternity";
export type Branch = "army" | "navy" | "rsaf" | "dis";

/**
 * Per-rank tiers used by doctrine. The string values match the rank
 * codes on the Dart `Rank` enum (e.g. "REC", "COL", "LG").
 */
export type RankCode =
  | "REC" | "PTE" | "LCP" | "CPL" | "CFC"
  | "3SG" | "2SG" | "1SG" | "SSG" | "MSG"
  | "3WO" | "2WO" | "1WO" | "MWO" | "SWO" | "CWO"
  | "OCT" | "2LT" | "LTA" | "CPT" | "MAJ" | "LTC" | "SLTC" | "COL"
  | "BG" | "MG" | "LG";

export interface ResolverProfile {
  branch: Branch;
  rank: RankCode;
  gender: Gender;
  isSikh: boolean;
}

/**
 * Shape of an entry in `accessory_library/{accessoryId}` after Firestore
 * has decoded it. Only the fields the resolver needs are typed; the rest
 * are passed through as `unknown`.
 */
export interface AccessoryRecord {
  id: string;
  display_name?: string;
  image_url?: string;
  placement_diagram?: string;
  rules?: Record<string, unknown>;
  render_logic?: Record<string, unknown>;
  branch_id?: string | null;
  category?: string | null;
  gender?: string | null;
  version?: number;
}

/**
 * Shape of a `dress_requirements/{dressId}` document. `branch_overrides`
 * is the structured per-branch override map keyed by branch wireName.
 * It carries every mandatory and optional accessory selection — including
 * universal items like belt / socks / footwear that happen to share
 * values across branches today (they're duplicated rather than living
 * in a separate top-level field, so the resolver has ONE place to look).
 */
export interface DressRequirementRecord {
  id: string;
  branch_overrides?: Record<string, Record<string, unknown>>;
  // Other fields exist on the doc but the resolver doesn't need them.
}

export interface ResolvedAccessory {
  id: string;
  record: AccessoryRecord;
}

export interface AccessorySplit {
  mandatory: ResolvedAccessory[];
  optional: ResolvedAccessory[];
}

const ENLISTEE_RANKS: ReadonlySet<RankCode> = new Set([
  "REC", "PTE", "LCP", "CPL", "CFC",
]);
const SPECIALIST_RANKS: ReadonlySet<RankCode> = new Set([
  "3SG", "2SG", "1SG", "SSG", "MSG",
]);
const OFFICER_OR_WARRANT_RANKS: ReadonlySet<RankCode> = new Set([
  "3WO", "2WO", "1WO", "MWO", "SWO", "CWO",
  "OCT", "2LT", "LTA", "CPT", "MAJ", "LTC", "SLTC", "COL",
  "BG", "MG", "LG",
]);
const COL_OR_ABOVE: ReadonlySet<RankCode> = new Set([
  "COL", "BG", "MG", "LG",
]);
const BG_OR_ABOVE: ReadonlySet<RankCode> = new Set([
  "BG", "MG", "LG",
]);

function isEnlisteeOrSpecialist(rank: RankCode): "enlistee" | "specialist" | null {
  if (ENLISTEE_RANKS.has(rank)) return "enlistee";
  if (SPECIALIST_RANKS.has(rank)) return "specialist";
  return null;
}

function pickHeaddress(
  headdress: Record<string, unknown>,
  profile: ResolverProfile,
): string | null {
  // Gender-neutral shape (DIS No.3, all of No.4): { unisex, sikh,
  // sikh_col_me7_above }.
  if ("unisex" in headdress) {
    if (profile.isSikh) {
      const colAbove = headdress["sikh_col_me7_above"];
      if (COL_OR_ABOVE.has(profile.rank) && typeof colAbove === "string") {
        return colAbove;
      }
      const sikh = headdress["sikh"];
      if (typeof sikh === "string") return sikh;
    }
    const unisex = headdress["unisex"];
    return typeof unisex === "string" ? unisex : null;
  }

  if (profile.gender === "female" || profile.gender === "maternity") {
    const ladies = headdress["ladies"];
    if (!ladies || typeof ladies !== "object") return null;
    const m = ladies as Record<string, unknown>;
    if (OFFICER_OR_WARRANT_RANKS.has(profile.rank)) {
      const v = m["officer_wo_me3_to_me8"];
      if (typeof v === "string") return v;
    }
    if (isEnlisteeOrSpecialist(profile.rank)) {
      const v = m["specialist_enlistee_me1_me2"];
      if (typeof v === "string") return v;
    }
    return null;
  }

  const men = headdress["men"];
  if (!men || typeof men !== "object") return null;
  const m = men as Record<string, unknown>;
  if (profile.isSikh) {
    if (COL_OR_ABOVE.has(profile.rank) && typeof m["sikh_col_me7_above"] === "string") {
      return m["sikh_col_me7_above"] as string;
    }
    if (typeof m["sikh"] === "string") return m["sikh"] as string;
  }
  return typeof m["default"] === "string" ? (m["default"] as string) : null;
}

function pickByOfficerTier(
  tiers: Record<string, unknown>,
  profile: ResolverProfile,
): string | null {
  const r = profile.rank;
  if (BG_OR_ABOVE.has(r) && typeof tiers["bg_me8_above"] === "string") {
    return tiers["bg_me8_above"] as string;
  }
  if (r === "COL") {
    if (typeof tiers["col_me7"] === "string") return tiers["col_me7"] as string;
    if (typeof tiers["col_me7_above"] === "string") {
      return tiers["col_me7_above"] as string;
    }
  }
  if (COL_OR_ABOVE.has(r) && typeof tiers["col_me7_above"] === "string") {
    return tiers["col_me7_above"] as string;
  }
  if (typeof tiers["sltc_me6_below"] === "string") {
    return tiers["sltc_me6_below"] as string;
  }
  return null;
}

function genderMatches(record: AccessoryRecord, gender: Gender): boolean {
  const raw = record.gender;
  if (!raw) return true;
  if (raw === "unisex") return true;
  if (gender === "female" || gender === "maternity") {
    return raw === "female" || raw === "ladies";
  }
  return raw === "male" || raw === "men";
}

function hydrate(
  ids: Iterable<string>,
  libraryById: Map<string, AccessoryRecord>,
  gender: Gender,
): ResolvedAccessory[] {
  const out: ResolvedAccessory[] = [];
  for (const id of ids) {
    const record = libraryById.get(id);
    if (!record) continue;
    if (record.render_logic?.["legacy_placeholder"] === true) continue;
    if (!genderMatches(record, gender)) continue;
    out.push({ id, record });
  }
  return out;
}

/**
 * Returns the mandatory + optional accessory split for the given
 * profile and dress. Mirrors `DressAccessoryResolver.resolveSplit`
 * in Dart.
 */
export function resolveAccessorySplit(
  requirement: DressRequirementRecord,
  library: AccessoryRecord[],
  profile: ResolverProfile,
): AccessorySplit {
  const override = requirement.branch_overrides?.[profile.branch] ?? {};
  const libraryById = new Map<string, AccessoryRecord>(
    library.map((a) => [a.id, a]),
  );

  const mandatoryIds = new Set<string>();
  const optionalIds = new Set<string>();

  function addMandatory(raw: unknown): void {
    if (typeof raw === "string" && raw.length > 0) mandatoryIds.add(raw);
  }
  function addOptional(raw: unknown): void {
    if (typeof raw === "string" && raw.length > 0) optionalIds.add(raw);
  }
  function addOptionalAll(raw: unknown): void {
    if (Array.isArray(raw)) {
      for (const item of raw) addOptional(item);
    } else {
      addOptional(raw);
    }
  }

  // headdress — gendered or gender-neutral selector, plus optional
  // `alternatives` / `sikh_alternatives` id lists (No.4 jockey cap /
  // jungle hat / helmet / green field turban).
  const headdress = override["headdress"];
  if (headdress && typeof headdress === "object") {
    const h = headdress as Record<string, unknown>;
    addMandatory(pickHeaddress(h, profile));
    addOptionalAll(h["alternatives"]);
    if (profile.isSikh) addOptionalAll(h["sikh_alternatives"]);
  }

  // cap_badge
  const capBadge = override["cap_badge"];
  if (capBadge && typeof capBadge === "object") {
    addMandatory(pickByOfficerTier(capBadge as Record<string, unknown>, profile));
  } else {
    addMandatory(capBadge);
  }

  // cap_embellishment
  const capEmbellishment = override["cap_embellishment"];
  if (capEmbellishment && typeof capEmbellishment === "object") {
    addMandatory(
      pickByOfficerTier(capEmbellishment as Record<string, unknown>, profile),
    );
  } else {
    addMandatory(capEmbellishment);
  }

  // rank_insignia_sleeve: { specialist, enlistee }
  const sleeve = override["rank_insignia_sleeve"];
  if (sleeve && typeof sleeve === "object") {
    const tier = isEnlisteeOrSpecialist(profile.rank);
    if (tier) {
      addMandatory((sleeve as Record<string, unknown>)[tier]);
    }
  } else {
    addMandatory(sleeve);
  }

  // epaulettes
  const epaulettes = override["epaulettes"];
  if (epaulettes && typeof epaulettes === "object") {
    addMandatory(
      pickByOfficerTier(epaulettes as Record<string, unknown>, profile),
    );
  } else {
    addMandatory(epaulettes);
  }

  // rank_epaulette: { standard, cadet_trainee } — No.4's chest-centre
  // rank tab, worn by every rank. Officer Cadets get the cadet variant.
  const rankEpaulette = override["rank_epaulette"];
  if (rankEpaulette && typeof rankEpaulette === "object") {
    const m = rankEpaulette as Record<string, unknown>;
    const key = profile.rank === "OCT" ? "cadet_trainee" : "standard";
    addMandatory(m[key] ?? m["standard"]);
  } else {
    addMandatory(rankEpaulette);
  }

  // name_tag: mandatory for all branches. Handled by bakeNameTag() in
  // composeUniformModel — included here to keep Dart/TS resolver parity
  // and surface the name tag in the Wardrobe checklist.
  addMandatory(override["name_tag"]);

  // belt / socks / footwear — universal mandatory items shared across
  // branches and dress codes; they live in `branch_overrides` so the
  // resolver picks them up via the same code path as every other
  // mandatory accessory (and the Wardrobe shows them in the Mandatory
  // section automatically). Each value is one of:
  //
  //   - a bare id string                       — single canonical item
  //   - a list of ids                          — alternatives, all
  //                                              added so the Wardrobe
  //                                              lists every option
  //   - a {men, ladies} selector               — gender-picked, where
  //                                              each side itself is
  //                                              one of the above shapes
  const ladiesKey =
    profile.gender === "female" || profile.gender === "maternity"
      ? "ladies"
      : "men";

  function addOne(raw: unknown): void {
    if (typeof raw === "string") {
      addMandatory(raw);
    } else if (Array.isArray(raw)) {
      for (const item of raw) {
        if (typeof item === "string") addMandatory(item);
      }
    }
  }

  function addGenderedMandatory(raw: unknown): void {
    if (raw && typeof raw === "object" && !Array.isArray(raw)) {
      addOne((raw as Record<string, unknown>)[ladiesKey]);
    } else {
      addOne(raw);
    }
  }

  addGenderedMandatory(override["belt"]);
  addGenderedMandatory(override["socks"]);
  addGenderedMandatory(override["footwear"]);

  // optional
  addOptional(override["lanyard"]);
  addOptional(override["arms_badge"]);
  addOptional(override["vocation_badge"]);

  // additional_mandatory / additional_optional — plain id lists (No.4
  // Singapore tag, inner T-shirt, chest / sleeve badges, unit patches).
  const extraMandatory = override["additional_mandatory"];
  if (Array.isArray(extraMandatory)) {
    for (const item of extraMandatory) addMandatory(item);
  }
  addOptionalAll(override["additional_optional"]);

  const mandatory = hydrate(mandatoryIds, libraryById, profile.gender);
  const optionalOnly = new Set<string>();
  for (const id of optionalIds) {
    if (!mandatoryIds.has(id)) optionalOnly.add(id);
  }
  const optional = hydrate(optionalOnly, libraryById, profile.gender);

  return { mandatory, optional };
}
