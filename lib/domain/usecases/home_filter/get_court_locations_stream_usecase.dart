import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/domain/repositories/home_filter_repository.dart';

class GetCourtLocationsStreamUseCase {
  final HomeFilterRepository _repository;

  GetCourtLocationsStreamUseCase(this._repository);

  Stream<List<CourtLocationModel>> call() {
    return _repository.getCourtLocationsStream();
  }
}
