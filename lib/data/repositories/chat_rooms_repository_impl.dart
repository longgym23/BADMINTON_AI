import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/domain/repositories/chat_rooms_repository.dart';

class ChatRoomsRepositoryImpl implements ChatRoomsRepository {
  final ChatRoomRepository _chatRoomRepository;

  ChatRoomsRepositoryImpl(this._chatRoomRepository);

  @override
  Stream<List<ChatRoom>> getUserRoomsStream(String userId) {
    return _chatRoomRepository.getUserRoomsStream(userId);
  }
}
