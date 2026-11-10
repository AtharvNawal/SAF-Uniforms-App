"""Inspection-profile validation and exact doctrine configuration selection."""

from __future__ import annotations

from dataclasses import dataclass

from rules.rule_loader import RuleConfig, RuleConfigError, load_rule_config


@dataclass(frozen=True)
class InspectionProfile:
    service: str
    dress: str
    gender: str
    rank_tier: str
    personnel_category: str = "regular"
    is_sikh: bool = False

    @property
    def uniform_type(self) -> str:
        return f"{self.service}_{self.dress}_{self.gender}"

    def as_rule_profile(self) -> dict:
        return {
            "service": self.service,
            "dress": self.dress,
            "gender": self.gender,
            "rank_tier": self.rank_tier,
            "personnel_category": self.personnel_category,
            "isSikh": self.is_sikh,
        }


def profile_from_uniform_type(
    uniform_type: str,
    rank_tier: str,
    gender: str,
    personnel_category: str = "regular",
    is_sikh: bool = False,
) -> InspectionProfile:
    parts = uniform_type.lower().split("_")
    if len(parts) != 3 or parts[1] not in {"no3", "no4"} or parts[2] not in {"male", "female"}:
        raise RuleConfigError(
            "uniform_type must use '<service>_<no3|no4>_<male|female>'"
        )
    return InspectionProfile(
        service=parts[0],
        dress=parts[1],
        gender=parts[2],
        rank_tier=rank_tier,
        personnel_category=personnel_category.lower(),
        is_sikh=is_sikh,
    )


def select_rule_config(profile: InspectionProfile, spec) -> RuleConfig:
    config = load_rule_config(spec.rules_path)
    metadata = config.metadata
    if metadata.get("branch") != profile.service:
        raise RuleConfigError(
            f"Rule service mismatch: profile={profile.service}, config={metadata.get('branch')}"
        )
    if str(metadata.get("dress_code", "")).lower().replace("_", "") != profile.dress:
        raise RuleConfigError(
            f"Rule dress mismatch: profile={profile.dress}, config={metadata.get('dress_code')}"
        )
    config_gender = str(metadata.get("gender", "")).lower()
    if profile.gender == "male" and config_gender not in {"men", "male", "unisex"}:
        raise RuleConfigError(f"Rule gender mismatch: profile={profile.gender}, config={config_gender}")
    if profile.gender == "female" and config_gender not in {"women", "female", "ladies", "unisex"}:
        raise RuleConfigError(f"Rule gender mismatch: profile={profile.gender}, config={config_gender}")
    return config
