import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/domain/repositories/home_filter_repository.dart';

class GetFallbackCourtsUseCase {
  final HomeFilterRepository _repository;

  GetFallbackCourtsUseCase(this._repository);

  Future<List<CourtLocationModel>> call() {
    return _repository.getAllCourtsFallback();
  }
}
