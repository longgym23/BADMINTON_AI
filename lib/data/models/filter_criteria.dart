class FilterCriteria {
  String? searchQuery;
  String? sportType;
  double? maxPrice;
  List<String> amenities;

  FilterCriteria({
    this.searchQuery,
    this.sportType,
    this.maxPrice,
    this.amenities = const [],
  });

  bool get hasFilters =>
      (searchQuery?.isNotEmpty ?? false) ||
      sportType != null ||
      maxPrice != null ||
      amenities.isNotEmpty;

  FilterCriteria copyWith({
    String? searchQuery,
    String? sportType,
    bool clearSportType = false,
    double? maxPrice,
    List<String>? amenities,
  }) {
    return FilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      sportType: clearSportType ? null : (sportType ?? this.sportType),
      maxPrice: maxPrice ?? this.maxPrice,
      amenities: amenities ?? this.amenities,
    );
  }
}
