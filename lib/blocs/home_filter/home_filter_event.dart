import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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
  final String? scheduleType;
  final DateTimeRange? dateRange;
  final TimeOfDay? timeStart;
  final TimeOfDay? timeEnd;
  final String? eventTimeFilter;
  final double? distance;

  const FilterCriteriaApplied({
    this.sportType,
    this.maxPrice,
    this.scheduleType,
    this.dateRange,
    this.timeStart,
    this.timeEnd,
    this.eventTimeFilter,
    this.distance,
  });

  @override
  List<Object?> get props => [
        sportType,
        maxPrice,
        scheduleType,
        dateRange,
        timeStart,
        timeEnd,
        eventTimeFilter,
        distance,
      ];
}

class FilterCriteriaReset extends HomeFilterEvent {}
