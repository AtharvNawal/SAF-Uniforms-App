import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/checklist/data/dress_requirements_repository.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';

Map<String, dynamic> _doc({
  required String dressName,
  List<Map<String, dynamic>> mandatoryRules = const [],
  Map<String, dynamic>? optionalLogic,
  Map<String, Map<String, dynamic>>? branchOverrides,
  int version = 1,
}) {
  return <String, dynamic>{
    'dress_name': dressName,
    'mandatory_rules': mandatoryRules,
    'optional_logic': optionalLogic ?? <String, dynamic>{},
    'branch_overrides': branchOverrides ?? <String, dynamic>{},
    'version': version,
  };
}

void main() {
  late FakeFirebaseFirestore firestore;
  late DressRequirementsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = DressRequirementsRepository(firestore: firestore);
  });

  test('watchById emits the seeded doc', () async {
    await firestore
        .collection('dress_requirements')
        .doc('no_3_dress_requirements')
        .set(_doc(
          dressName: 'No. 3 Dress',
          mandatoryRules: [
            {'category': 'headdress', 'rule': 'standard'},
          ],
        ));

    final req = await repo.watchById('no_3_dress_requirements').first;
    expect(req, isNotNull);
    expect(req!.id, 'no_3_dress_requirements');
    expect(req.dressName, 'No. 3 Dress');
    expect(req.mandatoryRules, hasLength(1));
  });

  test('watchById emits null when the doc is missing', () async {
    final req = await repo.watchById('does_not_exist').first;
    expect(req, isNull);
  });

  test('fetchForBranch applies the matching branch override', () async {
    await firestore
        .collection('dress_requirements')
        .doc('no_3_dress_requirements')
        .set(_doc(
          dressName: 'No. 3 Dress',
          mandatoryRules: [
            {'category': 'headdress', 'rule': 'base'},
          ],
          branchOverrides: <String, Map<String, dynamic>>{
            'navy': <String, dynamic>{
              'mandatory_rules': [
                {'category': 'headdress', 'rule': 'navy-specific'},
              ],
            },
          },
        ));

    final navy = await repo.fetchForBranch(
      'no_3_dress_requirements',
      BranchId.navy,
    );
    expect(navy, isNotNull);
    expect(navy!.mandatoryRules.first['rule'], 'navy-specific');

    final army = await repo.fetchForBranch(
      'no_3_dress_requirements',
      BranchId.army,
    );
    expect(army!.mandatoryRules.first['rule'], 'base');
  });
}
