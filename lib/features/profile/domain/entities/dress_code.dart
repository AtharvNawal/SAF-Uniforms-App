enum DressCode {
  no1('No1'),
  no2('No2'),
  no3('No3'),
  no4('No4'),
  no5('No5');

  const DressCode(this.wireName);

  final String wireName;

  String get requirementDocId => switch (this) {
    DressCode.no1 => 'no_1_dress_requirements',
    DressCode.no2 => 'no_2_dress_requirements',
    DressCode.no3 => 'no_3_dress_requirements',
    DressCode.no4 => 'no_4_dress_requirements',
    DressCode.no5 => 'no_5_dress_requirements',
  };

  static DressCode fromWireName(String value) {
    return DressCode.values.firstWhere(
      (d) => d.wireName == value,
      orElse: () => throw ArgumentError('Unknown DressCode: $value'),
    );
  }
}
