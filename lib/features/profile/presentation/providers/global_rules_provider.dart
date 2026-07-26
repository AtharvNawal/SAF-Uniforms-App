import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/global_rules_repository.dart';
import '../../domain/entities/medal_vertical_shift_rule.dart';

part 'global_rules_provider.g.dart';

@Riverpod(keepAlive: true)
GlobalRulesRepository globalRulesRepository(Ref ref) {
  return GlobalRulesRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
Stream<MedalVerticalShiftRule?> medalVerticalShiftRule(Ref ref) {
  return ref.watch(globalRulesRepositoryProvider).watchVerticalShiftRule();
}
