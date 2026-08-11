import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/components/booking_history/calendar_theme.dart';

Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  String cancelLabel = 'Huỷ',
  String confirmLabel = 'Xác nhận',
}) async {
  DateTime? tempStart = initialDateRange?.start;
  DateTime? tempEnd = initialDateRange?.end;
  DateTime focusedDay = tempStart ?? DateTime.now();

  return await showDialog<DateTimeRange>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          shape: BookingCalendarTheme.dialogShape,
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          content: SizedBox(
            width: BookingCalendarTheme.dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TableCalendar(
                  focusedDay: focusedDay,
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  rangeStartDay: tempStart,
                  rangeEndDay: tempEnd,
                  rangeSelectionMode: RangeSelectionMode.enforced,
                  onRangeSelected: (start, end, focused) {
                    setState(() {
                      tempStart = start;
                      tempEnd = end;
                      focusedDay = focused;
                    });
                  },
                  locale: 'vi_VN',
                  headerStyle: BookingCalendarTheme.headerStyle(
                    formatter: (date, locale) => 'Tháng ${date.month}, ${date.year}',
                  ),
                  calendarStyle: BookingCalendarTheme.calendarStyle,
                  daysOfWeekStyle: BookingCalendarTheme.daysOfWeekStyle,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BookingCalendarTheme.cancelButton(
                      onPressed: () => Navigator.pop(ctx), 
                      label: cancelLabel
                    ),
                    const SizedBox(width: 16),
                    BookingCalendarTheme.confirmButton(
                      onPressed: () {
                        if (tempStart != null) {
                          Navigator.pop(ctx, DateTimeRange(start: tempStart!, end: tempEnd ?? tempStart!));
                        } else {
                          Navigator.pop(ctx);
                        }
                      }, 
                      label: confirmLabel
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
