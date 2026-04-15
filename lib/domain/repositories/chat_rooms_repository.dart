import 'package:badminton_ai/data/repositories/chat_room_repository.dart';

abstract class ChatRoomsRepository {
  Stream<List<ChatRoom>> getUserRoomsStream(String userId);
}
