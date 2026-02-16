// login_controller.dart
class LoginController {
  // Database sederhana (Hardcoded) untuk multiple users
  // Pastikan ada minimal 2 akun berbeda
  final Map<String, String> _users = {
    'admin': 'admin123',
    'guest': 'guest123',
  };

  // Fungsi pengecekan (Logic-Only)
  // Mengembalikan true jika username ada dan password cocok
  bool login(String username, String password) {
    if (!_users.containsKey(username)) return false;
    return _users[username] == password;
  }

  // Opsional: expose list of users (read-only)
  Map<String, String> get users => Map.unmodifiable(_users);
}
