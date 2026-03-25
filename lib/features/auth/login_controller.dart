import 'package:logbook_app_001/features/logbook/models/user_model.dart';

class LoginController {
  final Map<String, Map<String, String>> _users = {
    'admin': {'password': 'admin123', 'role': 'Ketua',   'id': 'user_1', 'teamId': 'team_A'},
    'guest': {'password': 'guest123', 'role': 'Anggota', 'id': 'user_2', 'teamId': 'team_A'},
  };

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  UserModel? login(String username, String password) {
    if (!_users.containsKey(username)) return null;
    final data = _users[username]!;
    if (data['password'] != password) return null;

    _currentUser = UserModel(
      id: data['id']!,
      username: username,
      role: data['role']!,
      teamId: data['teamId'],
    );
    return _currentUser;
  }

  void logout() => _currentUser = null;

  Map<String, Map<String, String>> get users => Map.unmodifiable(_users);
}