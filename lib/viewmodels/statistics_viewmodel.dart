import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';

import 'package:badminton_ai/viewmodels/mixins/filterable_viewmodel_mixin.dart';

/// Extends BookingGroup to include sportType for chart grouping
class StatBookingGroup {
  final BookingModel base;
  int startSlot;
  int endSlot;
  int price;
  final String? sportType;

  StatBookingGroup({
    required this.base,
    required this.startSlot,
    required this.endSlot,
    required this.price,
    this.sportType,
  });
}

class StatisticsViewModel extends ChangeNotifier with FilterableViewModelMixin {
  final SupabaseRepository repo;
  final String userId;

  List<StatBookingGroup> _allGroups = [];
  List<StatBookingGroup> _filteredGroups = [];
  Map<String, CourtLocationModel> _courtMap = {};
  StreamSubscription? _bookingsSubscription;

  bool _isLoading = true;
  String? _error;

  StatisticsViewModel({required this.repo, required this.userId}) {
    _initData();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<StatBookingGroup> get filteredGroups => _filteredGroups;

  // Overriding mixin setter to trigger local filter application
  @override
  void setFilterAll() {
    super.setFilterAll();
    _applyFilter();
  }

  @override
  void setFilterDateRange(DateTimeRange range) {
    super.setFilterDateRange(range);
    _applyFilter();
  }

  @override
  void setFilterMonth(int month, int year) {
    super.setFilterMonth(month, year);
    _applyFilter();
  }

  @override
  void setFilterYear(int year) {
    super.setFilterYear(year);
    _applyFilter();
  }

  // Khởi tạo data
  Future<void> _initData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch courts
      final courtsStream = repo.getCourtLocationsStream();
      final courts = await courtsStream.first; 
      _courtMap = {for (var c in courts) c.id: c};

      // 2. Subscribe to user bookings stream for real-time updates
      _bookingsSubscription?.cancel();
      _bookingsSubscription = repo.getUserBookingHistoryStream(userId).listen(
        (bookings) {
          _allGroups = _groupBookings(bookings);
          _applyFilter();
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  void _applyFilter() {
    _filteredGroups = _allGroups.where((g) => isDateInFilter(g.base.date)).toList();
    notifyListeners();
  }

  int get totalSpend => _filteredGroups.fold(0, (sum, g) => sum + g.price);

  int get courtsBooked => _filteredGroups.length;

  // returns map of sportType -> number of orders
  Map<String, int> getSportTypeDistribution() {
    final map = <String, int>{};
    for (var g in _filteredGroups) {
      final sport = g.sportType ?? 'unknown';
      map[sport] = (map[sport] ?? 0) + 1;
    }
    return map;
  }

  List<StatBookingGroup> _groupBookings(List<BookingModel> bookings) {
    // Chỉ lấy confirmed/completed bookings (không lấy PENDING_PAYMENT, cancelled)
    final validBookings = bookings.where((b) => b.status != 'PENDING_PAYMENT' && b.status != 'cancelled').toList();

    final sorted = List<BookingModel>.from(validBookings)
      ..sort((a, b) {
        int cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        cmp = a.courtId.compareTo(b.courtId);
        if (cmp != 0) return cmp;
        cmp = a.courtNumber.compareTo(b.courtNumber);
        if (cmp != 0) return cmp;
        return a.timeSlot.compareTo(b.timeSlot);
      });

    final groups = <StatBookingGroup>[];
    for (final b in sorted) {
      final sportType = _courtMap[b.courtId]?.sportType?.toLowerCase() ?? 'unknown';
      
      if (groups.isEmpty) {
        groups.add(StatBookingGroup(base: b, startSlot: b.timeSlot, endSlot: b.timeSlot + 1, price: b.price, sportType: sportType));
        continue;
      }
      final last = groups.last;
      if (last.base.date == b.date &&
          last.base.courtId == b.courtId &&
          last.base.courtNumber == b.courtNumber &&
          last.endSlot == b.timeSlot) {
        last.endSlot = b.timeSlot + 1;
        last.price += b.price;
      } else {
        groups.add(StatBookingGroup(base: b, startSlot: b.timeSlot, endSlot: b.timeSlot + 1, price: b.price, sportType: sportType));
      }
    }

    groups.sort((a, b) {
      final dateA = DateTime(a.base.date.year, a.base.date.month, a.base.date.day, a.startSlot);
      final dateB = DateTime(b.base.date.year, b.base.date.month, b.base.date.day, b.startSlot);
      return dateB.compareTo(dateA);
    });

    return groups;
  }
}
