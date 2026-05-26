class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.level,
    required this.exp,
    required this.expToNext,
    required this.hunger,
    required this.energy,
    required this.mood,
    required this.love,
    required this.lastUpdatedAt,
  });

  factory Pet.initial() {
    return Pet(
      id: 'kiki',
      name: 'Kiki',
      species: 'Red Fox',
      level: 3,
      exp: 400,
      expToNext: 500,
      hunger: 72,
      energy: 80,
      mood: 76,
      love: 68,
      lastUpdatedAt: DateTime.now(),
    );
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String? ?? 'kiki',
      name: json['name'] as String? ?? 'Kiki',
      species: json['species'] as String? ?? 'Red Fox',
      level: json['level'] as int? ?? 3,
      exp: json['exp'] as int? ?? 400,
      expToNext: json['expToNext'] as int? ?? 500,
      hunger: json['hunger'] as int? ?? 72,
      energy: json['energy'] as int? ?? 80,
      mood: json['mood'] as int? ?? 76,
      love: json['love'] as int? ?? 68,
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String species;
  final int level;
  final int exp;
  final int expToNext;
  final int hunger;
  final int energy;
  final int mood;
  final int love;
  final DateTime lastUpdatedAt;

  String get moodLabel {
    if (mood < 30) return 'Needs care';
    if (mood < 70) return 'Calm';
    return 'Happy';
  }

  double get expProgress => (exp / expToNext).clamp(0, 1).toDouble();

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    int? level,
    int? exp,
    int? expToNext,
    int? hunger,
    int? energy,
    int? mood,
    int? love,
    DateTime? lastUpdatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      expToNext: expToNext ?? this.expToNext,
      hunger: hunger ?? this.hunger,
      energy: energy ?? this.energy,
      mood: mood ?? this.mood,
      love: love ?? this.love,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'level': level,
      'exp': exp,
      'expToNext': expToNext,
      'hunger': hunger,
      'energy': energy,
      'mood': mood,
      'love': love,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }
}
