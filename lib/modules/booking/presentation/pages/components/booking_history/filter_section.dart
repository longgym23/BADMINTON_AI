import 'package:easy_localization/easy_localization.dart';

import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/booking/presentation/viewmodels/booking_history_viewmodel.dart';
import 'package:badminton_ai/core/design_system/patterns/filterable_viewmodel_mixin.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/components/booking_history/calendar_theme.dart';
import 'package:flutter/material.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_date_range_picker_dialog.dart';

/// Popup filter button that opens date-range / month / year pickers.
class FilterRow extends StatelessWidget {
  final BookingHistoryViewModel vm;
const FilterRow({super.key, required this.vm});

  // ─── Date Range Picker ─────────────────────────────────────────────────

  Future<void> _pickDateRange(BuildContext context) async {
    final result = await showCustomDateRangePicker(
      context: context,
      initialDateRange: vm.selectedDateRange,
      cancelLabel: 'common.cancel'.tr(),
      confirmLabel: 'common.confirm'.tr(),
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
          surfaceTintColor: Colors.transparent,
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
                SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
              cancelLabel: 'common.cancel'.tr(),
              confirmLabel: 'common.confirm'.tr(),
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
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _DialogActions(
                onCancel: () => Navigator.pop(ctx),
                onConfirm: () {
                  Navigator.pop(ctx);
                  vm.setFilterYear(tempYear);
                },
                cancelLabel: 'common.cancel'.tr(),
                confirmLabel: 'common.confirm'.tr(),
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
        color: VColors.brandPrimary,
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
          _buildMenuItem(0, 'booking_history_screen.filterByDateRange'.tr()),
          _buildMenuItem(1, 'booking_history_screen.filterByMonth'.tr()),
          _buildMenuItem(2, 'booking_history_screen.filterByYear'.tr()),
          _buildMenuItem(3, 'booking_history_screen.viewAll'.tr()),
        ],
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: VColors.brandPrimary),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vm.filterMode == FilterMode.all ? 'booking_history_screen.viewAll'.tr() : vm.filterLabel(context),
                style: TextStyle(
                  color: Color.fromARGB(255, 108, 108, 108),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.calendar_month, color: VColors.brandPrimary, size: 16),
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
          style: TextStyle(
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
        BookingCalendarTheme.cancelButton(
          onPressed: onCancel,
          label: 'common.cancel'.tr(),
        ),
        SizedBox(width: 16),
        BookingCalendarTheme.confirmButton(
          onPressed: onConfirm,
          label: 'common.confirm'.tr(),
        ),
      ],
    );
  }
}
