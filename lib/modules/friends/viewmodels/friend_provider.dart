import 'dart:async';

import 'package:badminton_ai/core/data/models/user_model.dart';
import 'package:badminton_ai/modules/friends/repositories/friend_repository.dart';
import 'package:flutter/foundation.dart';

/// ViewModel for Friends. Talks directly to [IFriendRepository].
class FriendProvider extends ChangeNotifier {
  FriendProvider({required IFriendRepository friendRepository})
    : _friendRepository = friendRepository;

  final IFriendRepository _friendRepository;

  StreamSubscription? _friendsSub;
  StreamSubscription? _requestsSub;

  List<UserModel> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;

  void startListening(String userId) {
    stopListening();

    _friendsSub = _friendRepository.watchFriendList(userId).listen((data) {
      _friends = data;
      notifyListeners();
    });

    _requestsSub = _friendRepository.watchPendingRequests(userId).listen((
      data,
    ) {
      _pendingRequests = data;
      notifyListeners();
    });
  }

  void stopListening() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
  }

  Future<UserModel?> searchUserByPhone(String phone) {
    return _friendRepository.searchUserByPhone(phone);
  }

  /// Kiểm tra trạng thái quan hệ: 'none' | 'pending_sent' | 'pending_received' | 'accepted'
  Future<String> checkRelationship(String myId, String otherId) {
    return _friendRepository.checkRelationship(myId, otherId);
  }

  Future<void> sendFriendRequest(String senderId, String receiverId) {
    return _friendRepository.sendFriendRequest(senderId, receiverId);
  }

  Future<void> acceptFriendRequest(String userId1, String userId2) {
    _pendingRequests.removeWhere(
      (r) =>
          (r['user_id1'] == userId1 && r['user_id2'] == userId2) ||
          (r['user_id1'] == userId2 && r['user_id2'] == userId1),
    );
    notifyListeners();
    return _friendRepository.acceptFriendRequest(userId1, userId2);
  }

  Future<void> rejectOrRemoveFriend(String userId1, String userId2) {
    _friends.removeWhere((f) => f.id == userId1 || f.id == userId2);
    _pendingRequests.removeWhere(
      (r) =>
          (r['user_id1'] == userId1 && r['user_id2'] == userId2) ||
          (r['user_id1'] == userId2 && r['user_id2'] == userId1),
    );
    notifyListeners();
    return _friendRepository.removeFriend(userId1, userId2);
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
