import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/core/persistence/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageService.lastRoute', () {
    test('readLastRoute returns null when nothing is cached', () async {
      final storage = LocalStorageService();
      expect(await storage.readLastRoute(), isNull);
    });

    test('writeLastRoute then readLastRoute round-trips the value', () async {
      final storage = LocalStorageService();
      await storage.writeLastRoute('/ar');
      expect(await storage.readLastRoute(), '/ar');
    });

    test('writeLastRoute overwrites a previously persisted value', () async {
      final storage = LocalStorageService();
      await storage.writeLastRoute('/ar');
      await storage.writeLastRoute('/dashboard');
      expect(await storage.readLastRoute(), '/dashboard');
    });

    test('clearLastRoute removes the persisted value', () async {
      final storage = LocalStorageService();
      await storage.writeLastRoute('/config');
      await storage.clearLastRoute();
      expect(await storage.readLastRoute(), isNull);
    });

    test('preserves query parameters (needed for routes like dress-accessories)',
        () async {
      final storage = LocalStorageService();
      await storage.writeLastRoute('/dress-accessories?dress=no_1');
      expect(await storage.readLastRoute(), '/dress-accessories?dress=no_1');
    });
  });
}
