import 'package:equatable/equatable.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/filter_criteria.dart';

enum HomeFilterStatus { initial, loading, success, failure }

class HomeFilterState extends Equatable {
  final HomeFilterStatus status;
  final List<CourtLocationModel> allCourts;
  final List<CourtLocationModel> filteredCourts;
  final FilterCriteria filterCriteria;
  final String? errorMessage;

  HomeFilterState({
    this.status = HomeFilterStatus.initial,
    this.allCourts = const [],
    this.filteredCourts = const [],
    FilterCriteria? filterCriteria,
    this.errorMessage,
  }) : filterCriteria = filterCriteria ?? FilterCriteria();

  HomeFilterState copyWith({
    HomeFilterStatus? status,
    List<CourtLocationModel>? allCourts,
    List<CourtLocationModel>? filteredCourts,
    FilterCriteria? filterCriteria,
    String? errorMessage,
  }) {
    return HomeFilterState(
      status: status ?? this.status,
      allCourts: allCourts ?? this.allCourts,
      filteredCourts: filteredCourts ?? this.filteredCourts,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allCourts,
    filteredCourts,
    filterCriteria,
    errorMessage,
  ];
}
