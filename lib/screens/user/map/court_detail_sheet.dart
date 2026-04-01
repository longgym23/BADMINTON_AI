import 'dart:io';

import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/providers/favorite_courts_provider.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CourtDetailSheet extends StatefulWidget {
  final CourtLocationModel court;
  const CourtDetailSheet({super.key, required this.court});

  @override
  State<CourtDetailSheet> createState() => _CourtDetailSheetState();
}

class _CourtDetailSheetState extends State<CourtDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _sportLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'pickleball':
        return 'Pickleball';
      case 'football':
        return 'Bóng đá';
      case 'tennis':
        return 'Tennis';
      default:
        return 'Cầu lông';
    }
  }

  Color _sportColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'pickleball':
        return Colors.blue;
      case 'football':
        return Colors.orange;
      case 'tennis':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  Future<void> _launchDirections() async {
    final lat = widget.court.latitude;
    final lng = widget.court.longitude;
    final name = Uri.encodeComponent(widget.court.name);

    Uri? uri;
    if (Platform.isAndroid) {
      uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      if (!await canLaunchUrl(uri)) {
        uri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name');
      }
    } else {
      uri = Uri.parse(
          'https://maps.apple.com/?daddr=$lat,$lng&directionsmode=driving');
    }

    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _bookCourt() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourtSelectionScreen(
          selectedCourt: widget.court,
          selectedDate: DateTime.now(),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final court = widget.court;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          clipBehavior: Clip.antiAlias, // Cắt bỏ các phần nhô ra để bo góc ảnh
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // Header image + actions
                    SliverToBoxAdapter(child: _buildHeader(court)),

                    // Court summary info
                    SliverToBoxAdapter(child: _buildCourtInfo(court)),

                    // Tab bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyTabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textGrey,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'Thông tin'),
                            Tab(text: 'Dịch vụ'),
                            Tab(text: 'Hình ảnh'),
                            Tab(text: 'Đánh giá'),
                          ],
                        ),
                      ),
                    ),
                    
                    // The magically swapping active tab content
                    ..._buildActiveTabSlivers(context, court),
                  ],
                ),
              ),

              // ── Bottom CTA ───────────────────────────────────────────────
              _buildBookButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(CourtLocationModel court) {
    return Stack(
      children: [
        // Cover image
        SizedBox(
          height: 220,
          width: double.infinity,
          child: court.imageUrl != null && court.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: court.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _PlaceholderCover(),
                  errorWidget: (_, __, ___) => _PlaceholderCover(),
                )
              : _PlaceholderCover(),
        ),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top action buttons
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              // Back
              _ActionCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              // Directions
              _ActionCircleButton(
                icon: Icons.directions_rounded,
                onTap: _launchDirections,
              ),
              const SizedBox(width: 10),
              // Favorite
              Consumer<FavoriteCourtsProvider>(
                builder: (_, fav, __) {
                  final isFav = fav.isFavorite(court.id);
                  return _ActionCircleButton(
                    icon: isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: isFav ? Colors.red : Colors.white,
                    onTap: () {
                      fav.toggleFavorite(court);
                      final msg = isFav
                          ? 'Đã xóa khỏi yêu thích'
                          : 'Đã thêm vào yêu thích';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.textBlack,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Rating chip at bottom of image
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    court.rating > 0
                        ? '${court.rating.toStringAsFixed(1)} · ${court.totalReviews} đánh giá'
                        : 'Chưa có đánh giá',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourtInfo(CourtLocationModel court) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + sport chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  court.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _sportColor(court.sportType).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _sportColor(court.sportType).withOpacity(0.35)),
                ),
                child: Text(
                  _sportLabel(court.sportType),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _sportColor(court.sportType),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Address
          _InfoRow(
            icon: Icons.location_on_rounded,
            iconColor: Colors.red,
            text: court.address,
          ),
          const SizedBox(height: 8),

          // Open hours (placeholder – không có field trong model)
          _InfoRow(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primary,
            text: '05:00 – 23:00',
          ),
          const SizedBox(height: 8),

          // Available courts
          _InfoRow(
            customIcon: Image.asset(
              "assets/images/sports.png",
              color: Colors.blue,
              height: 20,
              width: 20,
            ),
            text: '${court.totalCourts} sân · Trống sân',
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _bookCourt,
            child: const Text(
              'Đặt sân ngay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveTabSlivers(BuildContext context, CourtLocationModel court) {
    switch (_tabController.index) {
      case 0:
        return _buildInfoTabSlivers(court);
      case 1:
        return _buildServicesTabSlivers(context);
      case 2:
        return _buildImagesTabSlivers(court);
      case 3:
      default:
        return _buildReviewsTabSlivers(court);
    }
  }

  List<Widget> _buildInfoTabSlivers(CourtLocationModel court) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _InfoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giá thuê',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatPrice(court.pricePerHour)}đ/giờ',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Số sân',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${court.totalCourts} sân',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Link đặt sân online',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textBlack),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Đặt sân qua ứng dụng · Hệ thống tự động xác nhận',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mô tả',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textBlack),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Sân chất lượng cao, hệ thống đèn chiếu sáng đầy đủ, bãi đậu xe rộng rãi. Phù hợp cho các buổi tập luyện và thi đấu.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    ];
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return price.toStringAsFixed(0);
  }

  List<Widget> _buildServicesTabSlivers(BuildContext context) {
    const services = [
      _ServiceItem(icon: Icons.local_parking_rounded, label: 'Bãi đỗ xe'),
      _ServiceItem(icon: Icons.shower_rounded, label: 'Phòng tắm'),
      _ServiceItem(icon: Icons.sports_rounded, label: 'Cho thuê vợt'),
      _ServiceItem(
          icon: Icons.local_drink_rounded, label: 'Nước uống / Căn tin'),
      _ServiceItem(icon: Icons.wifi_rounded, label: 'Wi-Fi miễn phí'),
    ];
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverToBoxAdapter(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: services
                .map(
                  (s) => Container(
                    width: (MediaQuery.of(context).size.width - 56) / 2,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.label,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildImagesTabSlivers(CourtLocationModel court) {
    final hasImage = court.imageUrl != null && court.imageUrl!.isNotEmpty;
    if (!hasImage) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text('Chưa có hình ảnh',
                style: TextStyle(color: AppColors.textGrey)),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: court.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.borderColor),
                errorWidget: (_, __, ___) => Container(color: AppColors.borderColor),
              ),
            ),
            childCount: 4,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildReviewsTabSlivers(CourtLocationModel court) {
    if (court.totalReviews == 0) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_rounded,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Chưa có đánh giá nào',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Hãy đặt sân và chia sẻ trải nghiệm của bạn!',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Row(
              children: [
                Text(
                  court.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < court.rating.floor()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${court.totalReviews} đánh giá',
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            const Center(
              child: Text(
                'Chi tiết đánh giá đang được cập nhật',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ]),
        ),
      ),
    ];
  }
} // End of _CourtDetailSheetState

// ── Helper Widgets ────────────────────────────────────────────────────────────


class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.42),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final Color? iconColor;
  final String text;

  const _InfoRow({
    this.icon,
    this.customIcon,
    this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customIcon ?? Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textGrey, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBg,
      child: Center(
        child: Icon(
          Icons.sports_tennis_rounded,
          size: 64,
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}

// Sticky TabBar delegate for CustomScrollView
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
        color: Colors.white,
        child: tabBar,
      );

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: child,
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String label;
  const _ServiceItem({required this.icon, required this.label});
}
