import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'theme_accent.dart';

const String _logName = 'theme.accent';

/// Persists and exposes the user-selected `ThemeAccent` (FollowBranch / SafCrest).
///
/// Hydration is async (off the build path) so the first frame renders with
/// the default `SafCrest()`. As soon as `LocalStorageService` returns
/// the persisted value, state flips and the theme updates.
class ThemeAccentNotifier extends Notifier<ThemeAccent> {
  /// Set to true the moment a user explicitly calls [set]. Hydration
  /// completed afterwards must not clobber that choice — otherwise an
  /// in-flight `readThemeAccent` racing the user's tap would silently
  /// revert the theme on next frame.
  bool _userOverride = false;

  @override
  ThemeAccent build() {
    // Fire-and-forget hydration — safe because Notifier#build runs once
    // per provider lifetime and `state` setter checks for disposal.
    _hydrate();
    return const SafCrest();
  }

  Future<void> _hydrate() async {
    try {
      final storage = ref.read(localStorageServiceProvider);
      final wire = await storage.readThemeAccent();
      if (_userOverride) {
        // The user already picked something while we were reading the
        // disk — defer to their explicit choice.
        return;
      }
      final hydrated = ThemeAccent.fromWireName(wire);
      if (hydrated.wireName != state.wireName) {
        state = hydrated;
        developer.log('hydrated accent=${hydrated.wireName}',
            name: _logName, level: 800);
      }
    } catch (e, st) {
      developer.log('hydrate failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }

  /// Switch the visual accent. Persists asynchronously; UI updates immediately.
  Future<void> set(ThemeAccent accent) async {
    _userOverride = true;
    state = accent;
    developer.log('set accent=${accent.wireName}',
        name: _logName, level: 800);
    try {
      final storage = ref.read(localStorageServiceProvider);
      await storage.writeThemeAccent(accent.wireName);
    } catch (e, st) {
      developer.log('persist failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }
}

final themeAccentProvider =
    NotifierProvider<ThemeAccentNotifier, ThemeAccent>(ThemeAccentNotifier.new);
