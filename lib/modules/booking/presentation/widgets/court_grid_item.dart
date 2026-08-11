import 'package:flutter/material.dart';

class CourtGridItem extends StatelessWidget {
  final int courtNumber;
  final bool isBooked;
  final bool isSelected; // <-- THAM SỐ CÒN THIẾU
  final VoidCallback onTap;

  const CourtGridItem({
    super.key,
    required this.courtNumber,
    required this.isBooked,
    required this.isSelected, // <-- THAM SỐ CÒN THIẾU
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Xác định màu sắc
    Color backgroundColor;
    Color foregroundColor;

    if (isBooked) {
      backgroundColor = Colors.grey.shade600; // Sân đã đặt: Màu xám
      foregroundColor = Colors.white;
    } else if (isSelected) {
      backgroundColor = colors.primary; // Sân đang chọn: Màu chính (vàng)
      foregroundColor = colors.onPrimary; // Chữ trên nền vàng (xanh đậm)
    } else {
      backgroundColor = Colors.green.shade600; // Sân còn trống: Màu xanh
      foregroundColor = Colors.white;
    }

    return GestureDetector(
      onTap: isBooked ? null : onTap, // Không cho phép nhấn nếu đã đặt
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colors.primary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sân $courtNumber',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBooked ? 'Đã đặt' : (isSelected ? 'Đang chọn' : 'Còn trống'),
                style: TextStyle(
                  fontSize: 14,
                  color: foregroundColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

