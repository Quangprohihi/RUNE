class Subscription {
  const Subscription({
    required this.plan,
    required this.status,
    this.expiresAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      plan: json['plan'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    );
  }

  factory Subscription.free() {
    return const Subscription(plan: 'free', status: 'active');
  }

  final String plan;
  final String status;
  final DateTime? expiresAt;

  bool get isPremium => plan == 'premium' && status == 'active';
  String get displayName => isPremium ? 'Premium' : 'Free';
}
