import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider đếm số tin nhắn chưa đọc cho badge trên thanh nav
class UnreadCountProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  String? _userId;
  int _unreadCount = 0;
  StreamSubscription? _subscription;

  /// Phòng chat đang mở — KHÔNG đếm unread cho phòng này
  String? _currentOpenRoomId;

  int get unreadCount => _unreadCount;

  /// Bắt đầu lắng nghe khi user đăng nhập
  void startListening(String userId) {
    _userId = userId;
    _fetchUnreadCount();

    // Realtime: lắng nghe bảng messages cho các phòng của user
    _subscription?.cancel();
    _subscription = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((_) => _fetchUnreadCount());
  }

  /// Dừng lắng nghe khi logout
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    _unreadCount = 0;
    _currentOpenRoomId = null;
    notifyListeners();
  }

  /// Gọi khi mở màn chat — ngừng đếm phòng này ngay lập tức
  void enterRoom(String roomId) {
    _currentOpenRoomId = roomId;
    // Reset badge ngay — không cần đợi DB
    _fetchUnreadCount();
  }

  /// Gọi khi đóng màn chat (dispose)
  void leaveRoom() {
    _currentOpenRoomId = null;
    _fetchUnreadCount();
  }

  /// Đánh dấu đã đọc phòng chat (cập nhật last_read_at)
  Future<void> markRoomAsRead(String roomId) async {
    if (_userId == null) return;
    try {
      // Dùng UTC để tránh lệch múi giờ với Supabase
      final now = DateTime.now().toUtc().toIso8601String();

      // Thử UPDATE trước
      final result = await _client
          .from('chat_room_members')
          .update({'last_read_at': now})
          .eq('room_id', roomId)
          .eq('user_id', _userId!)
          .select();

      // Nếu không có row nào (user chưa có entry), tạo mới
      if ((result as List).isEmpty) {
        await _client.from('chat_room_members').upsert({
          'room_id': roomId,
          'user_id': _userId!,
          'last_read_at': now,
        });
      }

      await _fetchUnreadCount();
    } catch (e) {
      if (kDebugMode) print('Error markRoomAsRead: $e');
    }
  }

  Future<void> _fetchUnreadCount() async {
    if (_userId == null) return;
    try {
      // Lấy tất cả phòng chat của user kèm last_read_at
      final memberships = await _client
          .from('chat_room_members')
          .select('room_id, last_read_at')
          .eq('user_id', _userId!);

      int total = 0;

      for (final m in memberships) {
        final roomId = m['room_id'] as String;

        // Bỏ qua phòng đang mở — user đang đọc rồi
        if (roomId == _currentOpenRoomId) continue;

        final lastReadAt = m['last_read_at'] as String?;

        // Nếu last_read_at == null → user chưa bao giờ mở phòng này
        // → Không đếm tin nhắn cũ, chỉ đếm từ từ khi có tin nhắn mới
        if (lastReadAt == null) {
          // Lấy tin nhắn mới nhất của người khác trong 24h
          final recent = await _client
              .from('messages')
              .select('id')
              .eq('room_id', roomId)
              .neq('sender_id', _userId!)
              .gt('created_at', DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String());
          total += (recent as List).length;
          continue;
        }

        // Đếm tin nhắn mới hơn last_read_at và không phải do mình gửi
        final rows = await _client
            .from('messages')
            .select('id')
            .eq('room_id', roomId)
            .neq('sender_id', _userId!)
            .gt('created_at', lastReadAt);

        total += (rows as List).length;
      }

      if (total != _unreadCount) {
        _unreadCount = total;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error _fetchUnreadCount: $e');
    }
  }
}
