import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/app_logger.dart';
import '../../profile/domain/entities/dress_code.dart';

const String _tag = 'ar.modelGen';

/// Result of a successful `composeUniformModel` call. The same fields
/// are also written to `users/{uid}/profile/current.generatedDresses`
/// by the Cloud Function, so the client picks them up via the existing
/// hydrated-profile stream — this return value is mainly for the
/// optimistic UI path.
class ComposedModel {
  const ComposedModel({
    required this.modelUrl,
    required this.profileHash,
    required this.schemaVersion,
  });

  final String modelUrl;
  final String profileHash;
  final int schemaVersion;
}

/// Client-side wrapper around the `composeUniformModel` HTTPS callable
/// defined in `functions/src/composeUniformModel.ts`.
///
/// The CF is the single source of truth for what a generated GLB
/// contains; this wrapper just forwards the request and surfaces
/// errors. The resulting URL also lands in Firestore via the CF, so
/// callers usually just wait for the profile stream to refresh and
/// don't strictly need this return value.
class ModelGenerationRepository {
  ModelGenerationRepository({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  Future<ComposedModel> compose({
    required DressCode dressCode,
    required String profileHash,
  }) async {
    // Diagnostic: confirm Firebase Auth state at the moment of the
    // call. `httpsCallable` attaches the current user's ID token as
    // a Bearer header automatically — if `currentUser` is null here,
    // no token is sent and the function rejects with UNAUTHENTICATED
    // even though our app's own `authSessionProvider` may be set
    // (the cached session is a UI-only optimisation; the real
    // Firebase Auth state lives in FirebaseAuth.instance).
    final currentUser = FirebaseAuth.instance.currentUser;
    String? idTokenPreview;
    bool? tokenStale;
    if (currentUser != null) {
      try {
        final tokenResult = await currentUser.getIdTokenResult(false);
        final tok = tokenResult.token ?? '';
        idTokenPreview = tok.length > 20
            ? '${tok.substring(0, 12)}…${tok.substring(tok.length - 6)} (${tok.length} chars)'
            : tok;
        tokenStale = tokenResult.expirationTime != null &&
            tokenResult.expirationTime!.isBefore(DateTime.now());
      } catch (e) {
        idTokenPreview = '(getIdToken threw: $e)';
      }
    }
    AppLog.i(
      'compose: calling composeUniformModel  '
      'dress=${dressCode.wireName}  hash=$profileHash  '
      'firebaseUser=${currentUser?.uid ?? "(null!)"}  '
      'idToken=$idTokenPreview  '
      'tokenStale=$tokenStale',
      tag: _tag,
    );
    try {
      final callable = _functions.httpsCallable(
        'composeUniformModel',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 90),
        ),
      );
      final result = await callable.call(<String, dynamic>{
        'dressCode': dressCode.wireName,
        'profileHash': profileHash,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final composed = ComposedModel(
        modelUrl: data['modelUrl'] as String,
        profileHash: data['profileHash'] as String,
        schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
      );
      AppLog.i(
        'compose: OK  dress=${dressCode.wireName}  '
        'url=${composed.modelUrl}  hash=${composed.profileHash}',
        tag: _tag,
      );
      return composed;
    } catch (e, st) {
      AppLog.e(
        'compose: FAILED  dress=${dressCode.wireName}',
        tag: _tag,
        error: e,
        st: st,
      );
      rethrow;
    }
  }
}
