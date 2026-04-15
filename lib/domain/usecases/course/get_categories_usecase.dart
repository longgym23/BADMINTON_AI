import 'package:badminton_ai/domain/entities/course_category.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';

class GetCategoriesUseCase {
  final ICourseRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<CourseCategory>> call() {
    return _repository.getCategories();
  }
}
