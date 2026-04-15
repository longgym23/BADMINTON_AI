import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';

class GetWatchedCoursesUseCase {
  final ICourseRepository _repository;

  GetWatchedCoursesUseCase(this._repository);

  Future<List<Course>> call() {
    return _repository.getWatchedCourses();
  }
}
