import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/medal_vertical_shift_rule.dart';

const String _logName = 'global_rules.repo';
const String _collection = 'global_logic_rules';
const String _verticalShiftRuleId = 'medal_vertical_shift';

/// Pure Firestore-backed repository for `global_logic_rules/{ruleId}`.
class GlobalRulesRepository {
  GlobalRulesRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Streams the typed Vertical Shift rule. Emits `null` until the doc
  /// exists in Firestore (or its cache).
  Stream<MedalVerticalShiftRule?> watchVerticalShiftRule() {
    developer.log('watchVerticalShiftRule: subscribing', name: _logName);
    return _firestore
        .collection(_collection)
        .doc(_verticalShiftRuleId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      try {
        final data = snap.data();
        if (data == null) return null;
        return MedalVerticalShiftRule.fromFirestore(data);
      } catch (e, st) {
        developer.log(
          'watchVerticalShiftRule: parse failed',
          name: _logName,
          error: e,
          stackTrace: st,
          level: 1000,
        );
        return null;
      }
    });
  }
}
