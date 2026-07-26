import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../ar_engine/presentation/providers/accessory_library_provider.dart';
import '../../../profile/domain/entities/accessory.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../../domain/services/dress_accessory_resolver.dart';
import 'dress_requirements_provider.dart';

part 'dress_accessories_provider.g.dart';

/// Selector that the Wardrobe tab uses to scope the accessory list.
/// Implemented as a sealed class with `==` overrides so Riverpod's
/// family-key equality works (so the same filter doesn't recompute).
@immutable
sealed class WardrobeFilter {
  const WardrobeFilter();
}

class AllAccessoriesFilter extends WardrobeFilter {
  const AllAccessoriesFilter();

  @override
  bool operator ==(Object other) => other is AllAccessoriesFilter;

  @override
  int get hashCode => 0;
}

class SingleDressFilter extends WardrobeFilter {
  const SingleDressFilter(this.dressId);
  final String dressId;

  @override
  bool operator ==(Object other) =>
      other is SingleDressFilter && other.dressId == dressId;

  @override
  int get hashCode => dressId.hashCode;
}

/// Maps a [DressCode] to its Firestore `dress_requirements` document id.
/// Mirrors the keys produced by `tool/seed_firestore_main.dart`.
String dressRequirementIdFor(DressCode code) {
  switch (code) {
    case DressCode.no1:
      return 'no_1_dress_requirements';
    case DressCode.no2:
      return 'no_2_dress_requirements';
    case DressCode.no3:
      return 'no_3_dress_requirements';
    case DressCode.no4:
      return 'no_4_dress_requirements';
    case DressCode.no5:
      return 'no_5_dress_requirements';
  }
}

/// The list of accessories the UI should render for the active
/// [UniformProfile]. Pure derivation of:
///
///   `(uniformProfile, dressRequirementForBranch, accessoryLibrary)`
///
/// All three sources are Firestore-backed real-time streams, so any change
/// — locally (user toggles a profile field) or remotely (admin portal
/// edits a doc) — re-emits a fresh list automatically.
///
/// Returns an [AsyncValue] so callers can show loading / error states.
/// Empty list when the dress requirement has no branch override for the
/// user's branch (e.g. No.1/2/4/5 today, where only legacy placeholders
/// exist in the accessory library and they are filtered out by
/// [DressAccessoryResolver]).
@Riverpod(keepAlive: true)
AsyncValue<List<Accessory>> dressAccessories(Ref ref) {
  final profile = ref.watch(uniformProfileProvider);
  final dressId = dressRequirementIdFor(profile.dressCode);

  final asyncRequirement = ref.watch(
    dressRequirementForBranchProvider(dressId, profile.branch),
  );
  final asyncLibrary = ref.watch(accessoryLibraryProvider);

  if (asyncRequirement.isLoading || asyncLibrary.isLoading) {
    return const AsyncValue<List<Accessory>>.loading();
  }
  if (asyncRequirement.hasError) {
    return AsyncValue<List<Accessory>>.error(
      asyncRequirement.error!,
      asyncRequirement.stackTrace ?? StackTrace.current,
    );
  }
  if (asyncLibrary.hasError) {
    return AsyncValue<List<Accessory>>.error(
      asyncLibrary.error!,
      asyncLibrary.stackTrace ?? StackTrace.current,
    );
  }

  final requirement = asyncRequirement.value;
  final library = asyncLibrary.value;
  if (requirement == null || library == null) {
    return const AsyncValue<List<Accessory>>.data(<Accessory>[]);
  }

  final resolved = const DressAccessoryResolver().resolve(
    requirement: requirement,
    profile: profile,
    library: library,
  );
  return AsyncValue<List<Accessory>>.data(resolved);
}

/// Like [dressAccessories] but parameterised by an explicit [dressId]
/// (so the Wardrobe tab can show a checklist for any dress, not only
/// the one the user is currently configured to wear) and split into
/// mandatory + optional so the UI can label rows.
@Riverpod(keepAlive: true)
AsyncValue<AccessorySplit> dressAccessoriesById(Ref ref, String dressId) {
  final profile = ref.watch(uniformProfileProvider);
  final asyncRequirement = ref.watch(
    dressRequirementForBranchProvider(dressId, profile.branch),
  );
  final asyncLibrary = ref.watch(accessoryLibraryProvider);

  if (asyncRequirement.isLoading || asyncLibrary.isLoading) {
    return const AsyncValue<AccessorySplit>.loading();
  }
  if (asyncRequirement.hasError) {
    return AsyncValue<AccessorySplit>.error(
      asyncRequirement.error!,
      asyncRequirement.stackTrace ?? StackTrace.current,
    );
  }
  if (asyncLibrary.hasError) {
    return AsyncValue<AccessorySplit>.error(
      asyncLibrary.error!,
      asyncLibrary.stackTrace ?? StackTrace.current,
    );
  }

  final requirement = asyncRequirement.value;
  final library = asyncLibrary.value;
  if (requirement == null || library == null) {
    return const AsyncValue<AccessorySplit>.data(
      (mandatory: <Accessory>[], optional: <Accessory>[]),
    );
  }

  final split = const DressAccessoryResolver().resolveSplit(
    requirement: requirement,
    profile: profile,
    library: library,
  );
  return AsyncValue<AccessorySplit>.data(split);
}

