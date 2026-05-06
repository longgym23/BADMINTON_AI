import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BookingMethodModal extends StatelessWidget {
  final CourtLocationModel court;
  final VoidCallback onVisualBooking;
  final VoidCallback onEventBooking;

  const BookingMethodModal({
    super.key,
    required this.court,
    required this.onVisualBooking,
    required this.onEventBooking,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'screens.chooseTheOrderForm'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Option 1: Đặt lịch ngày trực quan
            _BookingOption(
              title: 'screens.setTheDateIntuitively'.tr(),
              description:
                  'screens.setAScheduleForDaysWhenG'.tr(),
              color: Colors.lightGreen[100]!,
              textColor: colors.primary,
              onTap: onVisualBooking,
            ),

            SizedBox(height: 16),

            // Option 2: Đặt lịch sự kiện
            Stack(
              children: [
                _BookingOption(
                  title: 'screens.scheduleAnEvent'.tr(),
                  description:
                      'screens.theEventHelpsYouPlayWith'.tr(),
                  color: Colors.pink[100]!,
                  textColor: Colors.purple[700]!,
                  onTap: onEventBooking,
                ),
                // Badge "New"
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BookingOption extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _BookingOption({
    required this.title,
    required this.description,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: textColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


