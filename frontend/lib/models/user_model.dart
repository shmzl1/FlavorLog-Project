class UserModel {
  final int id;
  final String username;
  final String email;
  final String? nickname;
  final String? avatarUrl;
  final String? healthGoal;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.nickname,
    this.avatarUrl,
    this.healthGoal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      healthGoal: json['health_goal'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'health_goal': healthGoal,
    };
  }
}