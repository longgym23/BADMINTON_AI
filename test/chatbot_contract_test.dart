import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chatbot message contract', () {
    test('fromSupabase parses metadata action and citations', () {
      final message = ChatMessageModel.fromSupabase({
        'id': 'msg-ai-001',
        'text': 'Tôi tìm thấy một số sân phù hợp cho bạn.',
        'is_user': false,
        'created_at': '2026-05-13T09:00:00.000Z',
        'type': 'text',
        'metadata': {
          'action': {
            'type': 'search_courts',
            'sport': 'badminton',
            'filters': {'max_price': 120000},
          },
          'citations': [
            {'title': 'Chính sách sân', 'source': 'kb_documents'},
          ],
        },
      });

      expect(message.id, 'msg-ai-001');
      expect(message.isUser, isFalse);
      expect(message.metadata, isNotNull);
      expect(message.metadata!['action']['type'], 'search_courts');
      expect(message.metadata!['action']['sport'], 'badminton');
      expect(message.metadata!['citations'], isA<List>());
      expect(message.metadata!['citations'], hasLength(1));
    });

    test('fromSupabase parses image and audio paths for multimodal messages', () {
      final message = ChatMessageModel.fromSupabase({
        'id': 'msg-user-001',
        'text': 'Phân tích ảnh sân này giúp tôi',
        'is_user': true,
        'created_at': '2026-05-13T09:05:00.000Z',
        'image_path': '/tmp/court.jpg',
        'audio_path': '/tmp/question.m4a',
        'type': 'mixed',
      });

      expect(message.isUser, isTrue);
      expect(message.imagePath, '/tmp/court.jpg');
      expect(message.audioPath, '/tmp/question.m4a');
      expect(message.type, 'mixed');
    });

    test('toSupabase keeps text, type and metadata for AI messages', () {
      final metadata = {
        'action': {'type': 'view_schedule'},
        'citations': <Map<String, Object?>>[],
      };
      final message = ChatMessageModel(
        id: '',
        text: 'Bạn có một lịch đặt sân tối nay.',
        isUser: false,
        timestamp: DateTime(2026, 5, 13, 19),
        type: 'text',
        metadata: metadata,
      );

      final map = message.toSupabase();

      expect(map['text'], 'Bạn có một lịch đặt sân tối nay.');
      expect(map['is_user'], isFalse);
      expect(map['type'], 'text');
      expect(map['metadata'], same(metadata));
      expect(map['user_id'], '');
    });

    test('supports all chatbot action types used by the UI', () {
      const actionTypes = [
        'search_courts',
        'view_schedule',
        'view_expense',
        'cancel_booking',
      ];

      for (final actionType in actionTypes) {
        final message = ChatMessageModel.fromSupabase({
          'id': 'msg-$actionType',
          'text': 'Action response',
          'is_user': false,
          'created_at': '2026-05-13T09:10:00.000Z',
          'metadata': {
            'action': {'type': actionType},
          },
        });

        expect(message.metadata!['action']['type'], actionType);
      }
    });
  });
}
