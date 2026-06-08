class UserSettings {
  const UserSettings({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.focusReminders,
    required this.silenceNotificationsDuringFocus,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      focusReminders: json['focusReminders'] as bool? ?? true,
      silenceNotificationsDuringFocus:
          json['silenceNotificationsDuringFocus'] as bool? ?? false,
    );
  }

  factory UserSettings.defaults() {
    return const UserSettings(
      soundEnabled: true,
      vibrationEnabled: true,
      focusReminders: true,
      silenceNotificationsDuringFocus: false,
    );
  }

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool focusReminders;
  final bool silenceNotificationsDuringFocus;

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'focusReminders': focusReminders,
      'silenceNotificationsDuringFocus': silenceNotificationsDuringFocus,
    };
  }

  UserSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? focusReminders,
    bool? silenceNotificationsDuringFocus,
  }) {
    return UserSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      focusReminders: focusReminders ?? this.focusReminders,
      silenceNotificationsDuringFocus:
          silenceNotificationsDuringFocus ??
          this.silenceNotificationsDuringFocus,
    );
  }
}
