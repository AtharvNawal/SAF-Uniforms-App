import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/profile_repository_impl.dart';
import '../../domain/entities/branch_id.dart';
import '../../domain/entities/dress_code.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/generated_dress.dart';
import '../../domain/entities/rank.dart';
import '../../domain/entities/uniform_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'uniform_provider.g.dart';

const String _tag = 'profile.notifier';

/// Window after the last setter call before we push the profile to
/// Firestore. Tuned high enough to coalesce rapid wizard taps but low
/// enough to feel real-time.
const Duration _kSyncDebounce = Duration(milliseconds: 500);

/// Mutually exclusive marksmanship-tier badges — picking one clears the
/// other two. Lives here (not in the screens) so Config + Profile share
/// one source of truth.
const Map<String, Set<String>> _kBadgeMutex = <String, Set<String>>{
  'marksman': {'sniper', 'fitness'},
  'sniper': {'marksman', 'fitness'},
  'fitness': {'marksman', 'sniper'},
};

/// Manages the global state of the user's current uniform profile:
/// branch, rank, gender, dress code, Sikh status, and selected accessories.
///
/// Every setter schedules a debounced Firestore upsert (see
/// [_scheduleSync]). Callers that need a guaranteed write (e.g. the
/// Configuration wizard's "Done" step) must `await` [persist] instead.
@Riverpod(keepAlive: true)
class UniformProfileNotifier extends _$UniformProfileNotifier {
  Timer? _debounce;

  @override
  UniformProfile build() {
    ref.onDispose(() => _debounce?.cancel());
    return const UniformProfile();
  }

  /// Replaces in-memory state with values loaded from Firestore.
  /// Called by the post-auth hydration listener; does NOT trigger a
  /// debounced write back (that would be a no-op echo).
  void hydrate(UniformProfile profile) {
    _debounce?.cancel();
    state = profile;
    AppLog.i('hydrated from Firestore', tag: _tag);
  }

  void setBranch(BranchId branch) {
    state = state.copyWith(branch: branch);
    _scheduleSync();
  }

  void setRank(Rank rank) {
    state = state.copyWith(rank: rank);
    _scheduleSync();
  }

  void setGender(Gender gender) {
    state = state.copyWith(gender: gender);
    _scheduleSync();
  }

  void setDressCode(DressCode dressCode) {
    state = state.copyWith(dressCode: dressCode);
    _scheduleSync();
  }

  void setSikh(bool isSikh) {
    state = state.copyWith(isSikh: isSikh);
    _scheduleSync();
  }

  void setFullName(String fullName) {
    if (state.fullName == fullName) return;
    state = state.copyWith(fullName: fullName);
    AppLog.d('setFullName  len=${fullName.length}', tag: _tag);
    _scheduleSync();
  }

  void setVocation(String vocation) {
    if (state.vocation == vocation) return;
    state = state.copyWith(vocation: vocation);
    AppLog.d('setVocation  vocation=$vocation', tag: _tag);
    _scheduleSync();
  }

  void setMedalRowCount(int rows) {
    final clamped = rows.clamp(0, 10);
    if (state.medalRowCount == clamped) return;
    state = state.copyWith(medalRowCount: clamped);
    AppLog.d('setMedalRowCount  rows=$clamped', tag: _tag);
    _scheduleSync();
  }

  /// `0` clears it; anything outside a plausible adult range (140-210 cm)
  /// is treated as not given rather than sent to the measurement.
  void setHeightCm(int heightCm) {
    final value = (heightCm >= 140 && heightCm <= 210) ? heightCm : 0;
    if (state.heightCm == value) return;
    state = state.copyWith(heightCm: value);
    AppLog.d('setHeightCm  heightCm=$value', tag: _tag);
    _scheduleSync();
  }

  void toggleBadge(String badgeId) {
    final next = Set<String>.from(state.selectedBadgeIds);
    if (next.contains(badgeId)) {
      next.remove(badgeId);
    } else {
      next.add(badgeId);
      final excluded = _kBadgeMutex[badgeId];
      if (excluded != null) {
        next.removeWhere(excluded.contains);
      }
    }
    state = state.copyWith(selectedBadgeIds: next);
    AppLog.d(
      'toggleBadge id=$badgeId  selected=${next.toList()..sort()}',
      tag: _tag,
    );
    _scheduleSync();
  }

