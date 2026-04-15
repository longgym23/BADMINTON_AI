import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/domain/repositories/home_filter_repository.dart';

class GetEventsStreamUseCase {
  final HomeFilterRepository _repository;

  GetEventsStreamUseCase(this._repository);

  Stream<List<EventModel>> call() {
    return _repository.getEventsStream();
  }
}
