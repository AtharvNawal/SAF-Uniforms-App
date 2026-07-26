import '../entities/uniform_profile.dart';

abstract class ProfileRepository {
  Future<void> upsert(UniformProfile profile);
  Future<UniformProfile?> fetch();
  Stream<UniformProfile?> watch();
}
