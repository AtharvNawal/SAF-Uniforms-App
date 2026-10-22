import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_scanner/domain/supported_uniforms.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';

void main() {
  test('uniformTypeFor matches the cv-service wire format', () {
    expect(
      uniformTypeFor(BranchId.rsaf, DressCode.no4, Gender.female),
      'rsaf_no4_female',
    );
    expect(
      uniformTypeFor(BranchId.army, DressCode.no3, Gender.male),
      'army_no3_male',
    );
    // Maternity folds to female.
    expect(
      uniformTypeFor(BranchId.rsaf, DressCode.no4, Gender.maternity),
      'rsaf_no4_female',
    );
  });

  test('isCheckableUniform', () {
    expect(
      isCheckableUniform(BranchId.rsaf, DressCode.no4, Gender.female),
      isTrue,
    );
    expect(
      isCheckableUniform(BranchId.rsaf, DressCode.no3, Gender.female),
      isFalse,
    );
    expect(
      isCheckableUniform(BranchId.army, DressCode.no3, Gender.female),
      isFalse,
    );
  });

  test('checkableUniforms lists exactly the supported set', () {
    final types = checkableUniforms()
        .map((u) => uniformTypeFor(u.branch, u.dress, u.gender))
        .toSet();
    expect(types, kCheckableUniformTypes);
  });
}
