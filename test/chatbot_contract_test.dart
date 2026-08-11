import 'package:badminton_ai/modules/chat/models/chat_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chatbot message contract', () {
    test('ChatMessageModel initializes correctly', () {
      final now = DateTime.now();
      final message = ChatMessageModel(
        id: 'msg-01',
        text: 'Xin chào AI Coach',
        isUser: true,
        timestamp: now,
      );

      expect(message.id, 'msg-01');
      expect(message.text, 'Xin chào AI Coach');
      expect(message.isUser, true);
      expect(message.timestamp, now);
    });
  });
}
