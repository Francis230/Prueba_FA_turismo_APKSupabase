// 2. lib/core/models/user_profile.dart
class UserProfile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final String role;

  UserProfile({required this.id, this.username,this.avatarUrl,required this.role});

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      username: map['username'],
      avatarUrl: map['avatar_url'],
      role: map['role'] ?? 'Visitante',
    );
  }
}
