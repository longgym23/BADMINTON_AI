import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';

enum FilterMode { all, dateRange, month, year }

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

class StatisticsViewModel extends ChangeNotifier {
  final SupabaseRepository repo;
  final String userId;

  List<StatBookingGroup> _allGroups = [];
  List<StatBookingGroup> _filteredGroups = [];
  Map<String, CourtLocationModel> _courtMap = {};

  bool _isLoading = true;
  String? _error;

  // Filter state
  FilterMode _filterMode = FilterMode.all;
  DateTimeRange? _selectedDateRange;
  int? _selectedMonth;
  int? _selectedYear;

  StatisticsViewModel({required this.repo, required this.userId}) {
    _initData();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<StatBookingGroup> get filteredGroups => _filteredGroups;

  FilterMode get filterMode => _filterMode;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  int? get selectedMonth => _selectedMonth;
  int? get selectedYear => _selectedYear;

  // Helper cho text hiển thị của filter
  String filterLabel(BuildContext context, String allLabel, String dateLabel, String monthLabel, String yearLabel) {
    switch (_filterMode) {
      case FilterMode.all:
        return allLabel;
      case FilterMode.dateRange:
        if (_selectedDateRange != null) {
          final fmt = DateFormat('dd/MM');
          return '${fmt.format(_selectedDateRange!.start)} - ${fmt.format(_selectedDateRange!.end)}';
        }
        return dateLabel;
      case FilterMode.month:
        if (_selectedMonth != null && _selectedYear != null) {
          return 'T$_selectedMonth/$_selectedYear';
        }
        return monthLabel;
      case FilterMode.year:
        if (_selectedYear != null) return 'Năm $_selectedYear';
        return yearLabel;
    }
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

      // 2. Fetch user bookings
      final bookingsStream = repo.getUserBookingHistoryStream(userId);
      final bookings = await bookingsStream.first;
      
      _allGroups = _groupBookings(bookings);
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterAll() {
    _filterMode = FilterMode.all;
    _selectedDateRange = null;
    _selectedMonth = null;
    _selectedYear = null;
    _applyFilter();
  }

  void setFilterDateRange(DateTimeRange range) {
    _filterMode = FilterMode.dateRange;
    _selectedDateRange = range;
    _applyFilter();
  }

  void setFilterMonth(int month, int year) {
    _filterMode = FilterMode.month;
    _selectedMonth = month;
    _selectedYear = year;
    _applyFilter();
  }

  void setFilterYear(int year) {
    _filterMode = FilterMode.year;
    _selectedYear = year;
    _applyFilter();
  }

  void _applyFilter() {
    switch (_filterMode) {
      case FilterMode.all:
        _filteredGroups = _allGroups;
        break;
      case FilterMode.dateRange:
        if (_selectedDateRange == null) {
          _filteredGroups = _allGroups;
          break;
        }
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end;
        _filteredGroups = _allGroups.where((g) {
          final d = g.base.date;
          return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
                 !d.isAfter(DateTime(end.year, end.month, end.day));
        }).toList();
        break;
      case FilterMode.month:
        if (_selectedMonth == null || _selectedYear == null) {
           _filteredGroups = _allGroups;
           break;
        }
        _filteredGroups = _allGroups
            .where((g) => g.base.date.month == _selectedMonth && g.base.date.year == _selectedYear)
            .toList();
        break;
      case FilterMode.year:
        if (_selectedYear == null) {
          _filteredGroups = _allGroups; 
          break;
        }
        _filteredGroups = _allGroups.where((g) => g.base.date.year == _selectedYear).toList();
        break;
    }
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
