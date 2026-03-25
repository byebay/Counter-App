import 'dart:developer' as dev;
import 'package:intl/intl.dart'; // Tetap kita gunakan untuk presisi waktu
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    try {
      // 1. Filter Konfigurasi (ENV) - safe jika dotenv belum load
      final int configLevel = int.tryParse(dotenv.maybeGet('LOG_LEVEL') ?? '2') ?? 2;
      final String muteList = dotenv.maybeGet('LOG_MUTE') ?? '';
      // ... sisa kode sama
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}
