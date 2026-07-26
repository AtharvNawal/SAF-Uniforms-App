enum Gender {
  male('male'),
  female('female'),
  maternity('maternity');

  const Gender(this.wireName);

  final String wireName;

  static Gender fromWireName(String value) {
    return Gender.values.firstWhere(
      (g) => g.wireName == value,
      orElse: () => throw ArgumentError('Unknown Gender: $value'),
    );
  }
}
