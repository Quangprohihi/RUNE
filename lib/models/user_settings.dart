class UserSettings {
  const UserSettings({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.focusReminders,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      focusReminders: json['focusReminders'] as bool? ?? true,
    );
  }

  factory UserSettings.defaults() {
    return const UserSettings(
      soundEnabled: true,
      vibrationEnabled: true,
      focusReminders: true,
    );
  }

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool focusReminders;

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'focusReminders': focusReminders,
    };
  }

  UserSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? focusReminders,
  }) {
    return UserSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      focusReminders: focusReminders ?? this.focusReminders,
    );
  }
}