  void clearBadges() {
    if (state.selectedBadgeIds.isEmpty) return;
    state = state.copyWith(selectedBadgeIds: const <String>{});
    AppLog.i('clearBadges', tag: _tag);
    _scheduleSync();
  }

  void toggleAccessory(String accessoryId) {
    final next = Set<String>.from(state.selectedAccessoryIds);
    if (!next.add(accessoryId)) next.remove(accessoryId);
    state = state.copyWith(selectedAccessoryIds: next);
    _scheduleSync();
  }

  void clearAccessories() {
    state = state.copyWith(selectedAccessoryIds: const <String>{});
    _scheduleSync();
  }

  /// Toggles a single accessory's verified state for the given dress.
  /// Persists per-dress so a tick on No.3 does not affect No.5.
  void toggleDressAccessory(String dressId, String accessoryId) {
    final next = _copyChecks(state.dressAccessoryChecks);
    final inner = Set<String>.from(next[dressId] ?? const <String>{});
    if (!inner.add(accessoryId)) inner.remove(accessoryId);
    if (inner.isEmpty) {
      next.remove(dressId);
    } else {
      next[dressId] = inner;
    }
    state = state.copyWith(dressAccessoryChecks: next);
    AppLog.d(
      'toggleDressAccessory dress=$dressId acc=$accessoryId '
      'now=${inner.toList()..sort()}',
      tag: _tag,
    );
    _scheduleSync();
  }

  /// Sets a single accessory's verified state for the given dress.
  /// Used by the "All Accessories" view, which fans the toggle out across
  /// every dress that lists this accessory id.
  void setDressAccessoryChecked(
    String dressId,
    String accessoryId, {
    required bool checked,
  }) {
    final next = _copyChecks(state.dressAccessoryChecks);
    final inner = Set<String>.from(next[dressId] ?? const <String>{});
    final changed = checked ? inner.add(accessoryId) : inner.remove(accessoryId);
    if (!changed) return;
    if (inner.isEmpty) {
      next.remove(dressId);
    } else {
      next[dressId] = inner;
    }
    state = state.copyWith(dressAccessoryChecks: next);
    _scheduleSync();
  }

  /// Records that a 3D model was successfully generated for [dress].
  /// Persists via the debounced Firestore sync.
  ///
  /// Note: in the new pipeline the **Cloud Function** is the
  /// authoritative writer of `generatedDresses[*]` (it owns
  /// `modelUrl`, `profileHash`, `schemaVersion`, etc). This method is
  /// kept as a thin client-side marker for the legacy "I built this"
  /// flow and will be retired once the CF pipeline is the only path.
  void markDressGenerated(DressCode dress) {
    final next = Map<String, GeneratedDress>.from(state.generatedDresses);
    next[dress.requirementDocId] = GeneratedDress(builtAt: DateTime.now());
    state = state.copyWith(generatedDresses: next);
    AppLog.i('markDressGenerated dress=${dress.requirementDocId}', tag: _tag);
    _scheduleSync();
  }

  /// Optimistic flag the moment the `composeUniformModel` callable
  /// fires. Lets `GhostScreen` swap to a "generating" state without
  /// waiting for the round-trip. The Cloud Function clears the flag
  /// (and writes the real `modelUrl`) when it completes.
  void markGenerationStarted(DressCode dress) {
    final id = dress.requirementDocId;
    final next = Map<String, GeneratedDress>.from(state.generatedDresses);
    final existing = next[id];
    next[id] = GeneratedDress(
      builtAt: existing?.builtAt ?? DateTime.now(),
      modelUrl: existing?.modelUrl,
      profileHash: existing?.profileHash,
      schemaVersion: existing?.schemaVersion,
      generationStartedAt: DateTime.now(),
      error: null,
    );
    state = state.copyWith(generatedDresses: next);
    AppLog.i('markGenerationStarted dress=$id', tag: _tag);
    _scheduleSync();
  }

