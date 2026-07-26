import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/profile/data/branch_config_repository.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';

Map<String, dynamic> _doc({
  required String displayName,
  double collarOffsetCm = 3.0,
  int version = 1,
}) {
  return <String, dynamic>{
    'displayName': displayName,
    'collarOffsetCm': collarOffsetCm,
    'ladiesMedalAnchor': <String, dynamic>{
      'anchor': 'leftLapelCenter',
      'offsetCm': <String, dynamic>{'x': 0.0, 'y': 1.5},
    },
    'sikhTurbanLogic': <String, dynamic>{
      'replacesHeadgear': true,
      'color': 'matchUniform',
      'alignmentOverride': 'turbanCenterline',
    },
    'dressCodes': <String>['No1', 'No2', 'No3', 'No4', 'No5'],
    'version': version,
  };
}

void main() {
  late FakeFirebaseFirestore firestore;
  late BranchConfigRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = BranchConfigRepository(firestore: firestore);
  });

  test('watchAll emits the seeded docs', () async {
    await firestore.collection('branch_configs').doc('army').set(
          _doc(displayName: 'Singapore Army'),
        );
    await firestore.collection('branch_configs').doc('navy').set(
          _doc(displayName: 'Republic of Singapore Navy', collarOffsetCm: 1.0),
        );

    final list = await repo.watchAll().first;
    expect(list, hasLength(2));
    expect(
      list.map((b) => b.branchId).toSet(),
      {BranchId.army, BranchId.navy},
    );
    final navy = list.firstWhere((b) => b.branchId == BranchId.navy);
    expect(navy.collarOffsetCm, 1.0);
  });

  test('watchAll re-emits after a remote update', () async {
    await firestore.collection('branch_configs').doc('army').set(
          _doc(displayName: 'Singapore Army'),
        );

    final stream = repo.watchAll();
    final first = await stream.first;
    expect(
      first.firstWhere((b) => b.branchId == BranchId.army).displayName,
      'Singapore Army',
    );

    await firestore.collection('branch_configs').doc('army').set(
          _doc(displayName: 'Renamed Army', version: 2),
        );

    final second = await stream.first;
    expect(
      second.firstWhere((b) => b.branchId == BranchId.army).displayName,
      'Renamed Army',
    );
  });

  test('fetchAll returns the current snapshot', () async {
    await firestore.collection('branch_configs').doc('rsaf').set(
          _doc(displayName: 'Republic of Singapore Air Force'),
        );

    final list = await repo.fetchAll();
    expect(list, hasLength(1));
    expect(list.first.branchId, BranchId.rsaf);
  });
}
