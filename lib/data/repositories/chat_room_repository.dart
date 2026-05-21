import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRoom {
  final String id;
  final bool isGroup;
  final String? name; // Tên nhóm (nếu có)
  final String? avatarUrl; // Avatar nhóm (nếu có)
  final DateTime createdAt;

  // Dữ liệu mở rộng để hiển thị UI
  String? displayTitle;
  String? displayAvatar;
  String? lastMessage;
  DateTime? lastMessageTime;
  int unreadCount = 0;
  List<UserModel> members = [];
  String? adminId;

  ChatRoom({
    required this.id,
    required this.isGroup,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    this.adminId,
  });

  factory ChatRoom.fromSupabase(Map<String, dynamic> data) {
    return ChatRoom(
      id: data['id'],
      isGroup: data['is_group'],
      name: data['name'],
      avatarUrl: data['avatar_url'],
      createdAt: DateTime.parse(data['created_at']).toLocal(),
      adminId: data['admin_id'],
    );
  }
}

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String? imagePath;

  // Thông tin thêm
  UserModel? sender;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.imagePath,
  });

  factory Message.fromSupabase(Map<String, dynamic> data) {
    return Message(
      id: data['id'],
      roomId: data['room_id'],
      senderId: data['sender_id'],
      content: data['content'],
      createdAt: DateTime.parse(data['created_at']).toLocal(),
      imagePath: data['image_path'],
    );
  }
}

class ChatRoomRepository {
  final SupabaseClient _client;

  ChatRoomRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Lấy danh sách phòng chat của 1 User
  Stream<List<ChatRoom>> getUserRoomsStream(String userId) {
    return _client
        .from('chat_room_members')
        .stream(primaryKey: ['room_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((memberships) async {
          List<ChatRoom> rooms = [];

          for (var membership in memberships) {
            String roomId = membership['room_id'];

            try {
              // Lấy thông tin phòng
              final roomData = await _client
                  .from('chat_rooms')
                  .select()
                  .eq('id', roomId)
                  .single();
              final room = ChatRoom.fromSupabase(roomData);

              // Lấy tất cả thành viên trong phòng đó
              final roomMembersData = await _client
                  .from('chat_room_members')
                  .select()
                  .eq('room_id', roomId);

              for (var rm in roomMembersData) {
                String memberId = rm['user_id'];
                final profileData = await _client
                    .from('profiles')
                    .select()
                    .eq('id', memberId)
                    .single();
                room.members.add(UserModel.fromSupabase(profileData));
              }

              // Xử lý display name / avatar
              if (room.isGroup) {
                room.displayTitle = room.name ?? "Nhóm không tên";
                room.displayAvatar = room.avatarUrl;
              } else {
                final otherUser = room.members.firstWhere(
                  (m) => m.id != userId,
                  orElse: () => room.members.first,
                );
                room.displayTitle = otherUser.displayName ?? 'Người dùng';
                room.displayAvatar = otherUser.photoUrl;
              }

              // Lấy tin nhắn cuối cùng của phòng này
              final lastMsgData = await _client
                  .from('messages')
                  .select()
                  .eq('room_id', roomId)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();

              if (lastMsgData != null) {
                final lastMsg = Message.fromSupabase(lastMsgData);
                room.lastMessage = lastMsg.content;
                room.lastMessageTime = lastMsg.createdAt;
              }

              rooms.add(room);
            } catch (e) {
              print("Lỗi load phòng chat $roomId: $e");
            }
          }

          // Sắp xếp theo tin nhắn mới nhất (hoặc ngày tạo nếu chưa có tin nhắn)
          rooms.sort((a, b) {
            final aTime = a.lastMessageTime ?? a.createdAt;
            final bTime = b.lastMessageTime ?? b.createdAt;
            return bTime.compareTo(aTime);
          });

          // Lọc bỏ phòng 1-1 trùng lặp (nếu có lỗi race condition khi tạo)
          List<ChatRoom> uniqueRooms = [];
          Set<String> seenDirectUsers = {};

          for (var r in rooms) {
            if (r.isGroup) {
              uniqueRooms.add(r);
            } else {
              final otherUser = r.members.firstWhere(
                (m) => m.id != userId,
                orElse: () => r.members.first,
              );
              if (!seenDirectUsers.contains(otherUser.id)) {
                seenDirectUsers.add(otherUser.id);
                uniqueRooms.add(r);
              }
            }
          }

          return uniqueRooms;
        });
  }

  /// Khởi tạo phòng chat 1-1
  Future<String> createDirectRoom(String myId, String friendId) async {
    // 1. Kiểm tra xem phòng giữa 2 người đã tồn tại chưa
    // Lấy tất cả phòng 1-1 của mình
    final myRooms = await _client
        .from('chat_room_members')
        .select('room_id')
        .eq('user_id', myId);

    for (var row in myRooms) {
      String rId = row['room_id'];
      // Xem phòng này có phải isGroup = false không
      final roomData = await _client
          .from('chat_rooms')
          .select()
          .eq('id', rId)
          .single();
      if (roomData['is_group'] == false) {
        // Kiểm tra xem friend có trong phòng này không
        final friendData = await _client
            .from('chat_room_members')
            .select()
            .eq('room_id', rId)
            .eq('user_id', friendId);

        if (friendData.isNotEmpty) {
          // Phòng đã tồn tại -> trả về ID phòng cũ
          return rId;
        }
      }
    }

    // 2. Tạo phòng mới
    final roomInsert = await _client
        .from('chat_rooms')
        .insert({'is_group': false})
        .select()
        .single();

    final newRoomId = roomInsert['id'];

    // 3. Thêm 2 thành viên
    await _client.from('chat_room_members').insert([
      {'room_id': newRoomId, 'user_id': myId},
      {'room_id': newRoomId, 'user_id': friendId},
    ]);

    return newRoomId;
  }

