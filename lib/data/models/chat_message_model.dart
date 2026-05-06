import 'package:easy_localization/easy_localization.dart';


class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;
  final String? audioPath;
  final String type; // 'text', 'booking_success', 'mixed'
  final Map<String, dynamic>? metadata;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
    this.audioPath,
    this.type = 'text',
    this.metadata,
  });


  // Create from Supabase Map
  factory ChatMessageModel.fromSupabase(Map<String, dynamic> data) {
    return ChatMessageModel(
      id: data['id'] ?? '',
      text: data['text'] ?? '',
      isUser: data['is_user'] ?? false,
      timestamp: data['created_at'] != null
          ? DateTime.parse(data['created_at']) // Supabase trả về ISO8601 string
          : DateTime.now(),
      imagePath: data['image_path'],
      audioPath: data['audio_path'],
      type: (data['type'] as String?) ?? 'text',
      metadata: data['metadata'] is Map<String, dynamic>
          ? (data['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  // Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': '', // Sẽ được điền ở repository
      'text': text,
      'is_user': isUser,
      'image_path': imagePath,
      'audio_path': audioPath,
      'type': type,
      'metadata': metadata,
      // 'created_at': Supabase tự sinh
    };
  }
}
