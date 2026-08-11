import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

/// VCard item representing a badminton court for selection.
class CourtCardItem extends StatelessWidget {
  final String courtName;
  final double pricePerHour;
  final bool isAvailable;
  final VoidCallback onSelect;

  const CourtCardItem({
    super.key,
    required this.courtName,
    required this.pricePerHour,
    required this.isAvailable,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return VCard(
      title: courtName,
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAvailable
              ? VColors.statusSuccessSubdued
              : VColors.statusCriticalSubdued,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isAvailable ? 'Còn trống' : 'Đã đặt',
          style: VTypography.caption.copyWith(
            color: isAvailable
                ? VColors.statusSuccess
                : VColors.statusCritical,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${pricePerHour.toInt()} VNĐ / giờ',
            style: VTypography.headingSm.copyWith(
              color: VColors.brandPrimary,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: isAvailable ? onSelect : null,
            child: const Text('Chọn Sân'),
          ),
        ],
      ),
    );
  }
}
