import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Dual-sink structured logger.
///
/// Every call writes to two destinations:
///   1. Dart VM service   → Flutter DevTools → Logging tab.
///   2. [debugPrint]      → `flutter run` terminal output (debug builds only).
///
/// Usage:
///   AppLog.i('auth flow started', tag: 'bootstrap');
///   AppLog.e('write failed', tag: 'auth.repo', error: e, st: st);
///
/// Levels:
///   d → debug  (verbose internals, inputs, branch decisions)
///   i → info   (lifecycle events, successful operations, state changes)
///   w → warn   (unexpected but non-fatal; caught and continuing)
///   e → error  (caught exceptions with full stack trace)
abstract final class AppLog {
  static void d(String msg, {required String tag}) =>
      _emit(msg, tag: tag, marker: 'D', dartLevel: 700);

  static void i(String msg, {required String tag}) =>
      _emit(msg, tag: tag, marker: 'I', dartLevel: 800);

  static void w(
    String msg, {
    required String tag,
    Object? error,
    StackTrace? st,
  }) =>
      _emit(msg, tag: tag, marker: 'W', dartLevel: 900, error: error, st: st);

  static void e(
    String msg, {
    required String tag,
    Object? error,
    StackTrace? st,
  }) =>
      _emit(msg, tag: tag, marker: 'E', dartLevel: 1000, error: error, st: st);

  // -------------------------------------------------------------------------

  static void _emit(
    String msg, {
    required String tag,
    required String marker,
    required int dartLevel,
    Object? error,
    StackTrace? st,
  }) {
    // Sink 1 — Dart VM service (visible in Flutter DevTools Logging tab).
    dev.log(msg, name: tag, error: error, stackTrace: st, level: dartLevel);

    // Sink 2 — terminal (visible in `flutter run` console output).
    if (!kDebugMode) return;
    final buf = StringBuffer()
      ..write('[$marker/$tag] ')
      ..write(msg);
    if (error != null) buf.write('\n    └─ $error');
    debugPrint(buf.toString());
    if (st != null && marker == 'E') {
      debugPrint('    STACKTRACE: $st');
    }
  }
}
