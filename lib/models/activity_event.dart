class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.eventType,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.createdAt,
    required this.metadata,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? '•',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  final String id;
  final String eventType;
  final String title;
  final String subtitle;
  final String icon;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
}

class FocusHistorySession {
  const FocusHistorySession({
    required this.id,
    required this.label,
    required this.plannedMinutes,
    required this.startedAt,
    this.completedAt,
  });

  factory FocusHistorySession.fromJson(Map<String, dynamic> json) {
    return FocusHistorySession(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Focus',
      plannedMinutes: json['plannedMinutes'] as int? ?? 0,
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String label;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? completedAt;
}
