import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/domain/repositories/home_filter_repository.dart';

class HomeFilterRepositoryImpl implements HomeFilterRepository {
  final SupabaseRepository _supabaseRepository;

  HomeFilterRepositoryImpl(this._supabaseRepository);

  @override
  Stream<List<CourtLocationModel>> getCourtLocationsStream() {
    return _supabaseRepository.getCourtLocationsStream();
  }

  @override
  Future<List<CourtLocationModel>> getAllCourtsFallback() {
    return _supabaseRepository.getAllCourtsFallback();
  }

  @override
  Stream<List<EventModel>> getEventsStream() {
    return _supabaseRepository.getEventsStream();
  }
}
