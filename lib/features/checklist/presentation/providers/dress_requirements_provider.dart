import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/branch_id.dart';
import '../../data/dress_requirements_repository.dart';
import '../../domain/entities/dress_requirement.dart';

part 'dress_requirements_provider.g.dart';

@Riverpod(keepAlive: true)
DressRequirementsRepository dressRequirementsRepository(Ref ref) {
  return DressRequirementsRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
Stream<DressRequirement?> dressRequirementById(Ref ref, String dressId) {
  return ref.watch(dressRequirementsRepositoryProvider).watchById(dressId);
}

/// Branch-resolved dress requirement: applies any matching `branch_overrides`
/// over the base entry. Falls back to the base when no override is present.
@Riverpod(keepAlive: true)
Stream<DressRequirement?> dressRequirementForBranch(
  Ref ref,
  String dressId,
  BranchId branch,
) {
  return ref
      .watch(dressRequirementsRepositoryProvider)
      .watchById(dressId)
      .map((req) => req?.mergedFor(branch));
}

/// Streams every document in `dress_requirements`. Drives the dynamic
/// Dashboard Home grid, which renders one tile per doc.
@Riverpod(keepAlive: true)
Stream<List<DressRequirement>> dressRequirementsAll(Ref ref) {
  return ref.watch(dressRequirementsRepositoryProvider).watchAll();
}
