import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/court_reviews_screen.dart';

class CourtListItem extends StatelessWidget {
  final CourtLocationModel court;
  final double distance;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const CourtListItem({
    super.key,
    required this.court,
    required this.distance,
    required this.onTap,
    required this.onDirections,
  });

  String _getDefaultSportImageUrl(String? sportType) {
    final type = sportType?.toLowerCase() ?? '';
    if (type.contains('pickleball')) {
      return 'https://olqwfnlycbtrcpywnvvf.supabase.co/storage/v1/object/public/court_images/pickleball-wallpaper-3-1759779191.png';
    } else if (type.contains('football') || type.contains('soccer') || type.contains('bóng đá') || type.contains('bong da')) {
      return 'https://olqwfnlycbtrcpywnvvf.supabase.co/storage/v1/object/public/court_images/hinh-nen-san-bong-da-dep-1.jpeg';
    } else if (type.contains('tennis')) {
      return 'https://olqwfnlycbtrcpywnvvf.supabase.co/storage/v1/object/public/court_images/san-tennis.jpg';
    } else {
      return 'https://olqwfnlycbtrcpywnvvf.supabase.co/storage/v1/object/public/court_images/pngtree-badminton-court-green-leisure-badminton-photo-image_9614702.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: VCard(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        backgroundColor: VColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(),
                  const VGap.xs(),
                  _buildRatingAndDistance(context),
                  const VGap.md(),
                  _buildFullWidthButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final fallbackUrl = _getDefaultSportImageUrl(court.sportType);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: court.imageUrl != null && court.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: court.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    imageUrl: fallbackUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: fallbackUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: VColors.statusSuccessSubdued,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: VColors.statusSuccess),
                const VGap(4),
                Text(
                  'home_tab.emptyCourt'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: VColors.statusSuccess,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  court.name,
                  style: VTypography.headingMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const VGap(6),
              const Icon(Icons.verified, size: 16, color: VColors.brandPrimary),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(court.pricePerHour),
          style: VTypography.headingMd.copyWith(color: VColors.brandPrimaryDark),
        ),
      ],
    );
  }

  Widget _buildRatingAndDistance(BuildContext context) {
    final rating = court.rating > 0 ? court.rating : 4.8;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourtReviewsScreen(court: court))),
          child: Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const VGap(4),
              Text(rating.toStringAsFixed(1), style: VTypography.bodySm.copyWith(fontWeight: FontWeight.bold)),
              const Icon(Icons.chevron_right, size: 16, color: VColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Text('•', style: TextStyle(color: VColors.textSubdued)),
        const SizedBox(width: 8),
        const Icon(Icons.location_on, size: 14, color: VColors.textSecondary),
        const SizedBox(width: 4),
        Text('${distance.toStringAsFixed(1)} km', style: VTypography.bodySm),
        const SizedBox(width: 8),
        const Text('•', style: TextStyle(color: VColors.textSubdued)),
        const SizedBox(width: 8),
        Text('${court.totalCourts} ${'home_tab.courts'.tr()}', style: VTypography.bodySm),
      ],
    );
  }

  Widget _buildFullWidthButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: VColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'home_tab.bookNow'.tr(),
              style: VTypography.headingSm.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: VColors.brandPrimarySubdued,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onDirections,
            icon: const Icon(Icons.directions, color: VColors.brandPrimary),
            tooltip: 'home_tab.directions'.tr(),
          ),
        ),
      ],
    );
  }
}
