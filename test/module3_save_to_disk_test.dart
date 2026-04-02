import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/models/user_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('offline_logs')) {
      await Hive.box('offline_logs').close();
    }
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    if (Hive.isBoxOpen('offline_logs')) {
      await Hive.box('offline_logs').close();
    }
    if (await Hive.boxExists('offline_logs')) {
      await Hive.deleteBoxFromDisk('offline_logs');
    }
  });

  test('loadFromDisk membaca cache Hive lokal', () async {
    final user = UserModel(
      id: 'user_1',
      username: 'admin',
      role: 'Ketua',
      teamId: 'team_A',
    );

    final box = await Hive.openBox('offline_logs');
    await box.put('offline_logs_user_1_0', {
      '_id': ObjectId().oid,
      'title': 'Offline Log',
      'description': 'Konten cache',
      'date': DateTime.now().toIso8601String(),
      'username': 'admin',
      'authorId': 'user_1',
      'teamId': 'team_A',
    });
    await box.close();

    final controller = LogController(currentUser: user);
    await controller.loadFromDisk();

    expect(controller.logs, isNotEmpty);
    expect(controller.logs.first.title, 'Offline Log');

    controller.dispose();
  });

  test('addLog menyimpan log baru ke Hive', () async {
    final user = UserModel(
      id: 'user_1',
      username: 'admin',
      role: 'Ketua',
      teamId: 'team_A',
    );

    final controller = LogController(currentUser: user);
    await controller.addLog('Judul Baru', 'Deskripsi baru');

    final box = await Hive.openBox('offline_logs');
    expect(controller.logs.length, 1);
    expect(box.values.length, 1);
    expect(box.keys.first.toString(), contains('offline_logs_user_1_0'));

    await box.close();
    controller.dispose();
  });

  test('updateLog memperbarui entri di Hive', () async {
    final user = UserModel(
      id: 'user_1',
      username: 'admin',
      role: 'Ketua',
      teamId: 'team_A',
    );

    final initialLog = LogModel(
      id: ObjectId().oid,
      title: 'Judul Lama',
      description: 'Deskripsi lama',
      date: DateTime.now(),
      username: 'admin',
      authorId: 'user_1',
      teamId: 'team_A',
    );

    final box = await Hive.openBox('offline_logs');
    await box.put('offline_logs_user_1_0', {
      '_id': initialLog.id,
      'title': initialLog.title,
      'description': initialLog.description,
      'date': initialLog.date.toIso8601String(),
      'username': initialLog.username,
      'authorId': initialLog.authorId,
      'teamId': initialLog.teamId,
    });
    await box.close();

    final controller = LogController(currentUser: user);
    await controller.loadFromDisk();
    await controller.updateLog(0, 'Judul Diubah', 'Deskripsi diperbarui');

    final reopenedBox = await Hive.openBox('offline_logs');
    final values = reopenedBox.values.cast<Map>().toList();

    expect(controller.logs.first.title, 'Judul Diubah');
    expect(values.first['title'], 'Judul Diubah');

    await reopenedBox.close();
    controller.dispose();
  });

  test('removeLog menghapus entri dari Hive', () async {
    final user = UserModel(
      id: 'user_1',
      username: 'admin',
      role: 'Ketua',
      teamId: 'team_A',
    );

    final initialLog = LogModel(
      id: ObjectId().oid,
      title: 'Judul Hapus',
      description: 'Deskripsi hapus',
      date: DateTime.now(),
      username: 'admin',
      authorId: 'user_1',
      teamId: 'team_A',
    );

    final box = await Hive.openBox('offline_logs');
    await box.put('offline_logs_user_1_0', {
      '_id': initialLog.id,
      'title': initialLog.title,
      'description': initialLog.description,
      'date': initialLog.date.toIso8601String(),
      'username': initialLog.username,
      'authorId': initialLog.authorId,
      'teamId': initialLog.teamId,
    });
    await box.close();

    final controller = LogController(currentUser: user);
    await controller.loadFromDisk();
    await controller.removeLog(0);

    final reopenedBox = await Hive.openBox('offline_logs');
    expect(controller.logs, isEmpty);
    expect(reopenedBox.values, isEmpty);

    await reopenedBox.close();
    controller.dispose();
  });
}
