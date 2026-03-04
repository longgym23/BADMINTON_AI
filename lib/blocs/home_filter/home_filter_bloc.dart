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

    // We listen to the courts stream to keep them updated
    await emit.forEach<List<CourtLocationModel>>(
      _repository.getCourtLocationsStream(),
      onData: (courts) {
        return state.copyWith(
          status: HomeFilterStatus.success,
          allCourts: courts,
          filteredCourts: _applyFilterLogic(courts, state.filterCriteria),
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
  ) {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(searchQuery: event.query);
    emit(
      state.copyWith(
        filterCriteria: newCriteria,
        filteredCourts: _applyFilterLogic(state.allCourts, newCriteria),
      ),
    );
  }

  void _onSportFilterToggled(
    SportFilterToggled event,
    Emitter<HomeFilterState> emit,
  ) {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(
      sportType: event.sport,
      clearSportType: event.sport == null,
    );
    emit(
      state.copyWith(
        filterCriteria: newCriteria,
        filteredCourts: _applyFilterLogic(state.allCourts, newCriteria),
      ),
    );
  }

  void _onFilterCriteriaApplied(
    FilterCriteriaApplied event,
    Emitter<HomeFilterState> emit,
  ) {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(
      sportType: event.sportType,
      clearSportType: event.sportType == null,
      maxPrice: event.maxPrice,
    );

    emit(
      state.copyWith(
        filterCriteria: newCriteria,
        filteredCourts: _applyFilterLogic(state.allCourts, newCriteria),
      ),
    );
  }

  void _onFilterCriteriaReset(
    FilterCriteriaReset event,
    Emitter<HomeFilterState> emit,
  ) {
    if (state.status != HomeFilterStatus.success) return;

    final newCriteria = state.filterCriteria.copyWith(
      sportType: null,
      clearSportType: true,
      searchQuery: null,
      maxPrice: null,
    );
    newCriteria.searchQuery = null; // Explicit clear
    newCriteria.maxPrice = null; // Explicit clear

    emit(
      state.copyWith(
        filterCriteria: newCriteria,
        filteredCourts: state.allCourts, // All courts shown
      ),
    );
  }

  List<CourtLocationModel> _applyFilterLogic(
    List<CourtLocationModel> allCourts,
    FilterCriteria criteria,
  ) {
    return allCourts.where((court) {
      // 1. Lọc theo Text
      if (criteria.searchQuery?.isNotEmpty == true) {
        final q = criteria.searchQuery!.toLowerCase();
        if (!court.name.toLowerCase().contains(q) &&
            !court.address.toLowerCase().contains(q)) {
          return false;
        }
      }

      // 2. Lọc theo môn thể thao
      if (criteria.sportType != null) {
        if (court.sportType != null && court.sportType!.isNotEmpty) {
          if (court.sportType != criteria.sportType) {
            return false;
          }
        }
      }

      // 3. Lọc theo giá lớn nhất
      if (criteria.maxPrice != null) {
        if (court.pricePerHour > criteria.maxPrice!) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Future<void> close() {
    _courtsSubscription?.cancel();
    return super.close();
  }
}
