import 'package:badminton_ai/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendRepository {
  final SupabaseClient _client;

  FriendRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Tìm user bằng số điện thoại (chính xác)
  Future<UserModel?> searchUserByPhone(String phone) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('phone_number', phone)
          .maybeSingle(); // maybeSingle trả về null nếu không tìm thấy

      if (data != null) {
        return UserModel.fromSupabase(data);
      }
      return null;
    } catch (e) {
      print("Lỗi searchUserByPhone: $e");
      return null;
    }
  }

  /// Lấy danh sách bạn bè đã được chấp nhận của user
  Stream<List<UserModel>> getFriendListStream(String userId) {
    return _client
        .from('friendships')
        .stream(primaryKey: ['user_id1', 'user_id2'])
        .eq('status', 'accepted')
        .map((friendships) {
          // Lọc ra các friendship có user_id hiện tại (1 hoặc 2)
          return friendships
              .where((f) => f['user_id1'] == userId || f['user_id2'] == userId)
              .toList();
        })
        .asyncMap((friendships) async {
          // Lấy profile của người bạn đó
          List<UserModel> friends = [];
          for (var f in friendships) {
            String friendId = f['user_id1'] == userId
                ? f['user_id2']
                : f['user_id1'];
            try {
              final profileData = await _client
                  .from('profiles')
                  .select()
                  .eq('id', friendId)
                  .single();
              friends.add(UserModel.fromSupabase(profileData));
            } catch (e) {
              print("Lỗi load profile bạn bè: $e");
            }
          }
          return friends;
        });
  }

  /// Lấy danh sách lời mời kết bạn GỬI ĐẾN user
  Stream<List<Map<String, dynamic>>> getPendingRequestsStream(String userId) {
    return _client
        .from('friendships')
        .stream(primaryKey: ['user_id1', 'user_id2'])
        .eq('status', 'pending')
        .map((friendships) {
          // Lọc các request mà userId của mình NẰM TRONG CẶP, nhưng MÌNH KHÔNG PHẢI NGƯỜI GỬI (id != userId)
          // Cột 'id' trong bảng friendships được set default là auth.uid() -> tức là sender_id
          return friendships
              .where(
                (f) =>
                    (f['user_id1'] == userId || f['user_id2'] == userId) &&
                    f['id'] != userId,
              )
              .toList();
        })
        .asyncMap((friendships) async {
          List<Map<String, dynamic>> requestsInfo = [];
          for (var f in friendships) {
            String senderId = f['id']; // id chính là requester_id
            try {
              final profileData = await _client
                  .from('profiles')
                  .select()
                  .eq('id', senderId)
                  .single();
              requestsInfo.add({
                'user': UserModel.fromSupabase(profileData),
                'user_id1': f['user_id1'],
                'user_id2': f['user_id2'],
              });
            } catch (e) {
              print("Lỗi load profile người gửi lời mời: $e");
            }
          }
          return requestsInfo;
        });
  }

  /// Gửi lời mời kết bạn (pending)
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    // Luôn sắp xếp id1 < id2 như constraint trong SQL
    String id1 = senderId.compareTo(receiverId) < 0 ? senderId : receiverId;
    String id2 = senderId.compareTo(receiverId) > 0 ? senderId : receiverId;

    await _client.from('friendships').insert({
      'user_id1': id1,
      'user_id2': id2,
      'status': 'pending',
      // 'id': auth.uid() is handled automatically by DB default
    });
  }

  /// Chấp nhận lời mời kết bạn (accepted)
  Future<void> acceptFriendRequest(String userId1, String userId2) async {
    String id1 = userId1.compareTo(userId2) < 0 ? userId1 : userId2;
    String id2 = userId1.compareTo(userId2) > 0 ? userId1 : userId2;

    await _client.from('friendships').update({'status': 'accepted'}).match({
      'user_id1': id1,
      'user_id2': id2,
    });
  }

  /// Xóa bạn (hoặc hủy lời mời)
  Future<void> removeFriend(String userId1, String userId2) async {
    String id1 = userId1.compareTo(userId2) < 0 ? userId1 : userId2;
    String id2 = userId1.compareTo(userId2) > 0 ? userId1 : userId2;

    await _client.from('friendships').delete().match({
      'user_id1': id1,
      'user_id2': id2,
    });
  }
}
