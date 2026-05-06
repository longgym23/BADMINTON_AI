import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';

abstract class HomeFilterRepository {
  Stream<List<CourtLocationModel>> getCourtLocationsStream();
  Future<List<CourtLocationModel>> getAllCourtsFallback();
  Stream<List<EventModel>> getEventsStream();
}
