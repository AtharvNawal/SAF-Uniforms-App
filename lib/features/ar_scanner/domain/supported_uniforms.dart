import '../../profile/domain/entities/branch_id.dart';
import '../../profile/domain/entities/dress_code.dart';
import '../../profile/domain/entities/gender.dart';

/// Uniforms `cv-service` can check today — mirrors `UNIFORMS` in
/// `cv-service/uniforms.py`. Update both together when a uniform is added;
/// the server's `UNSUPPORTED_UNIFORM` 422 stays authoritative if they drift.
const Set<String> kCheckableUniformTypes = {
  'army_no3_male',
  'rsaf_no4_male',
  'rsaf_no4_female',
};

/// Dresses the scanner offers. Doctrine for No.1/2/5 isn't transcribed.
const List<DressCode> kScannableDresses = [DressCode.no3, DressCode.no4];

/// Doctrine only distinguishes male/female — maternity folds to female.
String uniformGenderWireValue(Gender g) => g == Gender.male ? 'male' : 'female';

/// `uniform_type` form field for `POST /check_uniform`, e.g. `rsaf_no4_female`.
String uniformTypeFor(BranchId branch, DressCode dress, Gender gender) =>
    '${branch.wireName}_${dress.wireName.toLowerCase()}_'
    '${uniformGenderWireValue(gender)}';

bool isCheckableUniform(BranchId branch, DressCode dress, Gender gender) =>
    kCheckableUniformTypes.contains(uniformTypeFor(branch, dress, gender));

/// The checkable uniforms as (branch, dress, gender) for user-facing lists.
List<({BranchId branch, DressCode dress, Gender gender})> checkableUniforms() =>
    [
      for (final b in BranchId.values)
        for (final d in kScannableDresses)
          for (final g in const [Gender.male, Gender.female])
            if (isCheckableUniform(b, d, g)) (branch: b, dress: d, gender: g),
    ];
