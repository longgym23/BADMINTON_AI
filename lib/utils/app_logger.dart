// ============================================================
// AppLogger — Centralized logger cho KLOO App
// Thay thế toàn bộ print() bằng structured logging
// - DEBUG: Chỉ hiện trong kDebugMode
// - INFO : Thông tin vận hành bình thường
// - WARN : Cảnh báo (không crash nhưng cần chú ý)
// - ERROR: Lỗi nghiêm trọng + stacktrace
// ============================================================
import 'package:flutter/foundation.dart';

enum _Level { debug, info, warn, error }

class AppLogger {
  AppLogger._();

  // Emoji prefix giúp dễ nhận biết trong console
  static const _prefix = {
    _Level.debug: '🔵 [DEBUG]',
    _Level.info:  '✅ [INFO] ',
    _Level.warn:  '⚠️  [WARN] ',
    _Level.error: '🔴 [ERROR]',
  };

  static void _log(_Level level, String tag, String message, [Object? error, StackTrace? stack]) {
    // DEBUG chỉ in trong debug mode
    if (level == _Level.debug && !kDebugMode) return;

    final time = DateTime.now().toIso8601String().substring(11, 23); // HH:mm:ss.mmm
    final prefix = _prefix[level]!;
    debugPrint('$prefix [$time] [$tag] $message');
    if (error != null)  debugPrint('           ↳ Error: $error');
    if (stack != null)  debugPrint('           ↳ Stack: ${stack.toString().split('\n').take(5).join('\n             ')}');
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Dùng để debug trong development — không hiện ở release build
  static void d(String tag, String message) =>
      _log(_Level.debug, tag, message);

  /// Thông tin vận hành bình thường (token saved, screen loaded,...)
  static void i(String tag, String message) =>
      _log(_Level.info, tag, message);

  /// Cảnh báo — không crash nhưng cần xem xét
  static void w(String tag, String message, [Object? error]) =>
      _log(_Level.warn, tag, message, error);

  /// Lỗi nghiêm trọng — kèm stacktrace để debug nhanh
  static void e(String tag, String message, [Object? error, StackTrace? stack]) =>
      _log(_Level.error, tag, message, error, stack);
}
