import 'package:equatable/equatable.dart';

abstract class HomeFilterEvent extends Equatable {
  const HomeFilterEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllCourts extends HomeFilterEvent {}

class SearchQueryChanged extends HomeFilterEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class SportFilterToggled extends HomeFilterEvent {
  final String? sport;
  const SportFilterToggled(this.sport);

  @override
  List<Object?> get props => [sport];
}

class FilterCriteriaApplied extends HomeFilterEvent {
  final String? sportType;
  final double? maxPrice;

  const FilterCriteriaApplied({this.sportType, this.maxPrice});

  @override
  List<Object?> get props => [sportType, maxPrice];
}

class FilterCriteriaReset extends HomeFilterEvent {}
