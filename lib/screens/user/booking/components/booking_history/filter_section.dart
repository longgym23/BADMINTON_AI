import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/viewmodels/booking_history_viewmodel.dart';
import 'package:badminton_ai/screens/user/booking/components/booking_history/calendar_theme.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Popup filter button that opens date-range / month / year pickers.
class FilterRow extends StatelessWidget {
  final BookingHistoryViewModel vm;
  final AppLocalizations l;

  const FilterRow({super.key, required this.vm, required this.l});

  // ─── Date Range Picker ─────────────────────────────────────────────────

  Future<void> _pickDateRange(BuildContext context) async {
    DateTime? tempStart = vm.selectedDateRange?.start;
    DateTime? tempEnd = vm.selectedDateRange?.end;
    DateTime focusedDay = tempStart ?? DateTime.now();

    final result = await showDialog<DateTimeRange>(
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
                  _DialogActions(
                    onCancel: () => Navigator.pop(ctx),
                    onConfirm: () {
                      if (tempStart != null) {
                        Navigator.pop(ctx, DateTimeRange(start: tempStart!, end: tempEnd ?? tempStart!));
                      } else {
                        Navigator.pop(ctx);
                      }
                    },
                    cancelLabel: l.cancel,
                    confirmLabel: l.confirm,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
      vm.setFilterDateRange(result);
    }
  }

  // ─── Month Picker ──────────────────────────────────────────────────────

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    int tempMonth = vm.selectedMonth ?? now.month;
    int tempYear = vm.selectedYear ?? now.year;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: BookingCalendarTheme.dialogShape,
          backgroundColor: Colors.white,
          content: SizedBox(
            width: BookingCalendarTheme.dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BookingCalendarTheme.yearNavigator(
                  label: '$tempYear',
                  onPrevious: () => setState(() => tempYear--),
                  onNext: () => setState(() => tempYear++),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final selected = m == tempMonth;
                    return GestureDetector(
                      onTap: () => setState(() => tempMonth = m),
                      child: Container(
                        decoration: BookingCalendarTheme.gridItemDecoration(selected: selected),
                        alignment: Alignment.center,
                        child: Text(
                          'Tháng $m',
                          style: BookingCalendarTheme.gridItemTextStyle(selected: selected),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            _DialogActions(
              onCancel: () => Navigator.pop(ctx),
              onConfirm: () {
                Navigator.pop(ctx);
                vm.setFilterMonth(tempMonth, tempYear);
              },
              cancelLabel: l.cancel,
              confirmLabel: l.confirm,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Year Picker ───────────────────────────────────────────────────────

  Future<void> _pickYear(BuildContext context) async {
    final now = DateTime.now();
    int tempYear = vm.selectedYear ?? now.year;
    int startYear = (tempYear ~/ 12) * 12;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: BookingCalendarTheme.dialogShape,
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          content: SizedBox(
            width: BookingCalendarTheme.dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BookingCalendarTheme.yearNavigator(
                  label: '$startYear - ${startYear + 11}',
                  onPrevious: () => setState(() => startYear -= 12),
                  onNext: () => setState(() => startYear += 12),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: List.generate(12, (i) {
                    final year = startYear + i;
                    final selected = year == tempYear;
                    return GestureDetector(
                      onTap: () => setState(() => tempYear = year),
                      child: Container(
                        decoration: BookingCalendarTheme.gridItemDecoration(selected: selected),
                        alignment: Alignment.center,
                        child: Text(
                          '$year',
                          style: BookingCalendarTheme.gridItemTextStyle(selected: selected, fontSize: 14),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DialogActions(
                onCancel: () => Navigator.pop(ctx),
                onConfirm: () {
                  Navigator.pop(ctx);
                  vm.setFilterYear(tempYear);
                },
                cancelLabel: l.cancel,
                confirmLabel: l.confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<int>(
        color: AppColors.brandOrange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 4,
        offset: const Offset(0, 45),
        onSelected: (value) {
          switch (value) {
            case 0:
              _pickDateRange(context);
            case 1:
              _pickMonth(context);
            case 2:
              _pickYear(context);
            case 3:
              vm.setFilterAll();
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem(0, l.filterByDateRange),
          _buildMenuItem(1, l.filterByMonth),
          _buildMenuItem(2, l.filterByYear),
          _buildMenuItem(3, l.viewAll),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.brandOrange),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vm.filterMode == FilterMode.all ? l.viewAll : vm.filterLabel(context),
                style: const TextStyle(
                  color: Color.fromARGB(255, 108, 108, 108),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_month, color: AppColors.brandOrange, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildMenuItem(int value, String text) {
    return PopupMenuItem<int>(
      value: value,
      height: 40,
      padding: EdgeInsets.zero,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color.fromARGB(255, 248, 255, 252),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Shared dialog action row ────────────────────────────────────────────────

class _DialogActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String cancelLabel;
  final String confirmLabel;

  const _DialogActions({
    required this.onCancel,
    required this.onConfirm,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        BookingCalendarTheme.cancelButton(onPressed: onCancel, label: cancelLabel),
        const SizedBox(width: 16),
        BookingCalendarTheme.confirmButton(onPressed: onConfirm, label: confirmLabel),
      ],
    );
  }
}
