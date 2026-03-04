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

  Future<void> sendFriendRequest(String senderId, String receiverId) {
    return _repository.sendFriendRequest(senderId, receiverId);
  }

  Future<void> acceptFriendRequest(String userId1, String userId2) {
    return _repository.acceptFriendRequest(userId1, userId2);
  }

  Future<void> rejectOrRemoveFriend(String userId1, String userId2) {
    return _repository.removeFriend(userId1, userId2);
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
