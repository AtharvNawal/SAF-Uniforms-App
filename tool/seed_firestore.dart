// Operator-only Firestore seed script (pure Dart, no Flutter, no device).
//
// Pushes the bundled `assets/data/*.v1.json` snapshots and the
// `medal_vertical_shift` global rule into the Firestore project that the
// supplied service account JSON is bound to.
//
// Usage:
//   dart run tool/seed_firestore.dart <path/to/service-account.json>
//   dart run tool/seed_firestore.dart <svc-account>.json --upload-images
//   dart run tool/seed_firestore.dart <svc-account>.json --upload-images \
//       --bucket=<custom-bucket-name>
//
// Get the service account JSON from Firebase Console:
//   Project settings → Service accounts → Generate new private key.
// Save it OUTSIDE the repo (or inside, but ensure `.gitignore` covers it —
// the `secrets/` dir is gitignored by default).
//
// Uses Firebase Admin SDK (server-side credentials) which bypasses
// Firestore security rules entirely — no need to relax `firestore.rules`
// for the seed window. Idempotent (`SetOptions.merge()`), safe to re-run.
//
// `--upload-images` (opt-in): walks `assets/accessories/<id>/{image,placement}.png`
// and uploads each PNG to `gs://<bucket>/accessories/<id>/<file>` via the
// Admin SDK's Cloud Storage client. SHA-256 stamped on each object as
// custom metadata; reruns short-circuit when the local file hash matches
// the remote stamp. The Firebase download URL for each upload is patched
// back into `accessory_library.v1.json` (in-memory and on disk) so the
// subsequent Firestore batch carries real `firebasestorage.googleapis.com`
// URLs. See ChangeRequest/2026-05-04_no3-accessory-images.md.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart'
    hide Credential;
import 'package:google_cloud_storage/google_cloud_storage.dart' as gcs;
import 'package:uuid/uuid.dart';

const String _branchConfigsAsset = 'assets/data/branch_configs.v1.json';
const String _dressRequirementsAsset = 'assets/data/dress_requirements.v1.json';
const String _accessoryLibraryAsset = 'assets/data/accessory_library.v1.json';
const String _accessoryImagesDir = 'assets/accessories';

const String _branchConfigsCollection = 'branch_configs';
const String _globalRulesCollection = 'global_logic_rules';
const String _dressRequirementsCollection = 'dress_requirements';
const String _accessoryLibraryCollection = 'accessory_library';

const String _imageFileName = 'image.png';
const String _placementFileName = 'placement.png';

Future<void> main(List<String> args) async {
  final positional = <String>[];
  bool uploadImages = false;
  String? bucketOverride;
  for (final arg in args) {
    if (arg == '--upload-images') {
      uploadImages = true;
    } else if (arg.startsWith('--bucket=')) {
      bucketOverride = arg.substring('--bucket='.length);
    } else if (arg.startsWith('--')) {
      stderr.writeln('Unknown flag: $arg');
      exit(64);
    } else {
      positional.add(arg);
    }
  }

  if (positional.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/seed_firestore.dart '
      '<path/to/service-account.json> [--upload-images] [--bucket=<name>]',
    );
    exit(64);
  }

  final credPath = positional.single;
  final credFile = File(credPath);
  if (!credFile.existsSync()) {
    stderr.writeln('Service account file not found: $credPath');
    exit(66);
  }

  // Pull projectId out of the credential file so we cannot accidentally
  // seed the wrong project.
  final credJson =
      jsonDecode(credFile.readAsStringSync()) as Map<String, dynamic>;
  final projectId = credJson['project_id'] as String?;
  if (projectId == null || projectId.isEmpty) {
    stderr.writeln('Service account file missing "project_id" field');
    exit(66);
  }

  final bucketName = bucketOverride ?? '$projectId.appspot.com';

  stdout.writeln('Seeding Firestore project: $projectId');
  if (uploadImages) {
    stdout.writeln('Image upload target bucket: gs://$bucketName');
  }

  final app = FirebaseApp.initializeApp(
    options: AppOptions(
      credential: Credential.fromServiceAccount(credFile),
      projectId: projectId,
      storageBucket: bucketName,
    ),
  );

  try {
    final firestore = app.firestore();
    await _seedBranchConfigs(firestore);
    await _seedGlobalLogicRules(firestore);
    await _seedDressRequirements(firestore);
    if (uploadImages) {
      await _uploadAccessoryImages(app, bucketName);
    }
    await _seedAccessoryLibrary(firestore);
    stdout.writeln('Seed complete.');
  } catch (e, st) {
    stderr.writeln('Seed failed: $e');
    stderr.writeln(st);
    exit(1);
  }
  exit(0);
}

