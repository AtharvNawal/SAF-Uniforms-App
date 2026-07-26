import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/branch_config_repository.dart';
import '../../domain/entities/branch_config.dart';
import '../../domain/entities/branch_id.dart';

part 'branch_config_provider.g.dart';

@Riverpod(keepAlive: true)
BranchConfigRepository branchConfigRepository(Ref ref) {
  return BranchConfigRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
Stream<List<BranchConfig>> branchConfigs(Ref ref) {
  return ref.watch(branchConfigRepositoryProvider).watchAll();
}

@Riverpod(keepAlive: true)
BranchConfig? branchConfigFor(Ref ref, BranchId branch) {
  final asyncList = ref.watch(branchConfigsProvider);
  return asyncList.maybeWhen(
    data: (configs) =>
        configs.where((c) => c.branchId == branch).firstOrNull,
    orElse: () => null,
  );
}
