import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:flutter/material.dart';

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn hình thức đặt',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Đặt lịch ngày trực quan
            _BookingOption(
              title: 'Đặt lịch ngày trực quan',
              description:
                  'Đặt lịch ngày khi khách chơi nhiều khung giờ, nhiều sân.',
              color: Colors.lightGreen[100]!,
              textColor: colors.primary,
              onTap: onVisualBooking,
            ),

            const SizedBox(height: 16),

            // Option 2: Đặt lịch sự kiện
            Stack(
              children: [
                _BookingOption(
                  title: 'Đặt lịch sự kiện',
                  description:
                      'Sự kiện giúp bạn chơi chung với người có cùng niềm đam mê, trình độ. Hay những giải đấu mang tính cạnh tranh cao, nâng cao trình độ do chủ sân tổ chức.',
                  color: Colors.pink[100]!,
                  textColor: Colors.purple[700]!,
                  onTap: onEventBooking,
                ),
                // Badge "New"
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
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

            const SizedBox(height: 20),
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
        padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
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

