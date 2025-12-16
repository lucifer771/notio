class UserProfile {
  final String id;
  final String name;
  final String email;
  final int avatarIndex; // 0-11 for different characters
  final int frameIndex; // 0: None, 1: Neon, 2: Gold, 3: Cyberpunk, etc.
  final bool isGuest;
  final Map<String, dynamic> stats; // For productivity score etc.

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
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
    int? avatarIndex,
    int? frameIndex,
    bool? isGuest,
    Map<String, dynamic>? stats,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
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
      avatarIndex: json['avatarIndex'] ?? 0,
      frameIndex: json['frameIndex'] ?? 0,
      isGuest: json['isGuest'] ?? false,
      stats: json['stats'] ?? {},
    );
  }
}
