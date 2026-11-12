/// User profile model representing pseudonymous identity and platform roles.
/// Ref: docs/DATABASE_AND_API.md
class UserProfileModel {
  final String id;
  final String penName;
  final String? bio;
  final String? avatarUrl;
  final String role; // 'user' | 'admin' | 'curator'
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.id,
    required this.penName,
    this.bio,
    this.avatarUrl,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper to determine if the profile holds curator / admin privileges
  bool get isAdmin => role == 'admin' || role == 'curator';

  /// Helper to determine if the profile is platform super-admin
  bool get isSuperAdmin => role == 'admin';

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      penName: map['pen_name'] as String? ?? 'Anonymous Writer',
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String? ?? 'user',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pen_name': penName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'role': role,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? penName,
    String? bio,
    String? avatarUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      penName: penName ?? this.penName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
