import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/uniform_profile.dart';
import '../domain/repositories/profile_repository.dart';
import 'dtos/uniform_profile_dto.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  DocumentReference<Map<String, dynamic>> get _profileDoc => _firestore
      .collection('users')
      .doc(_userId)
      .collection('profile')
      .doc('current');

  @override
  Future<void> upsert(UniformProfile profile) async {
    final data = UniformProfileDto.toFirestore(profile);
    if (data.isEmpty) return;
    await _profileDoc.set(data, SetOptions(merge: true));
  }

  @override
  Future<UniformProfile?> fetch() async {
    final snap = await _profileDoc.get();
    final data = snap.data();
    if (data == null) return null;
    return UniformProfileDto.fromFirestore(data);
  }

  @override
  Stream<UniformProfile?> watch() {
    return _profileDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UniformProfileDto.fromFirestore(data);
    });
  }
}
