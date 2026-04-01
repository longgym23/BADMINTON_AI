import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/entities/course_category.dart';

abstract class ICourseRepository {
  Future<List<CourseCategory>> getCategories();
  Future<List<Course>> getCoursesByCategory(String categoryId);
  Future<List<Course>> getWatchedCourses();
  Future<void> markCourseAsWatched(Course course);
}
