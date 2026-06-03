class AchievementProgress {
  const AchievementProgress({
    required this.code,
    required this.title,
    required this.tier,
    required this.stars,
    required this.maxStars,
    required this.isComplete,
    required this.isClaimed,
    required this.rewardTokens,
    required this.rewardExp,
    required this.tasks,
    this.claimedAt,
  });

  factory AchievementProgress.empty() {
    return const AchievementProgress(
      code: 'productive_partner_i',
      title: 'Most Productive Partner I',
      tier: 1,
      stars: 0,
      maxStars: 5,
      isComplete: false,
      isClaimed: false,
      rewardTokens: 100,
      rewardExp: 100,
      tasks: [],
    );
  }

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      code: json['code'] as String? ?? 'productive_partner_i',
      title: json['title'] as String? ?? 'Most Productive Partner I',
      tier: json['tier'] as int? ?? 1,
      stars: json['stars'] as int? ?? 0,
      maxStars: json['maxStars'] as int? ?? 5,
      isComplete: json['isComplete'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      claimedAt: DateTime.tryParse(json['claimedAt'] as String? ?? ''),
      rewardTokens: json['rewardTokens'] as int? ?? 100,
      rewardExp: json['rewardExp'] as int? ?? 100,
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(AchievementTask.fromJson)
          .toList(),
    );
  }

  final String code;
  final String title;
  final int tier;
  final int stars;
  final int maxStars;
  final bool isComplete;
  final bool isClaimed;
  final DateTime? claimedAt;
  final int rewardTokens;
  final int rewardExp;
  final List<AchievementTask> tasks;

  bool get canClaim => isComplete && !isClaimed;
  double get progress => maxStars == 0 ? 0 : (stars / maxStars).clamp(0, 1);
}

class AchievementTask {
  const AchievementTask({
    required this.code,
    required this.title,
    required this.current,
    required this.target,
    required this.completed,
  });

  factory AchievementTask.fromJson(Map<String, dynamic> json) {
    return AchievementTask(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      current: json['current'] as int? ?? 0,
      target: json['target'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
    );
  }

  final String code;
  final String title;
  final int current;
  final int target;
  final bool completed;
}
