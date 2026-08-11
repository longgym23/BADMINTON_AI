import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/event_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';

/// Data access port for the Home (court discovery / filter) feature.
abstract class IHomeRepository {
  /// Emits the list of courts (Realtime).
  Stream<List<CourtLocationModel>> watchCourts();

  /// Fetch courts once — used as a fallback when the Realtime stream
  /// fails/times out.
  Future<List<CourtLocationModel>> getFallbackCourts();

  /// Emits the list of upcoming events (Realtime).
  Stream<List<EventModel>> watchEvents();
}

class HomeRepository implements IHomeRepository {
  HomeRepository(this._supabaseRepository);

  final SupabaseRepository _supabaseRepository;

  @override
  Stream<List<CourtLocationModel>> watchCourts() =>
      _supabaseRepository.getCourtLocationsStream();

  @override
  Future<List<CourtLocationModel>> getFallbackCourts() =>
      _supabaseRepository.getAllCourtsFallback();

  @override
  Stream<List<EventModel>> watchEvents() =>
      _supabaseRepository.getEventsStream();
}
