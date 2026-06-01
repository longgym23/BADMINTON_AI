import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/viewmodels/mixins/filterable_viewmodel_mixin.dart';
import 'package:flutter/material.dart';

class AdminDashboardViewModel extends ChangeNotifier with FilterableViewModelMixin {
  final SupabaseRepository repo;
  final AppAuthProvider auth;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => _bookings;

  int _totalRevenue = 0;
  int get totalRevenue => _totalRevenue;

  int _totalBookingsCount = 0;
  int get totalBookingsCount => _totalBookingsCount;

  List<Map<String, dynamic>> _courtsList = [];
  List<Map<String, dynamic>> get courtsList => _courtsList;

  String? _selectedCourtId;
  String? get selectedCourtId => _selectedCourtId;

  Map<String, String> _userNames = {};
  Map<String, String> get userNames => _userNames;

  int _totalUsersCount = 0;
  int get totalUsersCount => _totalUsersCount;

  int _activeCourtsCount = 0;
  int get activeCourtsCount => _activeCourtsCount;

  AdminDashboardViewModel({required this.repo, required this.auth});

  void setSelectedCourtId(String? id) {
    _selectedCourtId = id;
    fetchDashboardData();
  }

  Future<void> fetchCourts() async {
    final user = auth.userModel;
    if (user == null) return;
    
    final isOwner = user.role == 'court_owner';
    final courts = await repo.getSimpleCourtsList(
      ownerId: isOwner ? user.id : null,
    );
    _courtsList = courts;
    _activeCourtsCount = courts.length;
    notifyListeners();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    final user = auth.userModel;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final isOwner = user.role == 'court_owner';
    final filterOwnerId = isOwner ? user.id : null;

    DateTime start, end;
    final now = DateTime.now();

    switch (filterMode) {
      case FilterMode.dateRange:
        if (selectedDateRange != null) {
          start = selectedDateRange!.start;
          end = selectedDateRange!.end;
        } else {
          end = now;
          start = end.subtract(const Duration(days: 6));
        }
        break;
      case FilterMode.month:
        if (selectedMonth != null && selectedYear != null) {
          start = DateTime(selectedYear!, selectedMonth!, 1);
          end = DateTime(selectedYear!, selectedMonth! + 1, 0);
        } else {
          end = now;
          start = end.subtract(const Duration(days: 6));
        }
        break;
      case FilterMode.year:
        if (selectedYear != null) {
          start = DateTime(selectedYear!, 1, 1);
          end = DateTime(selectedYear!, 12, 31);
        } else {
          end = now;
          start = end.subtract(const Duration(days: 6));
        }
        break;
      case FilterMode.last7Days:
        end = now;
        start = end.subtract(const Duration(days: 6));
        break;
      case FilterMode.all:
        start = DateTime(2000); // effectively all
        end = now;
        break;
      default:
        end = now;
        start = end.subtract(const Duration(days: 6));
        break;
    }

    try {
      // 1. Fetch Courts if empty
      if (_courtsList.isEmpty) {
        final courts = await repo.getSimpleCourtsList(
          ownerId: filterOwnerId,
        );
        _courtsList = courts;
      }
      _activeCourtsCount = _courtsList.length;

      // 2. Fetch Users cache if empty
      if (_userNames.isEmpty) {
        final users = await repo.getUsers();
        _userNames = {
          for (var u in users) u.id: u.displayName ?? (u.email != null ? u.email!.split('@')[0] : 'Khách')
        };
        _totalUsersCount = users.where((u) => u.role != 'admin').length;
      }

      // 3. Fetch Bookings
      final fetchedBookings = await repo.getBookingsForDateRange(
        start,
        end,
        ownerId: filterOwnerId,
        courtId: _selectedCourtId,
      );

      final validStates = ['PAID', 'confirmed', 'completed'];

      final validList = fetchedBookings.where((b) {
        final status = b.status.toUpperCase();
        return validStates.contains(status);
      }).toList();

      int rev = 0;
      for (var b in validList) {
        rev += b.price;
      }

      _bookings = fetchedBookings;
      _totalBookingsCount = validList.length;
      _totalRevenue = rev;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi fetch dashboard: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  // Override to trigger fetch on filter change
  @override
  void setFilterAll() {
    super.setFilterAll();
    fetchDashboardData();
  }

  @override
  void setFilterDateRange(DateTimeRange range) {
    super.setFilterDateRange(range);
    fetchDashboardData();
  }

  @override
  void setFilterMonth(int month, int year) {
    super.setFilterMonth(month, year);
    fetchDashboardData();
  }

  @override
  void setFilterYear(int year) {
    super.setFilterYear(year);
    fetchDashboardData();
  }

  @override
  void setFilterLast7Days() {
    super.setFilterLast7Days();
    fetchDashboardData();
  }
}
