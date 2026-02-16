// login_view.dart
import 'package:flutter/material.dart';
// Import Controller milik sendiri (masih satu folder)
import 'package:logbook_app_001/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_app_001/features/logbook/counter_view.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'dart:async';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscure = true; // untuk show/hide password
  int _attempts = 0; // jumlah percobaan salah
  bool _isLocked = false; // tombol login disabled saat lock
  Timer? _lockTimer;
  int _remainingSeconds = 0;

  void _handleLogin() {
    if (_isLocked) return; // safety

    String user = _userController.text.trim();
    String pass = _passController.text;

    // Validasi input kosong
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username dan Password tidak boleh kosong")),
      );
      return;
    }

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      // Reset attempts on success
      _attempts = 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CounterView(username: user),
        ),
      );
    } else {
      _attempts += 1;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Gagal! Periksa username/password")),
      );

      if (_attempts >= 3) {
        // Lock selama 10 detik
        setState(() {
          _isLocked = true;
          _remainingSeconds = 10;
        });
        _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _remainingSeconds -= 1;
            if (_remainingSeconds <= 0) {
              _isLocked = false;
              _attempts = 0;
              timer.cancel();
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passController,
              obscureText: _obscure, // Menyembunyikan teks password
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLocked ? null : _handleLogin,
                child: _isLocked
                    ? Text('Terkunci ($_remainingSeconds)')
                    : const Text('Masuk'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const OnboardingView()),
                    (route) => false,
                  );
                },
                child: const Text('Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
