class UserProfile {
  final String id;
  final String name;
  final String email;
  final String username;
  final String bio;
  final String? profileImagePath;
  final String? appLockPin; // Renamed from password for clarity
  final bool isAppLockEnabled;
  final int avatarIndex;
  final int frameIndex;
  final bool isGuest;
  final Map<String, dynamic> stats;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    this.bio = '',
    this.profileImagePath,
    this.appLockPin,
    this.isAppLockEnabled = false,
    this.avatarIndex = 0,
    this.frameIndex = 0,
    this.isGuest = false,
    this.stats = const {},
  });

  // Factory for a guest user
  factory UserProfile.guest() {
    return const UserProfile(
      id: 'guest',
      name: 'Guest',
      email: '',
      isGuest: true,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? username,
    String? bio,
    String? profileImagePath,
    String? appLockPin,
    bool? isAppLockEnabled,
    int? avatarIndex,
    int? frameIndex,
    bool? isGuest,
    Map<String, dynamic>? stats,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      appLockPin: appLockPin ?? this.appLockPin,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      frameIndex: frameIndex ?? this.frameIndex,
      isGuest: isGuest ?? this.isGuest,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'bio': bio,
      'profileImagePath': profileImagePath,
      'appLockPin': appLockPin,
      'isAppLockEnabled': isAppLockEnabled,
      'avatarIndex': avatarIndex,
      'frameIndex': frameIndex,
      'isGuest': isGuest,
      'stats': stats,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 'guest',
      name: json['name'] ?? 'Guest',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      profileImagePath: json['profileImagePath'],
      appLockPin:
          json['appLockPin'], // Load from local or backend if provided (unlikely)
      isAppLockEnabled: json['isAppLockEnabled'] ?? false,
      avatarIndex: json['avatarIndex'] ?? 0,
      frameIndex: json['frameIndex'] ?? 0,
      isGuest: json['isGuest'] ?? false,
      stats: json['stats'] ?? {},
    );
  }
}
