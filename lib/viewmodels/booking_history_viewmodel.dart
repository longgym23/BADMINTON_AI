import 'package:flutter/material.dart';
import 'package:badminton_ai/data/models/booking_model.dart';

import 'package:badminton_ai/viewmodels/mixins/filterable_viewmodel_mixin.dart';

class BookingGroup {
  final BookingModel base;
  final List<BookingModel> items;
  int startSlot;
  int endSlot;
  int price;

  BookingGroup({
    required this.base,
    required this.items,
    required this.startSlot,
    required this.endSlot,
    required this.price,
  });
}

class BookingHistoryViewModel extends ChangeNotifier with FilterableViewModelMixin {
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
        groups.add(BookingGroup(base: b, items: [b], startSlot: b.timeSlot, endSlot: b.timeSlot + 1, price: b.price));
        continue;
      }
      final last = groups.last;
      if (last.base.date == b.date &&
          last.base.courtId == b.courtId &&
          last.base.courtNumber == b.courtNumber &&
          last.endSlot == b.timeSlot) {
        last.endSlot = b.timeSlot + 1;
        last.price += b.price;
        last.items.add(b);
      } else {
        groups.add(BookingGroup(base: b, items: [b], startSlot: b.timeSlot, endSlot: b.timeSlot + 1, price: b.price));
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
    return groups.where((g) => isDateInFilter(g.base.date)).toList();
  }

  /// Tổng tiền từ danh sách groups đã lọc
  int calculateTotalSpend(List<BookingGroup> filtered) =>
      filtered.fold(0, (sum, g) => sum + g.price);
}
