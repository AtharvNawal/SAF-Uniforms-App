/// User-selectable visual theme accent.
///
/// Decoupled from `BranchId` so a user can pick a non-branch theme
/// (e.g. the SAF Crest) without changing their service-derived data
/// (Firestore reference content, accessory IDs, etc.).
///
/// `SafCrest` — default — uses the navy/gold SAF crest palette regardless
/// of branch.
/// `FollowBranch` — derives the active `BranchTheme` from
/// `currentBranchProvider` (i.e. the user's selected service).
sealed class ThemeAccent {
  const ThemeAccent();

  /// Stable wire format used to persist the choice in `SharedPreferences`.
  String get wireName;

  static ThemeAccent fromWireName(String? value) {
    return switch (value) {
      'follow' => const FollowBranch(),
      'saf_crest' => const SafCrest(),
      _ => const SafCrest(),
    };
  }
}

class FollowBranch extends ThemeAccent {
  const FollowBranch();

  @override
  String get wireName => 'follow';
}

class SafCrest extends ThemeAccent {
  const SafCrest();

  @override
  String get wireName => 'saf_crest';
}
