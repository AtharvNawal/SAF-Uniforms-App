enum BranchId {
  army('army'),
  navy('navy'),
  rsaf('rsaf'),
  dis('dis');

  const BranchId(this.wireName);

  final String wireName;

  static BranchId fromWireName(String value) {
    return BranchId.values.firstWhere(
      (b) => b.wireName == value,
      orElse: () => throw ArgumentError('Unknown BranchId: $value'),
    );
  }
}
