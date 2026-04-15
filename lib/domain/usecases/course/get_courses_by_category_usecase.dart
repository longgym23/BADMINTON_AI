import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';

class GetCoursesByCategoryUseCase {
  final ICourseRepository _repository;

  GetCoursesByCategoryUseCase(this._repository);

  Future<List<Course>> call(String categoryId) {
    return _repository.getCoursesByCategory(categoryId);
  }
}
