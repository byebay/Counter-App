// lib/models/user_model.dart
class UserModel {
  final String id;
  final String username;
  final String role;
  final String? teamId;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.teamId,
  });
}