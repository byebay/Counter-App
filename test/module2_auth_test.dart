import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';

void main() {
  late LoginController controller;

  setUp(() {
    controller = LoginController();
  });

  test('username benar', () {
    final user = controller.login('admin', 'admin123');

    expect(user, isNotNull);
    expect(user!.username, 'admin');
    expect(controller.currentUser, isNotNull);
  });

  test('username salah', () {
    final user = controller.login('invalid', 'admin123');

    expect(user, isNull);
    expect(controller.currentUser, isNull);
  });

  test('username kosong', () {
    final user = controller.login('', 'admin123');

    expect(user, isNull);
    expect(controller.currentUser, isNull);
  });
}
