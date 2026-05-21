import 'dart:async';
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/data/repositories/friend_repository.dart';
import 'package:flutter/foundation.dart';

class FriendProvider extends ChangeNotifier {
  final FriendRepository _repository;

  StreamSubscription? _friendsSub;
  StreamSubscription? _requestsSub;

  List<UserModel> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;

  FriendProvider(this._repository);

  void startListening(String userId) {
    stopListening();

    _friendsSub = _repository.getFriendListStream(userId).listen((data) {
      _friends = data;
      notifyListeners();
    });

    _requestsSub = _repository.getPendingRequestsStream(userId).listen((data) {
      _pendingRequests = data;
      notifyListeners();
    });
  }

  void stopListening() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
  }

  Future<UserModel?> searchUserByPhone(String phone) {
    return _repository.searchUserByPhone(phone);
  }

  /// Kiểm tra trạng thái quan hệ: 'none' | 'pending_sent' | 'pending_received' | 'accepted'
  Future<String> checkRelationship(String myId, String otherId) {
    return _repository.checkRelationship(myId, otherId);
  }

  Future<void> sendFriendRequest(String senderId, String receiverId) {
    return _repository.sendFriendRequest(senderId, receiverId);
  }

  Future<void> acceptFriendRequest(String userId1, String userId2) {
    _pendingRequests.removeWhere((r) => 
      (r['user_id1'] == userId1 && r['user_id2'] == userId2) || 
      (r['user_id1'] == userId2 && r['user_id2'] == userId1)
    );
    notifyListeners();
    return _repository.acceptFriendRequest(userId1, userId2);
  }

  Future<void> rejectOrRemoveFriend(String userId1, String userId2) {
    _friends.removeWhere((f) => f.id == userId1 || f.id == userId2);
    _pendingRequests.removeWhere((r) => 
      (r['user_id1'] == userId1 && r['user_id2'] == userId2) || 
      (r['user_id1'] == userId2 && r['user_id2'] == userId1)
    );
    notifyListeners();
    return _repository.removeFriend(userId1, userId2);
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
