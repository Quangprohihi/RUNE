class AppNotification {
  const AppNotification({
    required this.id,
    required this.notificationType,
    required this.message,
    required this.icon,
    required this.isRead,
    required this.createdAt,
    this.title,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      notificationType: json['notificationType'] as String? ?? '',
      title: json['title'] as String?,
      message: json['message'] as String? ?? '',
      icon: json['icon'] as String? ?? '•',
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String notificationType;
  final String? title;
  final String message;
  final String icon;
  final bool isRead;
  final DateTime createdAt;
}
