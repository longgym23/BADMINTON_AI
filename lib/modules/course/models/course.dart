class Course {
  final String id;
  final String title;
  final String description;
  final String videoUrl; // YouTube URL
  final String thumbnailUrl;
  final String categoryId;
  final String duration;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.categoryId,
    required this.duration,
  });
}
