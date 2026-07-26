import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/branch_config.dart';
import 'dtos/branch_config_firestore.dart';

const String _logName = 'branch_config.repo';
const String _collection = 'branch_configs';

/// Pure Firestore-backed repository for `branch_configs/{branchId}`. The
/// Firestore SDK's offline cache means the stream serves cached docs while
/// offline, so the app does not need its own local mirror. The doc-level
/// `version` field is preserved on the wire for the admin portal's
/// cache-busting use, but the mobile reads every snapshot regardless.
class BranchConfigRepository {
  BranchConfigRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<BranchConfig>> watchAll() {
    developer.log('watchAll: subscribing', name: _logName);
    return _firestore.collection(_collection).snapshots().map(_mapSnapshot);
  }

  Future<List<BranchConfig>> fetchAll() async {
    developer.log('fetchAll: start', name: _logName);
    try {
      final snap = await _firestore.collection(_collection).get();
      final list = _mapSnapshot(snap);
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

  List<BranchConfig> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return snap.docs
        .map((d) => BranchConfigFirestore.fromFirestore(
              docId: d.id,
              data: d.data(),
            ))
        .toList(growable: false);
  }
}
