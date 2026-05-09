import 'package:flutter/material.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/viewmodels/mixins/filterable_viewmodel_mixin.dart';

class ManageBookingsViewModel extends ChangeNotifier with FilterableViewModelMixin {
  final List<BookingModel> _bookings = [];
  bool _isLoading = false;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  List<BookingModel> applyFilter(List<BookingModel> allBookings) {
    return allBookings.where((b) => isDateInFilter(b.date)).toList();
  }

  // Sắp xếp booking theo ngày và giờ (mới nhất lên trên)
  List<BookingModel> sortBookings(List<BookingModel> list) {
    return List<BookingModel>.from(list)
      ..sort((a, b) {
        final dateA = DateTime(a.date.year, a.date.month, a.date.day, a.timeSlot);
        final dateB = DateTime(b.date.year, b.date.month, b.date.day, b.timeSlot);
        return dateB.compareTo(dateA);
      });
  }

  int calculateTotalRevenue(List<BookingModel> filtered) {
    return filtered.fold(0, (sum, b) => sum + b.price);
  }
}
