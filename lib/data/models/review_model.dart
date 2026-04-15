import 'package:badminton_ai/data/models/user_model.dart';

class ReviewModel {
  final String id;
  final String courtId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  UserModel? reviewer;

  ReviewModel({
    required this.id,
    required this.courtId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewer,
  });

  factory ReviewModel.fromSupabase(Map<String, dynamic> data) {
    return ReviewModel(
      id: data['id'] ?? '',
      courtId: data['court_id'] ?? '',
      userId: data['user_id'] ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'court_id': courtId,
      'user_id': userId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}
