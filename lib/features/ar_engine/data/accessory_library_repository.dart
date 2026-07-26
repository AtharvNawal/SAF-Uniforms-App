import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/domain/entities/accessory.dart';
import 'dtos/accessory_firestore.dart';

const String _logName = 'accessory_library.repo';
const String _collection = 'accessory_library';

/// Pure Firestore-backed repository for `accessory_library/{accessoryId}`.
class AccessoryLibraryRepository {
  AccessoryLibraryRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<Accessory>> watchAll() {
    developer.log('watchAll: subscribing', name: _logName);
    return _firestore.collection(_collection).snapshots().map((snap) {
      return snap.docs
          .map((d) => AccessoryFirestore.fromFirestore(
                docId: d.id,
                data: d.data(),
              ))
          .toList(growable: false);
    });
  }

  Future<List<Accessory>> fetchAll() async {
    developer.log('fetchAll: start', name: _logName);
    try {
      final snap = await _firestore.collection(_collection).get();
      final list = snap.docs
          .map((d) => AccessoryFirestore.fromFirestore(
                docId: d.id,
                data: d.data(),
              ))
          .toList(growable: false);
      developer.log('fetchAll: ok (${list.length} docs)', name: _logName);
      return list;
    } catch (e, st) {
      developer.log(
        'fetchAll: failed',
        name: _logName,
        error: e,
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<Accessory?> fetchById(String accessoryId) async {
    developer.log('fetchById: $accessoryId', name: _logName);
    try {
      final snap = await _firestore
          .collection(_collection)
          .doc(accessoryId)
          .get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return AccessoryFirestore.fromFirestore(docId: snap.id, data: data);
    } catch (e, st) {
      developer.log(
        'fetchById: failed for $accessoryId',
        name: _logName,
        error: e,
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }
}
