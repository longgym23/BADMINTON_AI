import 'package:easy_localization/easy_localization.dart';

import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/design_system/patterns/filterable_viewmodel_mixin.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/components/booking_history/calendar_theme.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_date_range_picker_dialog.dart';
import 'package:flutter/material.dart';

class TimeFilterWidget<T extends FilterableViewModelMixin>
    extends StatelessWidget {
  final T viewModel;
const TimeFilterWidget({super.key, required this.viewModel});

  Future<void> _pickDateRange(BuildContext context) async {
    final result = await showCustomDateRangePicker(
      context: context,
      initialDateRange: viewModel.selectedDateRange,
      cancelLabel: 'common.cancel'.tr(),
      confirmLabel: 'common.confirm'.tr(),
    );

    if (result != null) {
      viewModel.setFilterDateRange(result);
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    int tempMonth = viewModel.selectedMonth ?? now.month;
    int tempYear = viewModel.selectedYear ?? now.year;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: BookingCalendarTheme.dialogShape,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          content: Material(
            color: Colors.transparent,
            child: SizedBox(
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
                          decoration: BookingCalendarTheme.gridItemDecoration(
                            selected: selected,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tháng $m',
                            style: BookingCalendarTheme.gridItemTextStyle(
                              selected: selected,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BookingCalendarTheme.cancelButton(
                    onPressed: () => Navigator.pop(ctx),
                    label: 'common.cancel'.tr(),
                  ),
                  const SizedBox(width: 16),
                  BookingCalendarTheme.confirmButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      viewModel.setFilterMonth(tempMonth, tempYear);
                    },
                    label: 'common.confirm'.tr(),
                  ),
                ],
              ),
            ),
          ],

        ),
      ),
    );
  }

  Future<void> _pickYear(BuildContext context) async {
    final now = DateTime.now();
    int tempYear = viewModel.selectedYear ?? now.year;
    int startYear = (tempYear ~/ 12) * 12;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: BookingCalendarTheme.dialogShape,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          content: Material(
            color: Colors.transparent,
            child: SizedBox(
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
                          decoration: BookingCalendarTheme.gridItemDecoration(
                            selected: selected,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$year',
                            style: BookingCalendarTheme.gridItemTextStyle(
                              selected: selected,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BookingCalendarTheme.cancelButton(
                    onPressed: () => Navigator.pop(ctx),
                    label: 'common.cancel'.tr(),
                  ),
                  const SizedBox(width: 16),
                  BookingCalendarTheme.confirmButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      viewModel.setFilterYear(tempYear);
                    },
                    label: 'common.confirm'.tr(),
                  ),
                ],
              ),
            ),
          ],

        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<int>(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 6,
        offset: const Offset(0, 45),
        onSelected: (value) {
          switch (value) {
            case 0:
              _pickDateRange(context);
              break;
            case 1:
              _pickMonth(context);
              break;
            case 2:
              _pickYear(context);
              break;
            case 3:
              viewModel.setFilterAll();
              break;
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem(context, 0, Icons.date_range, 'booking_history_screen.filterByDateRange'.tr()),
          _buildMenuItem(
            context,
            1,
            Icons.calendar_view_month,
            'booking_history_screen.filterByMonth'.tr(),
          ),
          _buildMenuItem(context, 2, Icons.calendar_today, 'booking_history_screen.filterByYear'.tr()),
          PopupMenuDivider(height: 1, color: Colors.grey[200]),
          _buildMenuItem(context, 3, Icons.list, 'booking_history_screen.viewAll'.tr()),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: VColors.brandPrimary.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: VColors.brandPrimary.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                viewModel.filterMode == FilterMode.all
                    ? 'booking_history_screen.viewAll'.tr()
                    : viewModel.filterLabel(context),
                style: const TextStyle(
                  color: VColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.tune, color: VColors.brandPrimary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildMenuItem(
    BuildContext context,
    int value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<int>(
      value: value,
      height: 48,
      child: Row(
        children: [
          Icon(icon, color: VColors.brandPrimary, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: VColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
