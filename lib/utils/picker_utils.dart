import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badminton_ai/utils/app_colors.dart';

class PickerUtils {
  PickerUtils._();

  static const double _datePickerHeight = 320.0;
  static const double _timePickerHeight = 280.0;

  // ─── Date Picker ───────────────────────────────────────────────────────────

  /// Hiển thị Cupertino date picker dạng bottom sheet.
  ///
  /// Trả về [DateTime] được chọn hoặc `null` nếu người dùng bấm Hủy.
  ///
  /// - [initialDate]: ngày hiển thị ban đầu (mặc định: hôm nay)
  /// - [minimumDate]: ngày nhỏ nhất có thể chọn
  /// - [maximumDate]: ngày lớn nhất có thể chọn
  /// - [minimumYear]: năm nhỏ nhất (dùng khi không set minimumDate)
  static Future<DateTime?> showDatePicker(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
    int minimumYear = 1900,
  }) async {
    final initial = initialDate ?? DateTime.now();
    // Đảm bảo initialDate nằm trong khoảng hợp lệ
    final safeInitial = _clamp(initial, minimumDate, maximumDate);

    DateTime temp = safeInitial;
    DateTime? result;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: _datePickerHeight,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            _buildToolbar(
              ctx,
              onCancel: () => Navigator.of(ctx).pop(),
              onDone: () {
                result = temp;
                Navigator.of(ctx).pop();
              },
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: safeInitial,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                minimumYear: minimumYear,
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  // ─── Time Picker ───────────────────────────────────────────────────────────

  /// Hiển thị Cupertino time picker (24h) dạng bottom sheet.
  ///
  /// Trả về chuỗi `"HH:mm"` khi người dùng xác nhận,
  /// hoặc `null` nếu bấm Hủy.
  ///
  /// - [initialTime]: chuỗi `"HH:mm"` làm giá trị ban đầu.
  ///   Nếu `null` hoặc sai format, dùng giờ hiện tại.
  static Future<String?> showTimePicker(
    BuildContext context, {
    String? initialTime,
  }) async {
    final initialDateTime = _parseTimeString(initialTime);
    DateTime temp = initialDateTime;
    String? result;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: _timePickerHeight,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            _buildToolbar(
              ctx,
              onCancel: () => Navigator.of(ctx).pop(),
              onDone: () {
                result =
                    '${temp.hour.toString().padLeft(2, '0')}:${temp.minute.toString().padLeft(2, '0')}';
                Navigator.of(ctx).pop();
              },
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  /// Hiển thị Cupertino time picker và trả về [TimeOfDay].
  ///
  /// Tiện dụng khi màn hình cần lưu [TimeOfDay] thay vì chuỗi.
  static Future<TimeOfDay?> showTimeOfDayPicker(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) async {
    final now = DateTime.now();
    final tod = initialTime ?? const TimeOfDay(hour: 8, minute: 0);
    final initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      tod.hour,
      tod.minute,
    );

    DateTime temp = initialDateTime;
    TimeOfDay? result;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: _timePickerHeight,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            _buildToolbar(
              ctx,
              onCancel: () => Navigator.of(ctx).pop(),
              onDone: () {
                result = TimeOfDay(hour: temp.hour, minute: temp.minute);
                Navigator.of(ctx).pop();
              },
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Toolbar chung (Hủy | tiêu đề | Xong) theo chuẩn Cupertino.
  static Widget _buildToolbar(
    BuildContext ctx, {
    required VoidCallback onCancel,
    required VoidCallback onDone,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          onPressed: onCancel,
          child: Text(
            'screens.cancel1'.tr(),
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
        CupertinoButton(
          onPressed: onDone,
          child: Text(
            'screens.done'.tr(),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Parse chuỗi "HH:mm" thành [DateTime] ngày hôm nay.
  static DateTime _parseTimeString(String? timeStr) {
    if (timeStr != null && timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }
    }
    return DateTime.now();
  }

  /// Clamp [date] trong khoảng [min, max].
  static DateTime _clamp(DateTime date, DateTime? min, DateTime? max) {
    if (min != null && date.isBefore(min)) return min;
    if (max != null && date.isAfter(max)) return max;
    return date;
  }
}
