import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FilterCriteria {
  String? searchQuery;
  String? sportType;
  double? maxPrice;
  List<String> amenities;
  
  // New fields for advanced search
  String? scheduleType; // 'empty', 'event', 'team'
  DateTimeRange? dateRange;
  TimeOfDay? timeStart;
  TimeOfDay? timeEnd;
  String? eventTimeFilter; // 'today', '3days', '1week', '2weeks', '1month'
  double? distance;

  FilterCriteria({
    this.searchQuery,
    this.sportType,
    this.maxPrice,
    this.amenities = const [],
    this.scheduleType,
    this.dateRange,
    this.timeStart,
    this.timeEnd,
    this.eventTimeFilter,
    this.distance,
  });

  bool get hasFilters =>
      (searchQuery?.isNotEmpty ?? false) ||
      sportType != null ||
      maxPrice != null ||
      amenities.isNotEmpty ||
      scheduleType != null ||
      distance != null;

  FilterCriteria copyWith({
    String? searchQuery,
    String? sportType,
    bool clearSportType = false,
    double? maxPrice,
    List<String>? amenities,
    String? scheduleType,
    DateTimeRange? dateRange,
    TimeOfDay? timeStart,
    TimeOfDay? timeEnd,
    String? eventTimeFilter,
    double? distance,
  }) {
    return FilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      sportType: clearSportType ? null : (sportType ?? this.sportType),
      maxPrice: maxPrice ?? this.maxPrice,
      amenities: amenities ?? this.amenities,
      scheduleType: scheduleType ?? this.scheduleType,
      dateRange: dateRange ?? this.dateRange,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      eventTimeFilter: eventTimeFilter ?? this.eventTimeFilter,
      distance: distance ?? this.distance,
    );
  }
}
