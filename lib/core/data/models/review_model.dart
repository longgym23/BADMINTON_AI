import 'package:badminton_ai/data/models/user_model.dart';

class ReviewModel {
  final String id;
  final String courtId;
  final String? userId; // Có thể null vì review từ Google Maps không có user_id
  final int rating;
  final String? comment;
  final DateTime createdAt;
  UserModel? reviewer;

  // Trường mới dành cho đánh giá từ Google Maps
  final String? reviewerName;
  final String? reviewerAvatar;

  ReviewModel({
    required this.id,
    required this.courtId,
    this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewer,
    this.reviewerName,
    this.reviewerAvatar,
  });

  factory ReviewModel.fromSupabase(Map<String, dynamic> data) {
    return ReviewModel(
      id: data['id'] ?? '',
      courtId: data['court_id'] ?? '',
      userId: data['user_id'],
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String?,
      reviewerName: data['reviewer_name'] as String?,
      reviewerAvatar: data['reviewer_avatar'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'court_id': courtId,
      if (userId != null) 'user_id': userId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (reviewerName != null) 'reviewer_name': reviewerName,
      if (reviewerAvatar != null) 'reviewer_avatar': reviewerAvatar,
    };
  }
}
