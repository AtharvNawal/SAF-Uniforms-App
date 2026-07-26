import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/utils/app_logger.dart';
import '../domain/device_identity.dart';

const String _tag = 'auth.registry';

/// Client-side wrapper around the `claimDeviceIdentity` and
/// `markProfileComplete` HTTPS callables defined in `functions/`.
class DeviceRegistryService {
  DeviceRegistryService({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  Future<ClaimResult> claim(DeviceIdentity identity) async {
    AppLog.i(
      'claim: calling claimDeviceIdentity  '
      'deviceId=${identity.deviceId}  platform=${identity.platform}',
      tag: _tag,
    );
    try {
      final callable = _functions.httpsCallable('claimDeviceIdentity');
      AppLog.d('claim: httpsCallable obtained, invoking...', tag: _tag);
      final result = await callable.call(<String, dynamic>{
        'deviceId': identity.deviceId,
        'platform': identity.platform,
      });
      AppLog.d(
        'claim: raw response type=${result.data.runtimeType}  '
        'data=${result.data}',
        tag: _tag,
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      final claim = ClaimResult(
        uid: data['uid'] as String,
        customToken: data['customToken'] as String,
        profileComplete: (data['profileComplete'] as bool?) ?? false,
      );
      AppLog.i(
        'claim: OK  uid=${claim.uid}  profileComplete=${claim.profileComplete}',
        tag: _tag,
      );
      return claim;
    } catch (e, st) {
      AppLog.e(
        'claim: FAILED — claimDeviceIdentity Cloud Function error. '
        'Check that functions are deployed to asia-southeast1.',
        tag: _tag,
        error: e,
        st: st,
      );
      rethrow;
    }
  }

  Future<void> markProfileComplete(String deviceId) async {
    AppLog.i(
      'markProfileComplete: calling Cloud Function  deviceId=$deviceId',
      tag: _tag,
    );
    try {
      final callable = _functions.httpsCallable('markProfileComplete');
      await callable.call(<String, dynamic>{'deviceId': deviceId});
      AppLog.i('markProfileComplete: OK', tag: _tag);
    } catch (e, st) {
      AppLog.e(
        'markProfileComplete: FAILED',
        tag: _tag,
        error: e,
        st: st,
      );
      rethrow;
    }
  }
}
