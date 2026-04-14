import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/filter_criteria.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'home_filter_event.dart';
import 'home_filter_state.dart';

class HomeFilterBloc extends Bloc<HomeFilterEvent, HomeFilterState> {
  final SupabaseRepository _repository;
  StreamSubscription? _courtsSubscription;

  HomeFilterBloc({required SupabaseRepository repository})
    : _repository = repository,
      super(HomeFilterState()) {
    on<LoadAllCourts>(_onLoadAllCourts);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SportFilterToggled>(_onSportFilterToggled);
    on<FilterCriteriaApplied>(_onFilterCriteriaApplied);
    on<FilterCriteriaReset>(_onFilterCriteriaReset);
  }

  void _onLoadAllCourts(
    LoadAllCourts event,
    Emitter<HomeFilterState> emit,
  ) async {
    emit(state.copyWith(status: HomeFilterStatus.loading));

    await emit.forEach<List<CourtLocationModel>>(
      _repository.getCourtLocationsStream(),
      onData: (courts) {
        // Khi courts thay đổi, mảng filtered giữ nguyên cho đến khi áp dụng lại bộ lọc cụ thể (tránh lỗi sync timeout filter).
        // Nếu muốn apply ngay lập tức, ta cần sửa lại logic luồng. Tạm thời chỉ filter lại bằng local filter thông thường.
        List<CourtLocationModel> localFiltered = courts;
        if (state.filterCriteria.scheduleType != 'event') {
          localFiltered = _applyFilterLogicSync(courts, state.filterCriteria);
        }
        return state.copyWith(
          status: HomeFilterStatus.success,
          allCourts: courts,
          filteredCourts: localFiltered,
        );
      },
      onError: (error, stackTrace) {
        return state.copyWith(
          status: HomeFilterStatus.failure,
          errorMessage: 'Lỗi tải danh sách sân: $error',
        );
      },
    );
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<HomeFilterState> emit,
  ) async {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(searchQuery: event.query);
    final filtered = await _applyFilterLogic(state.allCourts, newCriteria);
    emit(
      state.copyWith(
        filterCriteria: newCriteria,
        filteredCourts: filtered,
      ),
    );
  }

  void _onSportFilterToggled(
    SportFilterToggled event,
    Emitter<HomeFilterState> emit,
  ) async {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(
      sportType: event.sport,
      clearSportType: event.sport == null,
    );
    final filtered = await _applyFilterLogic(state.allCourts, newCriteria);
    emit(
      state.copyWith(
        filterCriteria: newCriteria,
        filteredCourts: filtered,
      ),
    );
  }

  void _onFilterCriteriaApplied(
    FilterCriteriaApplied event,
    Emitter<HomeFilterState> emit,
  ) async {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(
      sportType: event.sportType,
      scheduleType: event.scheduleType,
      dateRange: event.dateRange,
      timeStart: event.timeStart,
      timeEnd: event.timeEnd,
      eventTimeFilter: event.eventTimeFilter,
      clearSportType: event.sportType == null,
      maxPrice: event.maxPrice,
    );

    emit(state.copyWith(status: HomeFilterStatus.loading));
    final filtered = await _applyFilterLogic(state.allCourts, newCriteria);

    emit(
      state.copyWith(
        status: HomeFilterStatus.success,
        filterCriteria: newCriteria,
        filteredCourts: filtered,
      ),
    );
  }

  void _onFilterCriteriaReset(
    FilterCriteriaReset event,
    Emitter<HomeFilterState> emit,
  ) async {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(
      sportType: null,
      clearSportType: true,
      searchQuery: null,
      maxPrice: null,
      scheduleType: 'empty',
    );
    newCriteria.searchQuery = null; // Explicit clear
    newCriteria.maxPrice = null; // Explicit clear
    newCriteria.scheduleType = 'empty';

    emit(
      state.copyWith(
        filterCriteria: newCriteria,
        filteredCourts: state.allCourts, // All courts shown
      ),
    );
  }

  // Filter Sync logic
  List<CourtLocationModel> _applyFilterLogicSync(
    List<CourtLocationModel> allCourts,
    FilterCriteria criteria,
  ) {
    return allCourts.where((court) {
      if (criteria.searchQuery?.isNotEmpty == true) {
        final q = criteria.searchQuery!.toLowerCase();
        if (!court.name.toLowerCase().contains(q) &&
            !court.address.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (criteria.sportType != null) {
        if (court.sportType != null && court.sportType!.isNotEmpty) {
          if (court.sportType != criteria.sportType) return false;
        }
      }
      if (criteria.maxPrice != null) {
        if (court.pricePerHour > criteria.maxPrice!) return false;
      }
      return true;
    }).toList();
  }

  Future<List<CourtLocationModel>> _applyFilterLogic(
    List<CourtLocationModel> allCourts,
    FilterCriteria criteria,
  ) async {
    List<CourtLocationModel> courts = _applyFilterLogicSync(allCourts, criteria);

    // Lọc sự kiện theo scheduleType == 'event'
    if (criteria.scheduleType == 'event') {
       try {
         final events = await _repository.getEventsStream().first;
         final eventCourtIds = events.map((e) => e.courtId).toSet();
         courts = courts.where((c) => eventCourtIds.contains(c.id)).toList();
       } catch (e) {
         print('Lỗi filter events: $e');
         courts = [];
       }
    }

    return courts;
  }


  @override
  Future<void> close() {
    _courtsSubscription?.cancel();
    return super.close();
  }
}
