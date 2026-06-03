class FocusPlan {
  const FocusPlan({
    required this.normalizedLabel,
    required this.subject,
    required this.subjects,
    required this.action,
    required this.topic,
    required this.clarityLevel,
    required this.focusMode,
    required this.recommendedMinutes,
    required this.pomodoroCount,
    required this.advice,
    required this.steps,
    required this.warnings,
    this.isFallback = false,
  });

  factory FocusPlan.fromJson(Map<String, dynamic> json) {
    return FocusPlan(
      normalizedLabel: json['normalizedLabel'] as String? ?? 'Focus',
      subject: json['subject'] as String? ?? 'General',
      subjects: (json['subjects'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      action: json['action'] as String? ?? 'study',
      topic: json['topic'] as String? ?? 'Focus Goal',
      clarityLevel: json['clarityLevel'] as String? ?? 'vague',
      focusMode: json['focusMode'] as String? ?? 'Focused Study',
      recommendedMinutes: json['recommendedMinutes'] as int? ?? 45,
      pomodoroCount: json['pomodoroCount'] as int? ?? 1,
      advice:
          json['advice'] as String? ??
          'Focus on one clear task until the timer ends.',
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  factory FocusPlan.fallback({
    required String goal,
    int selectedMinutes = 45,
    String selectedTask = 'Study',
  }) {
    final label = goal.trim().isEmpty ? selectedTask : goal.trim();
    return FocusPlan(
      normalizedLabel: label,
      subject: 'General',
      subjects: const ['General'],
      action: selectedTask.toLowerCase(),
      topic: 'Focus Goal',
      clarityLevel: label == selectedTask ? 'vague' : 'medium',
      focusMode: selectedTask == 'Break' ? 'Light Focus' : 'Focused Study',
      recommendedMinutes: selectedMinutes,
      pomodoroCount: selectedMinutes <= 25 ? 1 : 2,
      advice: 'Focus on one clear task until the timer ends.',
      steps: const [
        'Pick one target before starting.',
        'Protect the timer from distractions.',
        'Review what to do next before stopping.',
      ],
      warnings: const [],
      isFallback: true,
    );
  }

  final String normalizedLabel;
  final String subject;
  final List<String> subjects;
  final String action;
  final String topic;
  final String clarityLevel;
  final String focusMode;
  final int recommendedMinutes;
  final int pomodoroCount;
  final String advice;
  final List<String> steps;
  final List<String> warnings;
  final bool isFallback;

  String get pomodoroLabel {
    return pomodoroCount <= 1 ? '1 Pomodoro' : '$pomodoroCount Pomodoros';
  }

  String get clarityLabel {
    return switch (clarityLevel) {
      'detailed' => 'Detailed goal',
      'medium' => 'Clear goal',
      _ => 'Broad goal',
    };
  }
}
