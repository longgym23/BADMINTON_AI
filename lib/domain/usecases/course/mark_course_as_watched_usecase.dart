import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';

class MarkCourseAsWatchedUseCase {
  final ICourseRepository _repository;

  MarkCourseAsWatchedUseCase(this._repository);

  Future<void> call(Course course) {
    return _repository.markCourseAsWatched(course);
  }
}
