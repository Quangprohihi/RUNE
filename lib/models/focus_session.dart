class FocusSession {
  const FocusSession({
    required this.id,
    required this.label,
    required this.startedAt,
    this.endedAt,
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.completedWorkBlocks = 0,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Focus',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? ''),
      workMinutes: json['workMinutes'] as int? ?? 25,
      breakMinutes: json['breakMinutes'] as int? ?? 5,
      completedWorkBlocks: json['completedWorkBlocks'] as int? ?? 0,
    );
  }

  final String id;
  final String label;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int workMinutes;
  final int breakMinutes;
  final int completedWorkBlocks;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'workMinutes': workMinutes,
      'breakMinutes': breakMinutes,
      'completedWorkBlocks': completedWorkBlocks,
    };
  }
}
