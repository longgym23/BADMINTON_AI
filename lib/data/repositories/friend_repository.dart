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

  /// Kiểm tra trạng thái quan hệ giữa 2 user.
  /// Trả về: 'none' | 'pending_sent' | 'pending_received' | 'accepted'
  Future<String> checkRelationship(String myId, String otherId) async {
    try {
      String id1 = myId.compareTo(otherId) < 0 ? myId : otherId;
      String id2 = myId.compareTo(otherId) > 0 ? myId : otherId;

      final rows = await _client
          .from('friendships')
          .select()
          .eq('user_id1', id1)
          .eq('user_id2', id2)
          .maybeSingle();

      if (rows == null) return 'none';

      final status = rows['status'] as String?;
      if (status == 'accepted') return 'accepted';

      if (status == 'pending') {
        // Xác định mình là người gửi hay người nhận
        final requesterId = rows['id'] as String?;
        return requesterId == myId ? 'pending_sent' : 'pending_received';
      }

      return 'none'; // rejected hoặc trạng thái lạ
    } catch (e) {
      print('Lỗi checkRelationship: $e');
      return 'none';
    }
  }

  /// Gửi lời mời kết bạn (pending).
  /// Tự động kiểm tra nếu đã tồn tại quan hệ thì bỏ qua, tránh duplicate key.
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    // Luôn sắp xếp id1 < id2 như constraint trong SQL
    String id1 = senderId.compareTo(receiverId) < 0 ? senderId : receiverId;
    String id2 = senderId.compareTo(receiverId) > 0 ? senderId : receiverId;

    // Kiểm tra đã tồn tại chưa trước khi INSERT
    final existing = await _client
        .from('friendships')
        .select()
        .eq('user_id1', id1)
        .eq('user_id2', id2)
        .maybeSingle();

    if (existing != null) {
      final status = existing['status'] as String?;
      if (status == 'accepted') {
        throw Exception('already_friends');
      }
      if (status == 'pending') {
        throw Exception('already_pending');
      }
      // Nếu rejected → cập nhật lại thành pending
      await _client
          .from('friendships')
          .update({'status': 'pending'})
          .eq('user_id1', id1)
          .eq('user_id2', id2);
      return;
    }

    await _client.from('friendships').insert({
      'user_id1': id1,
      'user_id2': id2,
      'status': 'pending',
    });
  }

  /// Chấp nhận lời mời kết bạn (accepted)
  Future<void> acceptFriendRequest(String userId1, String userId2) async {
    await _client.from('friendships').update({'status': 'accepted'}).or(
      'and(user_id1.eq.$userId1,user_id2.eq.$userId2),and(user_id1.eq.$userId2,user_id2.eq.$userId1)'
    );
  }

  /// Xóa bạn (hoặc hủy lời mời)
  Future<void> removeFriend(String userId1, String userId2) async {
    try {
      // Tìm chính xác dòng quan hệ (thử cả 2 chiều)
      final rows = await _client.from('friendships')
        .select()
        .or('and(user_id1.eq.$userId1,user_id2.eq.$userId2),and(user_id1.eq.$userId2,user_id2.eq.$userId1)');

      if (rows.isNotEmpty) {
        final Map<String, dynamic> row = rows.first;
        final validId1 = row['user_id1'];
        final validId2 = row['user_id2'];

        // Thử xoá và yêu cầu trả về dữ liệu (để kiểm tra xem có xoá được thật không)
        final deletedRows = await _client.from('friendships')
            .delete()
            .match({'user_id1': validId1, 'user_id2': validId2})
            .select();

        // Nếu deletedRows rỗng nghĩa là RLS policy đã CHẶN lệnh DELETE!
        if (deletedRows.isEmpty) {
          // Thử UPDATE chuyển status về rejected
          final updatedRows = await _client.from('friendships')
              .update({'status': 'rejected'})
              .match({'user_id1': validId1, 'user_id2': validId2})
              .select();
              
          if (updatedRows.isEmpty) {
             throw Exception('Hành động bị chặn bởi bảo mật CSDL (Row-Level Security của Supabase). Hãy kiểm tra lại policy bảng friendships.');
          }
        }
      } else {
        throw Exception('Không tìm thấy dữ liệu bạn bè trên hệ thống.');
      }
    } catch (e) {
      print("Lỗi khi xóa bạn: $e");
      rethrow;
    }
  }


}
