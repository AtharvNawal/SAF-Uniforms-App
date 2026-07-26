// PLACEHOLDER — REGENERATE BEFORE FIRST RUN.
//
// Do not commit real keys. Run:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// That command overwrites this file with a real `DefaultFirebaseOptions`
// containing the platform-specific API keys, app IDs, and project IDs.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions: web is not supported on this project.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions: ${defaultTargetPlatform.name} is not supported.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDY9S9G9sAqZcBUt7tgMqW22JmZosyKXAk',
    appId: '1:612500938654:ios:db70964b515da4805e408f',
    messagingSenderId: '612500938654',
    projectId: 'saf-uniforms',
    storageBucket: 'saf-uniforms.firebasestorage.app',
    iosBundleId: 'com.saf.safUniforms',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqFkmZeyay3O6YCpkeeSPoRY6PgwRiaug',
    appId: '1:612500938654:android:3908ea89dee96af15e408f',
    messagingSenderId: '612500938654',
    projectId: 'saf-uniforms',
    storageBucket: 'saf-uniforms.firebasestorage.app',
  );

}