/// Deduped union of accessories across every dress in
/// `dress_requirements`, applied to the active profile. Powers the
/// "All Accessories" filter in the Wardrobe tab. Order is determined by
/// each dress's resolved order on first encounter, which keeps the UI
/// stable across rebuilds.
@Riverpod(keepAlive: true)
AsyncValue<List<Accessory>> allDressesAccessoriesCombined(Ref ref) {
  final asyncDresses = ref.watch(dressRequirementsAllProvider);
  final profile = ref.watch(uniformProfileProvider);
  final asyncLibrary = ref.watch(accessoryLibraryProvider);

  if (asyncDresses.isLoading || asyncLibrary.isLoading) {
    return const AsyncValue<List<Accessory>>.loading();
  }
  if (asyncDresses.hasError) {
    return AsyncValue<List<Accessory>>.error(
      asyncDresses.error!,
      asyncDresses.stackTrace ?? StackTrace.current,
    );
  }
  if (asyncLibrary.hasError) {
    return AsyncValue<List<Accessory>>.error(
      asyncLibrary.error!,
      asyncLibrary.stackTrace ?? StackTrace.current,
    );
  }

  final dresses = asyncDresses.value ?? const <dynamic>[];
  final library = asyncLibrary.value ?? const <Accessory>[];

  const resolver = DressAccessoryResolver();
  final seen = <String>{};
  final ordered = <Accessory>[];
  for (final dress in dresses) {
    final merged = dress.mergedFor(profile.branch);
    final resolved = resolver.resolve(
      requirement: merged,
      profile: profile,
      library: library,
    );
    for (final a in resolved) {
      if (seen.add(a.id)) ordered.add(a);
    }
  }
  return AsyncValue<List<Accessory>>.data(ordered);
}

/// Maps an accessory id back to every dress (by Firestore doc id) that
/// resolves to it for the active profile. The Wardrobe "All Accessories"
/// view uses this to fan a tick out across every dress that lists it,
/// so the verified count stays coherent regardless of which view the
/// user toggles from.
@Riverpod(keepAlive: true)
AsyncValue<Map<String, Set<String>>> accessoryDressIndex(Ref ref) {
  final asyncDresses = ref.watch(dressRequirementsAllProvider);
  final profile = ref.watch(uniformProfileProvider);
  final asyncLibrary = ref.watch(accessoryLibraryProvider);

  if (asyncDresses.isLoading || asyncLibrary.isLoading) {
    return const AsyncValue<Map<String, Set<String>>>.loading();
  }
  if (asyncDresses.hasError) {
    return AsyncValue<Map<String, Set<String>>>.error(
      asyncDresses.error!,
      asyncDresses.stackTrace ?? StackTrace.current,
    );
  }
  if (asyncLibrary.hasError) {
    return AsyncValue<Map<String, Set<String>>>.error(
      asyncLibrary.error!,
      asyncLibrary.stackTrace ?? StackTrace.current,
    );
  }

  final dresses = asyncDresses.value ?? const <dynamic>[];
  final library = asyncLibrary.value ?? const <Accessory>[];

  const resolver = DressAccessoryResolver();
  final index = <String, Set<String>>{};
  for (final dress in dresses) {
    final merged = dress.mergedFor(profile.branch);
    final resolved = resolver.resolve(
      requirement: merged,
      profile: profile,
      library: library,
    );
    for (final a in resolved) {
      (index[a.id] ??= <String>{}).add(merged.id as String);
    }
  }
  return AsyncValue<Map<String, Set<String>>>.data(index);
}

/// `(checked, total)` count for the Wardrobe verified card, scoped to
/// the active filter. For [SingleDressFilter] it counts only checks on
/// that dress; for [AllAccessoriesFilter] an accessory counts as
/// verified if at least one dress that lists it is checked.
@Riverpod(keepAlive: true)
({int checked, int total}) wardrobeProgress(
  Ref ref,
  WardrobeFilter filter,
) {
  final profile = ref.watch(uniformProfileProvider);
  switch (filter) {
    case SingleDressFilter(:final dressId):
      final asyncSplit = ref.watch(dressAccessoriesByIdProvider(dressId));
      final split = asyncSplit.value;
      if (split == null) return (checked: 0, total: 0);
      final all = [...split.mandatory, ...split.optional];
      final dressChecks =
          profile.dressAccessoryChecks[dressId] ?? const <String>{};
      final checked =
          all.where((a) => dressChecks.contains(a.id)).length;
      return (checked: checked, total: all.length);
    case AllAccessoriesFilter():
      final asyncCombined =
          ref.watch(allDressesAccessoriesCombinedProvider);
      final asyncIndex = ref.watch(accessoryDressIndexProvider);
      final combined = asyncCombined.value;
      final index = asyncIndex.value;
      if (combined == null || index == null) {
        return (checked: 0, total: 0);
      }
      final checks = profile.dressAccessoryChecks;
      final checkedCount = combined.where((a) {
        final dressIds = index[a.id] ?? const <String>{};
        for (final dId in dressIds) {
          if ((checks[dId] ?? const <String>{}).contains(a.id)) return true;
        }
        return false;
      }).length;
      return (checked: checkedCount, total: combined.length);
  }
}
