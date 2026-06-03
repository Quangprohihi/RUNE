class PetEvolution {
  const PetEvolution({
    required this.code,
    required this.title,
    required this.levelRange,
    required this.unlockLevel,
    required this.assetPath,
    required this.flavor,
  });

  final String code;
  final String title;
  final String levelRange;
  final int unlockLevel;
  final String assetPath;
  final String flavor;

  bool isUnlocked(int petLevel) => petLevel >= unlockLevel;
}

const petEvolutions = [
  PetEvolution(
    code: 'standard',
    title: 'Standard',
    levelRange: 'Lv 1 - Lv 9',
    unlockLevel: 1,
    assetPath: 'assets/images/fox_standard.png',
    flavor: 'Kiki starts the focus journey with you.',
  ),
  PetEvolution(
    code: 'spirit',
    title: 'Spirit Form',
    levelRange: 'Lv 10 - Lv 29',
    unlockLevel: 10,
    assetPath: 'assets/images/fox_spirit.png',
    flavor: '+50 EXP gain preview',
  ),
  PetEvolution(
    code: 'celestial',
    title: 'Celestial Form',
    levelRange: 'Lv 30+',
    unlockLevel: 30,
    assetPath: 'assets/images/fox_celestial.png',
    flavor: '+500 EXP and +1000 tokens preview',
  ),
];

PetEvolution evolutionByCode(String code) {
  return petEvolutions.firstWhere(
    (evolution) => evolution.code == code,
    orElse: () => petEvolutions.first,
  );
}
