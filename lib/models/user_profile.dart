class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.hasLoggedIn,
  });

  factory UserProfile.guest() {
    return const UserProfile(
      id: '',
      displayName: 'Friend',
      email: '',
      hasLoggedIn: false,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Friend',
      email: json['email'] as String? ?? '',
      hasLoggedIn: json['hasLoggedIn'] as bool? ?? false,
    );
  }

  final String id;
  final String displayName;
  final String email;
  final bool hasLoggedIn;

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    bool? hasLoggedIn,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      hasLoggedIn: hasLoggedIn ?? this.hasLoggedIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'hasLoggedIn': hasLoggedIn,
    };
  }
}