Future<void> _seedBranchConfigs(Firestore firestore) async {
  stdout.writeln('  branch_configs: starting');
  final json = _readAssetJson(_branchConfigsAsset);
  final version = (json['version'] as num).toInt();
  final branches = json['branches'] as List<dynamic>;

  final batch = firestore.batch();
  for (final dynamic b in branches) {
    final branch = b as Map<String, dynamic>;
    final branchId = branch['branchId'] as String;
    batch.set(
      firestore.collection(_branchConfigsCollection).doc(branchId),
      <String, dynamic>{
        'displayName': branch['displayName'],
        'collarOffsetCm': branch['collarOffsetCm'],
        'ladiesMedalAnchor': branch['ladiesMedalAnchor'],
        'sikhTurbanLogic': branch['sikhTurbanLogic'],
        'dressCodes': branch['dressCodes'],
        'version': version,
        'updatedAt': FieldValue.serverTimestamp,
      },
      options: SetOptions.merge(),
    );
  }
  await batch.commit();
  stdout.writeln('  branch_configs: ok (${branches.length} docs)');
}

Future<void> _seedGlobalLogicRules(Firestore firestore) async {
  stdout.writeln('  global_logic_rules: starting');
  await firestore
      .collection(_globalRulesCollection)
      .doc('medal_vertical_shift')
      .set(
        <String, dynamic>{
          'ruleId': 'medal_vertical_shift',
          'scope': 'global',
          'description':
              'When medal rows >= 3, shift all chest badges downward by '
              'verticalShiftCmPerExtraRow per row beyond minRows.',
          'params': <String, dynamic>{
            'minRows': 3,
            'verticalShiftCmPerExtraRow': 1.0,
          },
          'version': 1,
          'updatedAt': FieldValue.serverTimestamp,
        },
        options: SetOptions.merge(),
      );
  stdout.writeln('  global_logic_rules: ok (1 doc)');
}

Future<void> _seedDressRequirements(Firestore firestore) async {
  stdout.writeln('  dress_requirements: starting');
  final json = _readAssetJson(_dressRequirementsAsset);
  final version = (json['version'] as num).toInt();
  final dressRequirements = json['dressRequirements'] as List<dynamic>;

  final batch = firestore.batch();
  for (final dynamic d in dressRequirements) {
    final doc = Map<String, dynamic>.from(d as Map<dynamic, dynamic>);
    final dressId = doc['id'] as String;
    batch.set(
      firestore.collection(_dressRequirementsCollection).doc(dressId),
      <String, dynamic>{
        ...doc,
        'version': version,
        'updatedAt': FieldValue.serverTimestamp,
      },
    );
  }
  await batch.commit();
  stdout.writeln(
    '  dress_requirements: ok (${dressRequirements.length} docs)',
  );
}

