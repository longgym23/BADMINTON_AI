import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum FilterMode { all, dateRange, month, year, last7Days }

mixin FilterableViewModelMixin on ChangeNotifier {
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
        return 'Tất cả';
      case FilterMode.dateRange:
        if (_selectedDateRange != null) {
          final fmt = DateFormat('dd/MM/yy');
          return '${fmt.format(_selectedDateRange!.start)} - ${fmt.format(_selectedDateRange!.end)}';
        }
        return 'Khoảng ngày';
      case FilterMode.month:
        if (_selectedMonth != null && _selectedYear != null) {
          return 'Tháng $_selectedMonth/$_selectedYear';
        }
        return 'Theo tháng';
      case FilterMode.year:
        if (_selectedYear != null) return 'Năm $_selectedYear';
        return 'Theo năm';
      case FilterMode.last7Days:
        return '7 ngày gần đây';
    }
  }

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

  void setFilterLast7Days() {
    _filterMode = FilterMode.last7Days;
    _selectedDateRange = null;
    _selectedMonth = null;
    _selectedYear = null;
    notifyListeners();
  }

  bool isDateInFilter(DateTime date) {
    switch (_filterMode) {
      case FilterMode.all:
        return true;
      case FilterMode.dateRange:
        if (_selectedDateRange == null) return true;
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        return !date.isBefore(start) && !date.isAfter(end);
      case FilterMode.month:
        if (_selectedMonth == null || _selectedYear == null) return true;
        return date.month == _selectedMonth && date.year == _selectedYear;
      case FilterMode.year:
        if (_selectedYear == null) return true;
        return date.year == _selectedYear;
      case FilterMode.last7Days:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return !date.isBefore(start) && !date.isAfter(end);
    }
  }
}
