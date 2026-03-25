import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/models/user_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class LogController {
  final UserModel currentUser;

  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  StreamSubscription? _connectivitySubscription;

  String get _boxKey => 'offline_logs_${currentUser.id}';

  List<LogModel> get filteredLogs {
    if (searchQuery.value.isEmpty) return logsNotifier.value;
    return logsNotifier.value
        .where((log) => log.title
            .toLowerCase()
            .contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  List<LogModel> get logs => logsNotifier.value;

  LogController({required this.currentUser}) {
    _listenConnectivity();
    loadFromDisk();
  }

  void _listenConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((result) {
      final isOffline = result == ConnectivityResult.none;
      print('[CONNECTIVITY] Status: ${isOffline ? "OFFLINE" : "ONLINE"}');

      if (isOffline) {
        // Jangan await di sini — fire and forget
        Future.microtask(() => MongoService().forceDisconnect());
      } else {
        Future.microtask(() => loadFromDisk());
      }
    });
  }

  // Simpan semua log milik user ini ke Hive
  Future<void> _saveToHive(List<LogModel> logs) async {
    try {
      final box = await Hive.openBox('offline_logs');
      final keysToDelete = box.keys.where((k) => k.toString().startsWith(_boxKey));
      await box.deleteAll(keysToDelete);
      final Map<String, Map<String, dynamic>> entries = {
        for (int i = 0; i < logs.length; i++)
          '${_boxKey}_$i': {
            '_id': logs[i].id,
            'title': logs[i].title,
            'description': logs[i].description,
            'date': logs[i].date.toIso8601String(),
            'username': logs[i].username,
            'authorId': logs[i].authorId,
            'teamId': logs[i].teamId,
          }
      };
      await box.putAll(entries);
      await LogHelper.writeLog(
        "HIVE: Disimpan ${logs.length} log untuk ${currentUser.username}",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog("HIVE ERROR: Gagal simpan - $e", level: 1);
    }
  }

  // Baca log milik user ini dari Hive
  Future<List<LogModel>> _readFromHive() async {
    try {
      final box = await Hive.openBox('offline_logs');
      final result = box.keys
          .where((k) => k.toString().startsWith(_boxKey))
          .map((k) {
            final map = Map<String, dynamic>.from(box.get(k));
            return LogModel.fromMap(map);
          })
          .toList();
      return result;
    } catch (e) {
      await LogHelper.writeLog("HIVE READ ERROR: $e", level: 1, source: "log_controller.dart");
      return [];
    }
  }

  Future<void> loadFromDisk() async {
    final localData = await _readFromHive();
    if (localData.isNotEmpty) {
      logsNotifier.value = localData;
      await LogHelper.writeLog(
        "HIVE: Loaded ${localData.length} log (offline cache)",
        source: "log_controller.dart",
      );
    }

    try {
      final cloudData = await MongoService().getLogs(currentUser.username);
      
      if (cloudData.isEmpty && localData.isNotEmpty) {
        await LogHelper.writeLog(
          "CLOUD: Return kosong, tetap pakai cache lokal",
          source: "log_controller.dart",
          level: 1,
        );
        return;
      }

      logsNotifier.value = cloudData;
      await _saveToHive(cloudData);
      await LogHelper.writeLog(
        "CLOUD: Loaded ${cloudData.length} log dari MongoDB",
        source: "log_controller.dart",
      );
    } catch (e) {
      // Tetap pakai data Hive jika cloud gagal
      await LogHelper.writeLog(
        "CLOUD ERROR: Gagal load dari MongoDB, pakai cache lokal - $e",
        level: 1,
        source: "log_controller.dart",
      );
    }
  }

  Future<bool> addLog(String title, String desc) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      date: DateTime.now(),
      username: currentUser.username,
      authorId: currentUser.id,
      teamId: currentUser.teamId,
    );

    // 1. Simpan ke Hive dulu (offline-first)
    final updatedLogs = List<LogModel>.from(logsNotifier.value)..add(newLog);
    logsNotifier.value = updatedLogs;
    await _saveToHive(updatedLogs);

    // 2. Kirim ke MongoDB
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SUCCESS: Tambah '${newLog.title}' ke Cloud",
        source: "log_controller.dart",
      );
      return true;
    } catch (e) {
      // Data tetap tersimpan di Hive meski cloud gagal
      await LogHelper.writeLog(
        "CLOUD ERROR: Gagal kirim Add ke MongoDB - $e (tersimpan lokal)",
        level: 1,
        source: "log_controller.dart",
      );
      return false;
    }
  }

  Future<bool> updateLog(int index, String newTitle, String newDesc) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    if (!AccessControlService.canPerform(
      currentUser.role,
      AccessControlService.actionUpdate,
      isOwner: oldLog.authorId == currentUser.id,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized update attempt",
        level: 1,
      );
      return false;
    }

    final updatedLog = LogModel(
      id: oldLog.id,
      title: newTitle,
      description: newDesc,
      date: DateTime.now(),
      username: currentUser.username,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
    );

    // 1. Update Hive dulu
    currentLogs[index] = updatedLog;
    logsNotifier.value = currentLogs;
    await _saveToHive(currentLogs);

    // 2. Kirim ke MongoDB
    try {
      await MongoService().updateLog(updatedLog);
      await LogHelper.writeLog(
        "SUCCESS: Update '${oldLog.title}' ke Cloud",
        source: "log_controller.dart",
        level: 2,
      );
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "CLOUD ERROR: Gagal Update ke MongoDB - $e (tersimpan lokal)",
        level: 1,
        source: "log_controller.dart",
      );
      return false;
    }
  }

  Future<bool> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    if (!AccessControlService.canPerform(
      currentUser.role,
      AccessControlService.actionDelete,
      isOwner: targetLog.authorId == currentUser.id,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt",
        level: 1,
      );
      return false;
    }

    if (targetLog.id == null) {
      await LogHelper.writeLog("ERROR: ID Log null, tidak bisa hapus", level: 1);
      return false;
    }

    // 1. Hapus dari Hive dulu
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    await _saveToHive(currentLogs);

    // 2. Hapus dari MongoDB
    try {
      await MongoService().deleteLog(targetLog.id!);
      await LogHelper.writeLog(
        "SUCCESS: Hapus '${targetLog.title}' dari Cloud",
        source: "log_controller.dart",
        level: 2,
      );
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "CLOUD ERROR: Gagal Hapus dari MongoDB - $e (terhapus lokal)",
        level: 1,
        source: "log_controller.dart",
      );
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    logsNotifier.dispose();
    searchQuery.dispose();
  }
}