  /// Khởi tạo phòng chat nhóm
  Future<String> createGroupRoom(
    String name,
    List<String> memberIds, {
    String? avatarUrl,
    String? sportType,
  }) async {
    // 1. Tạo phòng mới
    final roomData = {'is_group': true, 'name': name};
    if (avatarUrl != null) roomData['avatar_url'] = avatarUrl;
    if (sportType != null) roomData['sport_type'] = sportType;
    if (memberIds.isNotEmpty) roomData['admin_id'] = memberIds.first;

    final roomInsert = await _client
        .from('chat_rooms')
        .insert(roomData)
        .select()
        .single();

    final newRoomId = roomInsert['id'];

    // 2. Thêm tất cả thành viên
    final insertData = memberIds
        .map((id) => {'room_id': newRoomId, 'user_id': id})
        .toList();

    await _client.from('chat_room_members').insert(insertData);

    return newRoomId;
  }

  /// Cache profile người gửi để không phải fetch lại mỗi lần stream emit
  final Map<String, UserModel> _senderCache = {};

  /// Lắng nghe tin nhắn của 1 phòng
  Stream<List<Message>> getMessagesStream(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true) // Tin nhắn cũ nhất lên trên
        .asyncMap((messagesData) async {
          List<Message> messages = [];
          for (var msgData in messagesData) {
            final msg = Message.fromSupabase(msgData);

            // Dùng cache để tránh fetch lại profile đã biết
            if (_senderCache.containsKey(msg.senderId)) {
              msg.sender = _senderCache[msg.senderId];
            } else {
              try {
                final senderData = await _client
                    .from('profiles')
                    .select()
                    .eq('id', msg.senderId)
                    .single();
                final user = UserModel.fromSupabase(senderData);
                _senderCache[msg.senderId] = user;
                msg.sender = user;
              } catch (e) {
                print("Lỗi load người gửi $e");
              }
            }
            messages.add(msg);
          }
          return messages;
        });
  }

  /// Gửi tin nhắn
  Future<void> sendMessage(
    String roomId,
    String senderId,
    String content, {
    String? imagePath,
  }) async {
    final Map<String, dynamic> data = {
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
    };
    if (imagePath != null) {
      data['image_path'] = imagePath;
    }

    // 1. Lưu tin nhắn
    await _client.from('messages').insert(data);

    // 2. Tạo in-app notification cho các thành viên khác
    try {
      final membersData = await _client
          .from('chat_room_members')
          .select('user_id')
          .eq('room_id', roomId);

      for (var row in membersData) {
        final String memberId = row['user_id'];
        if (memberId != senderId) {
          await _client.from('notifications').insert({
            'user_id': memberId,
            'type': 'new_message',
            'title': 'Tin nhắn mới',
            'message': content.isNotEmpty
                ? content
                : 'Bạn nhận được một hình ảnh mới',
            'is_read': false,
          });

          // Gọi API bắn Push Notification (FCM)
          try {
            final senderProfileData = await _client
                .from('profiles')
                .select('display_name')
                .eq('id', senderId)
                .single();
            final senderName = senderProfileData['display_name'] ?? 'Ai đó';

            final roomData = await _client
                .from('chat_rooms')
                .select('is_group')
                .eq('id', roomId)
                .single();
            final bool isGroup = roomData['is_group'] == true;

            final notificationTitle = isGroup ? 'Tin nhắn nhóm' : senderName;
            final notificationBody = content.isNotEmpty
                ? (isGroup ? '$senderName: $content' : content)
                : 'Đã gửi một hình ảnh';

            await http
                .post(
                  Uri.parse(
                    'https://badminton-ai-1.onrender.com/api/send-notification',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'receiver_id': memberId,
                    'title': notificationTitle,
                    'body': notificationBody,
                    'data': {
                      'type': 'chat',
                      'room_id': roomId,
                      'sender_id': senderId,
                    },
                  }),
                )
                .timeout(const Duration(seconds: 10));
          } catch (e) {
            print('Lỗi gọi API gửi Push Notification: $e');
          }
        }
      }
    } catch (e) {
      print('Lỗi tạo notification khi gửi tin nhắn: $e');
    }
  }

  /// Upload ảnh lên Supabase Storage
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      // Removed 'chat_images/' because the bucket name is already 'chat_images'
      final path = fileName;

      await _client.storage
          .from('chat_images')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      return _client.storage.from('chat_images').getPublicUrl(path);
    } catch (e) {
      print('Lỗi upload ảnh: $e');
      return null;
    }
  }

  /// Giải tán nhóm
  Future<void> dissolveGroup(String roomId) async {
    // Xóa tất cả tin nhắn
    await _client.from('messages').delete().eq('room_id', roomId);
    // Xóa thành viên
    await _client.from('chat_room_members').delete().eq('room_id', roomId);
    // Xóa phòng
    await _client.from('chat_rooms').delete().eq('id', roomId);
  }

  /// Rời khỏi nhóm
  Future<void> leaveGroup(String roomId, String userId) async {
    await _client
        .from('chat_room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }
}
