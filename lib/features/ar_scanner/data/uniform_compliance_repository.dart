// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:cloud_functions/cloud_functions.dart';

// import '../../../core/utils/app_logger.dart';
// import '../../profile/domain/entities/dress_code.dart';
// import '../domain/entities/compliance_result.dart';

// const String _tag = 'arScanner.compliance';

// /// Client-side wrapper around the `checkUniformCompliance` HTTPS
// /// callable defined in `functions/src/checkUniformCompliance.ts`. The
// /// Cloud Function is the single source of truth for what "correct"
// /// means (it resolves the same expected-accessory list
// /// `composeUniformModel` uses); this wrapper just base64-encodes the
// /// photo, forwards the request, and maps the response onto
// /// [ComplianceResult]. Nothing is cached or persisted client-side —
// /// each call is a fresh, ephemeral check.

// class UniformComplianceRepository {
//   UniformComplianceRepository({required FirebaseFunctions functions})
//       : _functions = functions;

//   final FirebaseFunctions _functions;

//   Future<ComplianceResult> check({
//     required DressCode dressCode,
//     required Uint8List photoBytes,
//     String mimeType = 'image/jpeg',
//   }) async {
//     AppLog.i(

//       'check: calling checkUniformCompliance  '
//       'dress=${dressCode.wireName}  bytes=${photoBytes.length}',
//       tag: _tag,
//     );
    
//     try {
//       final callable = _functions.httpsCallable(
//         'checkUniformCompliance',
//         options: HttpsCallableOptions(
//           timeout: const Duration(seconds: 60),
//         ),
//       );
//       final result = await callable.call(<String, dynamic>{
//         'dressCode': dressCode.wireName,
//         'photoBase64': base64Encode(photoBytes),
//         'mimeType': mimeType,
//       });
//       final data = Map<String, dynamic>.from(result.data as Map);
//       final items = (data['items'] as List<dynamic>? ?? [])
//           .map((raw) {
//             final m = Map<String, dynamic>.from(raw as Map);
//             return ComplianceItem(
//               accessoryId: m['accessoryId'] as String,
//               displayName: m['displayName'] as String,
//               status: ComplianceStatus.fromWireName(m['status'] as String),
//               note: m['note'] as String,
//             );
//           })
//           .toList(growable: false);
//       final parsed = ComplianceResult(
//         overallScore: (data['overallScore'] as num).toInt(),
//         summary: data['summary'] as String,
//         items: items,
//       );
//       AppLog.i(
//         'check: OK  dress=${dressCode.wireName}  '
//         'score=${parsed.overallScore}  items=${items.length}',
//         tag: _tag,
//       );
//       return parsed;
//     } catch (e, st) {
//       AppLog.e(
//         'check: FAILED  dress=${dressCode.wireName}',
//         tag: _tag,
//         error: e,
//         st: st,
//       );
//       rethrow;
//     }
//   }
// }
