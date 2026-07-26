import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/accessory.dart';
import '../../data/accessory_library_repository.dart';

part 'accessory_library_provider.g.dart';

@Riverpod(keepAlive: true)
AccessoryLibraryRepository accessoryLibraryRepository(Ref ref) {
  return AccessoryLibraryRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
Stream<List<Accessory>> accessoryLibrary(Ref ref) {
  return ref.watch(accessoryLibraryRepositoryProvider).watchAll();
}

@Riverpod(keepAlive: true)
Accessory? accessoryById(Ref ref, String accessoryId) {
  final asyncList = ref.watch(accessoryLibraryProvider);
  return asyncList.maybeWhen(
    data: (list) =>
        list.where((a) => a.id == accessoryId).firstOrNull,
    orElse: () => null,
  );
}
