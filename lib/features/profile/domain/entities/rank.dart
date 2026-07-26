enum Rank {
  // Enlisted
  rec('REC'),
  pte('PTE'),
  lcp('LCP'),
  cpl('CPL'),
  cfc('CFC'),
  // Specialists
  threeSg('3SG'),
  twoSg('2SG'),
  oneSg('1SG'),
  ssg('SSG'),
  msg('MSG'),
  // Warrant Officers
  threeWo('3WO'),
  twoWo('2WO'),
  oneWo('1WO'),
  mwo('MWO'),
  swo('SWO'),
  cwo('CWO'),
  // Officers
  oct('OCT'),
  twoLt('2LT'),
  lta('LTA'),
  cpt('CPT'),
  maj('MAJ'),
  ltc('LTC'),
  sltc('SLTC'),
  col('COL'),
  bg('BG'),
  mg('MG'),
  ltg('LG');

  const Rank(this.code);

  final String code;
}
