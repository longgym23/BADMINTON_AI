import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'imagePath': imagePath,
      'audioPath': audioPath,
      'type': type,
      'metadata': metadata,
    };
  }

  // Create from Firestore Document
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imagePath: data['imagePath'],
      audioPath: data['audioPath'],
      type: data['type'] ?? 'text',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}
