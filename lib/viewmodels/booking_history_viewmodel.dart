import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/data/models/booking_model.dart';

/// Các chế độ lọc lịch sử đặt sân
enum FilterMode { all, dateRange, month, year }

/// Nhóm các slot liên tiếp của cùng 1 sân thành 1 booking hiển thị
class BookingGroup {
  final BookingModel base;
  int startSlot;
  int endSlot;
  int price;

  BookingGroup({
    required this.base,
    required this.startSlot,
    required this.endSlot,
    required this.price,
  });
}

class BookingHistoryViewModel extends ChangeNotifier {
  // ─── Filter state ──────────────────────────────────────────────────────────
  FilterMode _filterMode = FilterMode.all;
  DateTimeRange? _selectedDateRange;
  int? _selectedMonth;
  int? _selectedYear;

  FilterMode get filterMode => _filterMode;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  int? get selectedMonth => _selectedMonth;
  int? get selectedYear => _selectedYear;

  String filterLabel(BuildContext context) {
    switch (_filterMode) {
      case FilterMode.all:
        return 'Xem tất cả';
      case FilterMode.dateRange:
        if (_selectedDateRange != null) {
          final fmt = DateFormat('dd/MM');
          return '${fmt.format(_selectedDateRange!.start)} - ${fmt.format(_selectedDateRange!.end)}';
        }
        return 'Khoảng ngày';
      case FilterMode.month:
        if (_selectedMonth != null && _selectedYear != null) {
          return 'T$_selectedMonth/$_selectedYear';
        }
        return 'Theo tháng';
      case FilterMode.year:
        if (_selectedYear != null) return 'Năm $_selectedYear';
        return 'Theo năm';
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────
  void setFilterAll() {
    _filterMode = FilterMode.all;
    _selectedDateRange = null;
    _selectedMonth = null;
    _selectedYear = null;
    notifyListeners();
  }

  void setFilterDateRange(DateTimeRange range) {
    _filterMode = FilterMode.dateRange;
    _selectedDateRange = range;
    notifyListeners();
  }

  void setFilterMonth(int month, int year) {
    _filterMode = FilterMode.month;
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  void setFilterYear(int year) {
    _filterMode = FilterMode.year;
    _selectedYear = year;
    notifyListeners();
  }

  // ─── Business logic ────────────────────────────────────────────────────────

  /// Nhóm các booking riêng lẻ thành các nhóm slot liên tiếp
  List<BookingGroup> groupBookings(List<BookingModel> bookings) {
    final sorted = List<BookingModel>.from(bookings)
      ..sort((a, b) {
        int cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        cmp = a.courtId.compareTo(b.courtId);
        if (cmp != 0) return cmp;
        cmp = a.courtNumber.compareTo(b.courtNumber);
        if (cmp != 0) return cmp;
        return a.timeSlot.compareTo(b.timeSlot);
      });

    final groups = <BookingGroup>[];
    for (final b in sorted) {
      if (groups.isEmpty) {
        groups.add(BookingGroup(base: b, startSlot: b.timeSlot, endSlot: b.timeSlot + 1, price: b.price));
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
        groups.add(BookingGroup(base: b, startSlot: b.timeSlot, endSlot: b.timeSlot + 1, price: b.price));
      }
    }

    // Sắp xếp theo ngày mới nhất trước
    groups.sort((a, b) {
      final dateA = DateTime(a.base.date.year, a.base.date.month, a.base.date.day, a.startSlot);
      final dateB = DateTime(b.base.date.year, b.base.date.month, b.base.date.day, b.startSlot);
      return dateB.compareTo(dateA);
    });

    return groups;
  }

  /// Lọc danh sách groups theo filter hiện tại
  List<BookingGroup> applyFilter(List<BookingGroup> groups) {
    switch (_filterMode) {
      case FilterMode.all:
        return groups;
      case FilterMode.dateRange:
        if (_selectedDateRange == null) return groups;
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end;
        return groups.where((g) {
          final d = g.base.date;
          return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
              !d.isAfter(DateTime(end.year, end.month, end.day));
        }).toList();
      case FilterMode.month:
        if (_selectedMonth == null || _selectedYear == null) return groups;
        return groups
            .where((g) => g.base.date.month == _selectedMonth && g.base.date.year == _selectedYear)
            .toList();
      case FilterMode.year:
        if (_selectedYear == null) return groups;
        return groups.where((g) => g.base.date.year == _selectedYear).toList();
    }
  }

  /// Tổng tiền từ danh sách groups đã lọc
  int calculateTotalSpend(List<BookingGroup> filtered) =>
      filtered.fold(0, (sum, g) => sum + g.price);
}
