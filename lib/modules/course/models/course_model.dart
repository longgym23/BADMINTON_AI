import 'course.dart';

class CourseModel extends Course {
  CourseModel({
    required super.id,
    required super.title,
    required super.description,
    required super.videoUrl,
    required super.thumbnailUrl,
    required super.categoryId,
    required super.duration,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['video_url'] ?? json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'] ?? '',
      categoryId: json['category_id']?.toString() ?? json['categoryId']?.toString() ?? '',
      duration: json['duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'categoryId': categoryId,
      'duration': duration,
    };
  }

  // Factory method để chuyển đổi từ Entity sang Model nếu cần
  factory CourseModel.fromEntity(Course course) {
    return CourseModel(
      id: course.id,
      title: course.title,
      description: course.description,
      videoUrl: course.videoUrl,
      thumbnailUrl: course.thumbnailUrl,
      categoryId: course.categoryId,
      duration: course.duration,
    );
  }
}