/// Walks `assets/accessories/<id>/{image,placement}.png` and uploads each
/// pair to Firebase Storage. Updates the in-memory + on-disk
/// `accessory_library.v1.json` so the subsequent Firestore batch picks up
/// real download URLs. SHA-256-keyed; reruns are no-ops when nothing changed.
Future<void> _uploadAccessoryImages(FirebaseApp app, String bucketName) async {
  stdout.writeln('  accessory_images: starting');

  final assetFile = File(_accessoryLibraryAsset);
  final assetJson =
      jsonDecode(assetFile.readAsStringSync()) as Map<String, dynamic>;
  final accessories = assetJson['accessories'] as List<dynamic>;

  final storage = app.storage();
  final bucket = storage.bucket(bucketName);

  int uploadedCount = 0;
  int skippedCount = 0;
  int missingCount = 0;
  int patchedEntries = 0;
  int failedCount = 0;

  /// Persist the JSON now so partial progress survives a crash/SIGINT.
  void persistJson() {
    const encoder = JsonEncoder.withIndent('  ');
    assetFile.writeAsStringSync('${encoder.convert(assetJson)}\n');
  }

  for (final dynamic raw in accessories) {
    final entry = raw as Map<String, dynamic>;
    final accessoryId = entry['id'] as String;

    final accessoryDir =
        Directory('$_accessoryImagesDir/$accessoryId');
    if (!accessoryDir.existsSync()) {
      missingCount++;
      continue;
    }

    bool patched = false;
    for (final pair in const [
      [_imageFileName, 'image_url'],
      [_placementFileName, 'placement_diagram'],
    ]) {
      final fileName = pair[0];
      final jsonKey = pair[1];

      final localFile = File('${accessoryDir.path}/$fileName');
      if (!localFile.existsSync()) {
        missingCount++;
        continue;
      }

      final bytes = localFile.readAsBytesSync();
      final localSha = sha256.convert(bytes).toString();
      final objectPath = 'accessories/$accessoryId/$fileName';

      // Wrap the per-file work in try/catch so a transient HTTP / TCP
      // error (e.g. the `HttpException: Unexpected response` Dart's
      // shared HttpClient sometimes hits after many uploads) does not
      // abort the whole pass. Keep going; rerun the script to pick up
      // any failed files via the SHA-256 idempotency short-circuit.
      try {
        final object = bucket.object(objectPath);
        final remoteSha = await _readRemoteSha256(object);
        String? downloadUrl;
        if (remoteSha == localSha) {
          skippedCount++;
          // Even on skip, ensure the JSON has a fresh URL (covers the
          // case where the asset was uploaded earlier but the JSON URL
          // was wiped).
          try {
            downloadUrl = await storage.getDownloadURL(bucket, objectPath);
          } catch (_) {
            downloadUrl = null;
          }
        } else {
          // Tag the object with both the SHA-256 (idempotency) and a
          // Firebase download token (lets `getDownloadURL` mint a
          // usable `firebasestorage.googleapis.com` URL).
          final token = const Uuid().v4();
          await object.upload(
            bytes,
            metadata: gcs.ObjectMetadata(
              contentType: 'image/png',
              cacheControl: 'public, max-age=31536000, immutable',
              metadata: <String, String>{
                'sha256': localSha,
                'firebaseStorageDownloadTokens': token,
              },
            ),
          );
          uploadedCount++;
          downloadUrl = await storage.getDownloadURL(bucket, objectPath);
        }

        if (downloadUrl != null && entry[jsonKey] != downloadUrl) {
          entry[jsonKey] = downloadUrl;
          patched = true;
          persistJson(); // checkpoint after every successful patch
        }
      } catch (e) {
        failedCount++;
        stderr.writeln('    [fail] $objectPath: $e');
      }
    }
    if (patched) patchedEntries++;
  }

  persistJson();

  stdout.writeln(
    '  accessory_images: '
    '${failedCount == 0 ? "ok" : "partial"} '
    '(uploaded $uploadedCount, skipped $skippedCount, '
    'missing $missingCount, failed $failedCount, '
    'json_patched $patchedEntries)',
  );
  if (failedCount > 0) {
    stdout.writeln(
      '  → re-run with --upload-images to retry the $failedCount failed files',
    );
  }
}

/// Returns the `sha256` custom metadata on the remote object, or `null`
/// if the object does not exist or has no such tag. Errors other than
/// "not found" are rethrown.
Future<String?> _readRemoteSha256(gcs.StorageObject object) async {
  try {
    final md = await object.metadata();
    return md.metadata?['sha256'];
  } catch (e) {
    final s = e.toString();
    if (s.contains('NotFoundException') ||
        s.contains('No such object') ||
        s.contains('404')) {
      return null;
    }
    rethrow;
  }
}

Future<void> _seedAccessoryLibrary(Firestore firestore) async {
  stdout.writeln('  accessory_library: starting');
  final json = _readAssetJson(_accessoryLibraryAsset);
  final version = (json['version'] as num).toInt();
  final accessories = json['accessories'] as List<dynamic>;

  // Firestore caps a single batch at 500 ops. The library is ~82 entries
  // today, but split into chunks so a future expansion does not silently
  // hit the cap.
  const int chunkSize = 400;
  for (int start = 0; start < accessories.length; start += chunkSize) {
    final end = (start + chunkSize).clamp(0, accessories.length);
    final batch = firestore.batch();
    for (int i = start; i < end; i++) {
      final doc =
          Map<String, dynamic>.from(accessories[i] as Map<dynamic, dynamic>);
      final accessoryId = doc['id'] as String;
      batch.set(
        firestore.collection(_accessoryLibraryCollection).doc(accessoryId),
        <String, dynamic>{
          ...doc,
          'version': version,
          'updatedAt': FieldValue.serverTimestamp,
        },
        options: SetOptions.merge(),
      );
    }
    await batch.commit();
  }
  stdout.writeln('  accessory_library: ok (${accessories.length} docs)');
}

Map<String, dynamic> _readAssetJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('Asset not found', path);
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}
