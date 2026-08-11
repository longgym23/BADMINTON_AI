import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service quản lý trạng thái online/offline của user (Presence System)
/// Tự động cập nhật status khi app vào foreground/background
class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  String? _userId;
  Timer? _heartbeatTimer;

  /// Khởi động presence tracking cho user đã đăng nhập
  void start(String userId) {
    _userId = userId;
    WidgetsBinding.instance.addObserver(this);
    _setStatus('online');
    // Heartbeat mỗi 30 giây để giữ trạng thái online
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _setStatus('online');
    });
  }

  /// Dừng presence tracking (khi logout)
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    await _setStatus('offline');
    _userId = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setStatus('online');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        _setStatus('offline');
        break;
      default:
        break;
    }
  }

  Future<void> _setStatus(String status) async {
    if (_userId == null) return;
    try {
      await _client.from('profiles').update({
        'status': status,
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', _userId!);
    } catch (e) {
      // Bỏ qua lỗi presence — không critical
    }
  }
}
