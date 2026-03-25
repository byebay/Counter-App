import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class MongoService {
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;

  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  // Ganti checkConnectivity() dengan cek socket langsung
  Future<bool> _isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('[MONGO] Internet check failed: $e');
      return false;
    }
  }

  Future<DbCollection> _getSafeCollection() async {
    final isOnline = await _isInternetAvailable();
    print('[MONGO] Status internet: ${isOnline ? "ONLINE" : "OFFLINE"}');

    if (!isOnline) {
      throw Exception("Tidak ada koneksi internet");
    }

    if (_db == null || !_db!.isConnected || _collection == null) {
      await connect();
    }
    return _collection!;
  }

  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) throw Exception("MONGODB_URI tidak ditemukan di .env");

      _db = await Db.create(dbUri);
      await _db!.open().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception(
            "Koneksi Timeout. Cek IP Whitelist (0.0.0.0/0) atau Sinyal HP.",
          );
        },
      );

      _collection = _db!.collection('logs');
      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// READ
  Future<List<LogModel>> getLogs(String username) async {
    try {
      final collection = await _getSafeCollection();
      final data = await collection.find(where.eq('username', username)).toList();
      await LogHelper.writeLog(
        "DATABASE: Loaded ${data.length} log",
        source: _source,
        level: 2,
      );
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  /// CREATE
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());
      await LogHelper.writeLog(
        "SUCCESS: Insert '${log.title}'",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// UPDATE
  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      if (log.objectId == null) {
        throw Exception("ID Log tidak ditemukan untuk update");
      }
      await collection.replaceOne(where.id(log.objectId!), log.toMap());
      await LogHelper.writeLog(
        "SUCCESS: Update '${log.title}'",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteLog(String id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(ObjectId.parse(id)));
      await LogHelper.writeLog(
        "SUCCESS: Delete ID $id",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Delete Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }

  Future<void> forceDisconnect() async {
    _db = null;
    _collection = null;
    print('[MONGO] State di-reset paksa (tanpa await close)');
  }
}