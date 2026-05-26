class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.hasLoggedIn,
  });

  factory UserProfile.guest() {
    return const UserProfile(
      displayName: 'Friend',
      email: '',
      hasLoggedIn: false,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String? ?? 'Friend',
      email: json['email'] as String? ?? '',
      hasLoggedIn: json['hasLoggedIn'] as bool? ?? false,
    );
  }

  final String displayName;
  final String email;
  final bool hasLoggedIn;

  UserProfile copyWith({
    String? displayName,
    String? email,
    bool? hasLoggedIn,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      hasLoggedIn: hasLoggedIn ?? this.hasLoggedIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'hasLoggedIn': hasLoggedIn,
    };
  }
}
