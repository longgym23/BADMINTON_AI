import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/filter_criteria.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_court_locations_stream_usecase.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_events_stream_usecase.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_fallback_courts_usecase.dart';
import 'home_filter_event.dart';
import 'home_filter_state.dart';

class HomeFilterBloc extends Bloc<HomeFilterEvent, HomeFilterState> {
  final GetCourtLocationsStreamUseCase _getCourtLocationsStreamUseCase;
  final GetFallbackCourtsUseCase _getFallbackCourtsUseCase;
  final GetEventsStreamUseCase _getEventsStreamUseCase;
  StreamSubscription? _courtsSubscription;

  HomeFilterBloc({
    required GetCourtLocationsStreamUseCase getCourtLocationsStreamUseCase,
    required GetFallbackCourtsUseCase getFallbackCourtsUseCase,
    required GetEventsStreamUseCase getEventsStreamUseCase,
  }) : _getCourtLocationsStreamUseCase = getCourtLocationsStreamUseCase,
       _getFallbackCourtsUseCase = getFallbackCourtsUseCase,
       _getEventsStreamUseCase = getEventsStreamUseCase,
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

    try {
      await emit.forEach<List<CourtLocationModel>>(
        _getCourtLocationsStreamUseCase(),
        onData: (courts) {
          // Khi courts thay đổi, mảng filtered giữ nguyên cho đến khi áp dụng lại bộ lọc cụ thể (tránh lỗi sync timeout filter).
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
          // Gném lỗi ra catch block bên ngoài thay vì cập nhật trạng thái lỗi ngay để có cơ hội fallback
          throw Exception(error);
        },
      );
    } catch (e) {
      // Bắt lỗi stream (thường là lỗi RealtimeSubscribeException timeout)
      print(
        "Stream timeout/lỗi: $e. Sử dụng phương thức tải tĩnh dự phòng (Fallback)...",
      );
      try {
        final courts = await _getFallbackCourtsUseCase();

        List<CourtLocationModel> localFiltered = courts;
        if (state.filterCriteria.scheduleType != 'event') {
          localFiltered = _applyFilterLogicSync(courts, state.filterCriteria);
        }

        emit(
          state.copyWith(
            status: HomeFilterStatus.success,
            allCourts: courts,
            filteredCourts: localFiltered,
          ),
        );
      } catch (fallbackError) {
        emit(
          state.copyWith(
            status: HomeFilterStatus.failure,
            errorMessage: 'Lỗi tải danh sách sân: $fallbackError',
          ),
        );
      }
    }
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<HomeFilterState> emit,
  ) async {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(searchQuery: event.query);
    final filtered = await _applyFilterLogic(state.allCourts, newCriteria);
    emit(state.copyWith(filterCriteria: newCriteria, filteredCourts: filtered));
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
    emit(state.copyWith(filterCriteria: newCriteria, filteredCourts: filtered));
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
    List<CourtLocationModel> courts = _applyFilterLogicSync(
      allCourts,
      criteria,
    );

    // Lọc sự kiện theo scheduleType == 'event'
    if (criteria.scheduleType == 'event') {
      try {
        final events = await _getEventsStreamUseCase().first;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        bool inEventWindow(DateTime eventDate) {
          final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
          switch (criteria.eventTimeFilter) {
            case 'today':
              return day == today;
            case 'tomorrow':
              return day == today.add(const Duration(days: 1));
            case '3days':
              return !day.isBefore(today) &&
                  !day.isAfter(today.add(const Duration(days: 2)));
            case '1week':
              return !day.isBefore(today) &&
                  !day.isAfter(today.add(const Duration(days: 6)));
            case '2weeks':
              return !day.isBefore(today) &&
                  !day.isAfter(today.add(const Duration(days: 13)));
            default:
              return !day.isBefore(today);
          }
        }

        final validEvents = events
            .where((e) => !e.isEnded && inEventWindow(e.dateTime))
            .toList();
        final eventCourtIds = validEvents.map((e) => e.courtId).toSet();
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
