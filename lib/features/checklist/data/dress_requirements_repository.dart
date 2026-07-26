import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/domain/entities/branch_id.dart';
import '../domain/entities/dress_requirement.dart';
import 'dtos/dress_requirement_firestore.dart';

const String _logName = 'dress_requirements.repo';
const String _collection = 'dress_requirements';

/// Pure Firestore-backed repository for `dress_requirements/{dressId}`.
class DressRequirementsRepository {
  DressRequirementsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<DressRequirement>> watchAll() {
    developer.log('watchAll: subscribing', name: _logName);
    return _firestore.collection(_collection).snapshots().map((snap) {
      return snap.docs
          .map((d) => DressRequirementFirestore.fromFirestore(
                docId: d.id,
                data: d.data(),
              ))
          .toList(growable: false);
    });
  }

  Stream<DressRequirement?> watchById(String dressId) {
    developer.log('watchById: $dressId', name: _logName);
    return _firestore
        .collection(_collection)
        .doc(dressId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      try {
        final data = snap.data();
        if (data == null) return null;
        return DressRequirementFirestore.fromFirestore(
          docId: snap.id,
          data: data,
        );
      } catch (e, st) {
        developer.log(
          'watchById: parse failed for $dressId',
          name: _logName,
          error: e,
          stackTrace: st,
          level: 1000,
        );
        return null;
      }
    });
  }

  Future<DressRequirement?> fetchForBranch(
    String dressId,
    BranchId branch,
  ) async {
    developer.log(
      'fetchForBranch: $dressId branch=${branch.wireName}',
      name: _logName,
    );
    try {
      final snap =
          await _firestore.collection(_collection).doc(dressId).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final base = DressRequirementFirestore.fromFirestore(
        docId: snap.id,
        data: data,
      );
      return base.mergedFor(branch);
    } catch (e, st) {
      developer.log(
        'fetchForBranch: failed for $dressId',
        name: _logName,
        error: e,
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }
}