  /// Records a generation failure so the UI can surface a retry CTA.
  /// Cleared on the next successful generation.
  void markGenerationFailed(DressCode dress, String error) {
    final id = dress.requirementDocId;
    final next = Map<String, GeneratedDress>.from(state.generatedDresses);
    final existing = next[id];
    next[id] = GeneratedDress(
      builtAt: existing?.builtAt ?? DateTime.now(),
      modelUrl: existing?.modelUrl,
      profileHash: existing?.profileHash,
      schemaVersion: existing?.schemaVersion,
      generationStartedAt: null,
      error: error,
    );
    state = state.copyWith(generatedDresses: next);
    AppLog.e('markGenerationFailed dress=$id  error=$error', tag: _tag);
    _scheduleSync();
  }

  /// Drops every check on a dress in one shot. Convenience for reset.
  void clearDressAccessoryChecks(String dressId) {
    if (!state.dressAccessoryChecks.containsKey(dressId)) return;
    final next = _copyChecks(state.dressAccessoryChecks);
    next.remove(dressId);
    state = state.copyWith(dressAccessoryChecks: next);
    AppLog.i('clearDressAccessoryChecks dress=$dressId', tag: _tag);
    _scheduleSync();
  }

  static Map<String, Set<String>> _copyChecks(
    Map<String, Set<String>> source,
  ) {
    return <String, Set<String>>{
      for (final entry in source.entries)
        entry.key: Set<String>.from(entry.value),
    };
  }

  /// Awaits a Firestore write immediately. Used at the end of the
  /// Configuration wizard so we know the profile is durable before
  /// flipping `profileComplete`.
  /// Flushes the debounced write immediately and reports whether it
  /// actually succeeded — unlike the fire-and-forget debounced path,
  /// `ConfigScreen`'s completion step needs to know this landed before
  /// it can safely mark onboarding complete and navigate away. See
  /// `ChangeRequest/2026-08-11_config-profile-save-failure-fix.md`.
  Future<bool> persist() async {
    _debounce?.cancel();
    return _writeNow();
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(_kSyncDebounce, () {
      // ignore: discarded_futures
      _writeNow();
    });
  }

  Future<bool> _writeNow() async {
    final session = ref.read(authSessionProvider);
    if (session == null) {
      AppLog.i(
        'write SKIPPED — authSessionProvider is null '
        '(kickoffAuthFlow not yet complete)',
        tag: _tag,
      );
      return false;
    }
    AppLog.d(
      'write START — uid=${session.uid}  '
      'branch=${state.branch.name}  rank=${state.rank.name}  '
      'gender=${state.gender.name}  isSikh=${state.isSikh}  '
      'fullName.len=${state.fullName.length}  '
      'vocation=${state.vocation}  '
      'medalRows=${state.medalRowCount}  '
      'badges=${(state.selectedBadgeIds.toList()..sort()).join(",")}',
      tag: _tag,
    );
    try {
      final repo = ref.read(_profileRepositoryProvider);
      await repo.upsert(state);
      AppLog.i(
        'write OK — users/${session.uid}/profile/current updated',
        tag: _tag,
      );
      return true;
    } catch (e, st) {
      AppLog.e(
        'write FAILED — users/${session.uid}/profile/current',
        tag: _tag,
        error: e,
        st: st,
      );
      return false;
    }
  }
}

/// The selected branch, exposed for theme + AR plumbing.
@Riverpod(keepAlive: true)
BranchId currentBranch(Ref ref) {
  return ref.watch(uniformProfileProvider.select((p) => p.branch));
}

@Riverpod(keepAlive: true)
ProfileRepository _profileRepository(Ref ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    throw StateError(
      'profileRepository accessed before authSession is set.',
    );
  }
  return ProfileRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
    userId: session.uid,
  );
}

/// One-shot hydration: when an auth session lands and we don't yet
/// have a profile loaded, fetch the persisted profile and seed
/// [UniformProfileNotifier]. Listened to in `app.dart`.
@Riverpod(keepAlive: true)
Stream<UniformProfile?> hydratedProfile(Ref ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield null;
    return;
  }
  final repo = ref.watch(_profileRepositoryProvider);
  yield* repo.watch();
}
