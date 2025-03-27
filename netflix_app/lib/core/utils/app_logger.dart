import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static late Directory _logDir;
  static late File _logFile;
  static bool _initialized = false;
  static const int maxLogSize = 5 * 1024 * 1024; // 5MB
  static const int maxLogDays = 7; // Xóa log cũ sau 7 ngày

  /// **Khởi tạo logger cho cả Mobile, Desktop và Web**
  static Future<void> init() async {
    if (kIsWeb) {
      print("Flutter Web: Sử dụng localStorage để lưu log.");
      _initialized = true;
      return;
    }

    if (Platform.isWindows) {
      _logDir = await getApplicationSupportDirectory();
    } else {
      _logDir = await getApplicationDocumentsDirectory();
    }

    await _cleanOldLogs();
    _logFile = _getLogFile();
    _initialized = true;
  }

  /// **Lấy file log theo ngày**
  static File _getLogFile() {
    final String date = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    return File('${_logDir.path}/log_$date.txt');
  }

  /// **Xóa log cũ quá 7 ngày**
  static Future<void> _cleanOldLogs() async {
    if (kIsWeb) return; // Không cần xóa trên Web

    final List<FileSystemEntity> files = _logDir.listSync();
    final DateTime now = DateTime.now();

    for (var file in files) {
      if (file is File && file.path.contains("log_")) {
        final String fileName = file.uri.pathSegments.last;
        final String fileDateStr = fileName.replaceAll(RegExp(r'log_|.txt'), '');
        final DateTime? fileDate = DateTime.tryParse(fileDateStr);

        if (fileDate != null && now.difference(fileDate).inDays > maxLogDays) {
          await file.delete();
        }
      }
    }
  }

  /// **Ghi log vào file hoặc localStorage tùy nền tảng**
  static Future<void> _writeLog(String message) async {
    if (!_initialized) return;

    if (kIsWeb) {
      _writeLogWeb(message);
    } else {
      final ReceivePort receivePort = ReceivePort();
      await Isolate.spawn(_writeLogIsolate, [message, _logFile.path, receivePort.sendPort]);
      await receivePort.first; // Chờ Isolate hoàn tất
    }
  }

  /// **Hàm ghi log chạy trên Isolate (Desktop, Mobile)**
  static void _writeLogIsolate(List<dynamic> args) {
    final String message = args[0];
    final String filePath = args[1];
    final SendPort sendPort = args[2];

    final File file = File(filePath);

    if (file.existsSync() && file.lengthSync() > maxLogSize) {
      file.renameSync('${file.path}.old'); // Đổi tên file cũ
      file.writeAsStringSync(""); // Xóa file hiện tại
    }

    final timestamp = DateTime.now().toIso8601String();
    file.writeAsStringSync('$timestamp - $message\n', mode: FileMode.append);

    sendPort.send(true); // Gửi tín hiệu hoàn tất
  }

  /// **Ghi log vào localStorage trên Web**
  static void _writeLogWeb(String message) {
    final String timestamp = DateTime.now().toIso8601String();
    final String logEntry = '$timestamp - $message';

    List<String> logs = [];
    String? storedLogs = html.window.localStorage['app_logs'];

    if (storedLogs != null) {
      logs = jsonDecode(storedLogs).cast<String>();
    }

    logs.add(logEntry);
    html.window.localStorage['app_logs'] = jsonEncode(logs);
  }

  /// **Tải log xuống file trên Web**
  static void downloadLogs() {
    if (!kIsWeb) return;

    String? storedLogs = html.window.localStorage['app_logs'];
    if (storedLogs == null) return;

    final String content = jsonDecode(storedLogs).join("\n");
    final blob = html.Blob([content], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final html.AnchorElement anchor =
        html.AnchorElement(href: url)
          ..setAttribute("download", "logs.txt")
          ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// **Các hàm ghi log**
  static void debug(dynamic message) {
    _logger.d(message);
    _writeLog("[DEBUG] $message");
  }

  static void info(dynamic message) {
    _logger.i(message);
    _writeLog("[INFO] $message");
  }

  static void warning(dynamic message) {
    _logger.w(message);
    _writeLog("[WARNING] $message");
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _writeLog("[ERROR] $message - ${error.toString()}");
  }

  static void verbose(dynamic message) {
    _logger.v(message);
    _writeLog("[VERBOSE] $message");
  }
}
