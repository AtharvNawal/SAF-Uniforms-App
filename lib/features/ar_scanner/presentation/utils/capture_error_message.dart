import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../data/cv_service_inspection_repository.dart';
import '../../data/uniform_check_repository.dart';

/// Maps the actual thrown error from a compliance-check call to an
/// accurate (title, subtitle) pair — see
/// `ChangeRequest/2026-08-11_ar-scanner-live-camera-and-error-messaging.md`.
/// Previously every failure showed the same hardcoded "check your
/// connection" text regardless of cause; this distinguishes the
/// genuinely-reachable causes so the message actually matches what
/// happened. Still never shows a raw exception/stack trace to the user.
(String, String) describeCaptureError(Object? error, AppLocalizations l) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'unauthenticated':
        return (l.arErrorSignInTitle, l.arErrorSignInSub);
      case 'not-found':
      case 'failed-precondition':
        return (l.arErrorProfileTitle, l.arErrorProfileSub);
      case 'invalid-argument':
        return (l.arErrorPhotoTitle, l.arErrorPhotoSub);
      case 'deadline-exceeded':
      case 'unavailable':
        return (l.arErrorConnectionTitle, l.arErrorConnectionSub);
      default:
        return (l.arCheckFailed, l.arCheckFailedSub);
    }
  }
  if (error is UniformCheckException) {
    // No HTTP status = the request never got a response, i.e. cv-service
    // isn't reachable (not running / wrong CV_SERVICE_BASE_URL / device
    // can't route to the host). Everything else is the service itself
    // responding with a typed, already-human-readable reason.
    if (error.statusCode == null) {
      return (l.arErrorConnectionTitle, l.arErrorCvUnreachableSub);
    }
    final title = switch (error.errorCode) {
      'NO_PERSON_DETECTED' || 'MULTIPLE_PEOPLE_DETECTED' => l.arErrorPhotoTitle,
      'POSE_UNRELIABLE' || 'SCALE_UNAVAILABLE' => l.arErrorPhotoTitle,
      'IMAGE_CORRUPTED' ||
      'IMAGE_TOO_LARGE' ||
      'IMAGE_TOO_SMALL' ||
      'IMAGE_TOO_DARK' ||
      'IMAGE_TOO_BRIGHT' ||
      'IMAGE_TOO_BLURRY' =>
        l.arErrorPhotoTitle,
      _ => l.arCheckFailed,
    };
    return (title, error.message);
  }
  if (error is CvServiceInspectionException) {
    // No HTTP status at all means the request never got a response —
    // most likely cv-service isn't reachable (e.g. not running
    // locally), a genuinely connection-shaped problem, distinct from
    // the service responding with a real error.
    if (error.statusCode == null) {
      return (l.arErrorConnectionTitle, l.arErrorCvUnreachableSub);
    }
    return (l.arCheckFailed, error.reason);
  }
  if (error is SocketException || error is TimeoutException) {
    return (l.arErrorConnectionTitle, l.arErrorConnectionSub);
  }
  return (l.arCheckFailed, l.arCheckFailedSub);
}
