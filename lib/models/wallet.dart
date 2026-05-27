class Wallet {
  const Wallet({
    required this.tokens,
    required this.energy,
    required this.diamonds,
  });

  factory Wallet.initial() {
    return const Wallet(tokens: 0, energy: 0, diamonds: 0);
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      tokens: json['tokens'] as int? ?? 0,
      energy: json['energy'] as int? ?? 0,
      diamonds: json['diamonds'] as int? ?? 0,
    );
  }

  final int tokens;
  final int energy;
  final int diamonds;
}
