import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/domain/repositories/chat_rooms_repository.dart';

class WatchUserChatRoomsUseCase {
  final ChatRoomsRepository _repository;

  WatchUserChatRoomsUseCase(this._repository);

  Stream<List<ChatRoom>> call(String userId) {
    return _repository.getUserRoomsStream(userId);
  }
}
