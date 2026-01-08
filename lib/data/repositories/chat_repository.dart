import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Lấy collection chat history của user
  CollectionReference _getChatCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history');
  }

  // Stream danh sách tin nhắn, sắp xếp theo thời gian mới nhất
  Stream<List<ChatMessageModel>> getMessages(String userId) {
    return _getChatCollection(userId)
        .orderBy('timestamp', descending: true) // Mới nhất ở đầu
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList();
        });
  }

  // Gửi tin nhắn mới (lưu vào Firestore)
  Future<void> sendMessage(String userId, ChatMessageModel message) async {
    // Nếu ID rỗng (tin nhắn mới), Firestore sẽ tự tạo ID nếu dùng .add()
    // Nhưng model của chúng ta có ID, nên ta dùng .doc(id).set() nếu id được tạo trước,
    // hoặc dùng .add() rồi cập nhật ID.
    // Ở đây ta sẽ để Firestore tự sinh ID nếu chưa có, nhưng ChatMessageModel thường được tạo khi gửi.
    // Cách tốt nhất: dùng doc().set() để control ID hoặc để Firestore sinh ID.

    // Nếu message.id rỗng hoặc placeholder, ta tạo doc mới
    DocumentReference docRef;
    if (message.id.isEmpty) {
      docRef = _getChatCollection(userId).doc();
    } else {
      docRef = _getChatCollection(userId).doc(message.id);
    }

    // Cập nhật timestamp server
    final data = message.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();

    await docRef.set(data);
  }

  // Xóa tin nhắn
  Future<void> deleteMessage(String userId, String messageId) async {
    await _getChatCollection(userId).doc(messageId).delete();
  }

  // Xóa toàn bộ lịch sử chat
  Future<void> clearChatHistory(String userId) async {
    final batch = _firestore.batch();
    var snapshots = await _getChatCollection(userId).get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
