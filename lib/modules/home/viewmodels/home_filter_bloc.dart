import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/filter_criteria.dart';
import '../repositories/home_repository.dart';
import 'home_filter_event.dart';
import 'home_filter_state.dart';
import 'package:flutter/foundation.dart';

class HomeFilterBloc extends Bloc<HomeFilterEvent, HomeFilterState> {
  final IHomeRepository _homeRepository;
  StreamSubscription? _courtsSubscription;

  HomeFilterBloc({
    required IHomeRepository homeRepository,
  }) : _homeRepository = homeRepository,
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
        _homeRepository.watchCourts(),
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
      debugPrint(
        "Stream timeout/lỗi: $e. Sử dụng phương thức tải tĩnh dự phòng (Fallback)...",
      );
      try {
        final courts = await _homeRepository.getFallbackCourts();

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

  // ─── Semantic keyword → sportType mapping ──────────────────────────────────
  static const _sportKeywordMap = <String, String>{
    // Cầu lông
    'cầu lông': 'badminton',
    'cau long': 'badminton',
    'caulong': 'badminton',
    'badminton': 'badminton',
    // Pickleball
    'pickleball': 'pickleball',
    'pickle ball': 'pickleball',
    // Bóng đá
    'bóng đá': 'football',
    'bong da': 'football',
    'bongda': 'football',
    'football': 'football',
    'soccer': 'football',
    // Bóng rổ
    'bóng rổ': 'basketball',
    'bong ro': 'basketball',
    'basketball': 'basketball',
    // Bóng chuyền
    'bóng chuyền': 'volleyball',
    'bong chuyen': 'volleyball',
    'volleyball': 'volleyball',
    // Tennis
    'tennis': 'tennis',
    // Bơi lội
    'bơi': 'swimming',
    'boi': 'swimming',
    'swimming': 'swimming',
  };

  // Filter Sync logic
  List<CourtLocationModel> _applyFilterLogicSync(
    List<CourtLocationModel> allCourts,
    FilterCriteria criteria,
  ) {
    return allCourts.where((court) {
      if (criteria.searchQuery?.isNotEmpty == true) {
        final q = criteria.searchQuery!.toLowerCase().trim();

        // Kiểm tra xem query có phải từ khóa môn thể thao không
        final mappedSport = _sportKeywordMap[q];

        // Khớp theo tên hoặc địa chỉ
        final matchText =
            court.name.toLowerCase().contains(q) ||
            court.address.toLowerCase().contains(q);

        // Khớp theo sportType (cả giá trị DB lẫn tên hiển thị)
        final courtSport = court.sportType?.toLowerCase() ?? '';
        final matchSport =
            mappedSport != null
                ? courtSport == mappedSport
                : courtSport.contains(q);

        if (!matchText && !matchSport) return false;
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
        final events = await _homeRepository.watchEvents().first;
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
        debugPrint('Lỗi filter events: $e');
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
