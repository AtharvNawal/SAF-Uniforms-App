import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/app_logger.dart';
import '../domain/auth_repository.dart';
import '../domain/device_identity.dart';

const String _tag = 'auth.repo';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<AuthSession> signInWithClaim({
    required ClaimResult claim,
    required DeviceIdentity identity,
  }) async {
    AppLog.i(
      'signInWithClaim: START  uid=${claim.uid}  '
      'profileComplete=${claim.profileComplete}',
      tag: _tag,
    );
    try {
      final current = _auth.currentUser;
      AppLog.d(
        'signInWithClaim: currentUser=${current?.uid ?? "<none>"}',
        tag: _tag,
      );

      if (current == null || current.uid != claim.uid) {
        AppLog.i('signInWithClaim: calling signInWithCustomToken...', tag: _tag);
        await _auth.signInWithCustomToken(claim.customToken);
        AppLog.i(
          'signInWithClaim: signInWithCustomToken OK  '
          'uid=${_auth.currentUser?.uid ?? "<null — unexpected>"}',
          tag: _tag,
        );
      } else {
        AppLog.d(
          'signInWithClaim: already signed in as uid=${current.uid} — skipping token exchange',
          tag: _tag,
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw StateError(
          'signInWithCustomToken completed but FirebaseAuth.currentUser is null.',
        );
      }

      // Best-effort: upsert the user doc. A Firestore rules error or network
      // blip here must NOT prevent session establishment — the router needs
      // the session set even if the write fails. The write retries on next launch.
      try {
        AppLog.i(
          'signInWithClaim: upserting users/${user.uid}...',
          tag: _tag,
        );
        await _upsertUserDoc(user.uid, identity);
        AppLog.i(
          'signInWithClaim: users/${user.uid} upsert OK',
          tag: _tag,
        );
      } catch (e, st) {
        AppLog.e(
          'signInWithClaim: users/${user.uid} upsert FAILED (non-fatal — '
          'session will still be established; doc will retry next launch)',
          tag: _tag,
          error: e,
          st: st,
        );
      }

      final session = AuthSession(
        uid: user.uid,
        deviceId: identity.deviceId,
        profileComplete: claim.profileComplete,
      );
      AppLog.i(
        'signInWithClaim: DONE  uid=${session.uid}  '
        'deviceId=${session.deviceId}  profileComplete=${session.profileComplete}',
        tag: _tag,
      );
      return session;
    } catch (e, st) {
      AppLog.e('signInWithClaim: FATAL — cannot establish session', tag: _tag,
          error: e, st: st);
      rethrow;
    }
  }

  Future<void> _upsertUserDoc(String uid, DeviceIdentity identity) async {
    AppLog.d('upsertUserDoc: reading users/$uid...', tag: _tag);
    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();
    AppLog.d(
      'upsertUserDoc: users/$uid exists=${snapshot.exists}',
      tag: _tag,
    );
    final data = <String, Object?>{
      'hardwareId': identity.deviceId,
      'platform': identity.platform,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['previousHardwareIds'] = <String>[];
    } else {
      final prev = (snapshot.data()?['hardwareId'] as String?) ?? '';
      if (prev.isNotEmpty && prev != identity.deviceId) {
        data['previousHardwareIds'] = FieldValue.arrayUnion([prev]);
      }
    }
    AppLog.d(
      'upsertUserDoc: writing users/$uid  fields=${data.keys.join(", ")}',
      tag: _tag,
    );
    await docRef.set(data, SetOptions(merge: true));
    AppLog.i('upsertUserDoc: users/$uid write OK', tag: _tag);
  }

  @override
  AuthSession? currentSession() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthSession(
      uid: user.uid,
      deviceId: '',
      profileComplete: false,
    );
  }

  @override
  Stream<AuthSession?> watchSession() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthSession(
        uid: user.uid,
        deviceId: '',
        profileComplete: false,
      );
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
