import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Shared calendar styles used across date range, month, and year pickers.
/// Centralizing styles ensures visual consistency and easy maintenance.
class BookingCalendarTheme {
  BookingCalendarTheme._();

  // ─── Dialog ──────────────────────────────────────────────────────────────

  static RoundedRectangleBorder get dialogShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  static const double dialogWidth = 280.0;

  // ─── Header ──────────────────────────────────────────────────────────────

  static HeaderStyle headerStyle({TextFormatter? formatter}) {
    return HeaderStyle(
      formatButtonVisible: false,
      titleCentered: true,
      leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.brandOrange),
      rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.brandOrange),
      titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleTextFormatter: formatter,
    );
  }

  // ─── Calendar cells ──────────────────────────────────────────────────────

  static CalendarStyle get calendarStyle => CalendarStyle(
        // Range highlight band behind cells
        rangeHighlightColor: Color(0x26FF6B00), // 15% opacity orange
        // Start date: full orange circle
        rangeStartDecoration: BoxDecoration(
          color: AppColors.brandOrange,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        rangeStartTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        // End date: full orange circle
        rangeEndDecoration: BoxDecoration(
          color: AppColors.brandOrange,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        rangeEndTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        // Dates between start and end: light orange rect
        withinRangeDecoration: BoxDecoration(
          color: Color(0x21FF6B00), // 13% opacity orange
        ),
        withinRangeTextStyle: TextStyle(
          color: AppColors.textBlack,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        // Today: orange border only
        todayDecoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.brandOrange, width: 1.5),
          ),
        ),
        todayTextStyle: TextStyle(
          color: AppColors.brandOrange,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        // Selected
        selectedDecoration: BoxDecoration(
          color: AppColors.brandOrange,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        // Override ALL other decorations to avoid BoxShape.circle conflict
        defaultDecoration: BoxDecoration(),
        weekendDecoration: BoxDecoration(),
        outsideDecoration: BoxDecoration(),
        disabledDecoration: BoxDecoration(),
        holidayDecoration: BoxDecoration(),
        markerDecoration: BoxDecoration(
          color: AppColors.brandOrange,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        // Text styles
        defaultTextStyle: TextStyle(color: Colors.black87, fontSize: 14),
        weekendTextStyle: TextStyle(color: Colors.black87, fontSize: 14),
        outsideTextStyle: TextStyle(color: Color(0xFFD0D0D0), fontSize: 14),
        disabledTextStyle: TextStyle(color: Color(0xFFBFBFBF), fontSize: 14),
        holidayTextStyle: TextStyle(color: AppColors.brandOrange, fontSize: 14),
        // Cell spacing
        cellMargin: EdgeInsets.all(2),
        cellPadding: EdgeInsets.zero,
        // Row decoration
        rowDecoration: BoxDecoration(),
      );

  static const DaysOfWeekStyle daysOfWeekStyle = DaysOfWeekStyle(
    weekdayStyle: TextStyle(color: Colors.grey, fontSize: 12),
    weekendStyle: TextStyle(color: Colors.grey, fontSize: 12),
  );

  // ─── Grid item (month / year tile) ───────────────────────────────────────

  static BoxDecoration gridItemDecoration({required bool selected}) {
    return BoxDecoration(
      color: selected ? AppColors.brandOrange : Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    );
  }

  static TextStyle gridItemTextStyle({required bool selected, double fontSize = 13}) {
    return TextStyle(
      color: selected ? Colors.white : AppColors.textBlack,
      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      fontSize: fontSize,
    );
  }

  // ─── Action buttons ──────────────────────────────────────────────────────

  static TextButton cancelButton({required VoidCallback onPressed, required String label}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textGrey,
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(label),
    );
  }

  static ElevatedButton confirmButton({required VoidCallback onPressed, required String label}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // ─── Year navigation header (shared between month & year pickers) ─────────

  static Widget yearNavigator({
    required String label,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.brandOrange),
          onPressed: onPrevious,
        ),
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          icon: Icon(Icons.chevron_right, color: AppColors.brandOrange),
          onPressed: onNext,
        ),
      ],
    );
  }
}
