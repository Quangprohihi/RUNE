class DailyTaskTemplate {
  const DailyTaskTemplate({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.taskType,
    required this.rewardTokens,
    required this.rewardDiamonds,
    required this.rewardPoints,
  });

  factory DailyTaskTemplate.fromJson(Map<String, dynamic> json) {
    return DailyTaskTemplate(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? 'Task',
      description: json['description'] as String? ?? '',
      taskType: json['taskType'] as String? ?? '',
      rewardTokens: json['rewardTokens'] as int? ?? 0,
      rewardDiamonds: json['rewardDiamonds'] as int? ?? 0,
      rewardPoints: json['rewardPoints'] as int? ?? 0,
    );
  }

  final String id;
  final String code;
  final String title;
  final String description;
  final String taskType;
  final int rewardTokens;
  final int rewardDiamonds;
  final int rewardPoints;
}

class DailyTask {
  const DailyTask({
    required this.id,
    required this.progressValue,
    required this.targetValue,
    required this.status,
    required this.template,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] as String? ?? '',
      progressValue: json['progressValue'] as int? ?? 0,
      targetValue: json['targetValue'] as int? ?? 1,
      status: json['status'] as String? ?? 'active',
      template: DailyTaskTemplate.fromJson(
        json['template'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final String id;
  final int progressValue;
  final int targetValue;
  final String status;
  final DailyTaskTemplate template;

  bool get canClaim => status == 'completed';
  bool get isClaimed => status == 'claimed';
}

class DailyMilestone {
  const DailyMilestone({
    required this.id,
    required this.pointsRequired,
    required this.rewardTokens,
    required this.rewardDiamonds,
  });

  factory DailyMilestone.fromJson(Map<String, dynamic> json) {
    return DailyMilestone(
      id: json['id'] as String? ?? '',
      pointsRequired: json['pointsRequired'] as int? ?? 0,
      rewardTokens: json['rewardTokens'] as int? ?? 0,
      rewardDiamonds: json['rewardDiamonds'] as int? ?? 0,
    );
  }

  final String id;
  final int pointsRequired;
  final int rewardTokens;
  final int rewardDiamonds;
}
