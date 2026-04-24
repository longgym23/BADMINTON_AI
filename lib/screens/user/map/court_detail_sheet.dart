import 'dart:io';

import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/review_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/favorite_courts_provider.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CourtDetailSheet extends StatefulWidget {
  final CourtLocationModel court;
  final VoidCallback? onClose;
  const CourtDetailSheet({super.key, required this.court, this.onClose});

  @override
  State<CourtDetailSheet> createState() => _CourtDetailSheetState();
}

class _CourtDetailSheetState extends State<CourtDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<ReviewModel>? _reviews;
  bool _loadingReviews = false;
  bool? _hasBooked;
  bool? _hasReviewed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
      // Load reviews khi chuyển sang tab Đánh giá
      if (_tabController.index == 3 && _reviews == null) {
        _loadReviews();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    if (_loadingReviews) return;
    setState(() => _loadingReviews = true);
    final repo = SupabaseRepository();
    final userId = context.read<AppAuthProvider>().userId;
    final reviews = await repo.getReviewsForCourt(widget.court.id);
    bool hasBooked = false;
    bool hasReviewed = false;
    if (userId != null) {
      hasBooked = await repo.hasUserBookedCourt(widget.court.id, userId);
      hasReviewed = await repo.hasUserReviewedCourt(widget.court.id, userId);
    }
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _hasBooked = hasBooked;
        _hasReviewed = hasReviewed;
        _loadingReviews = false;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _sportLabel(String? type) {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('pickleball')) return 'Pickleball';
    if (t.contains('bóng đá') || t.contains('football') || t.contains('soccer')) return 'Bóng đá';
    if (t.contains('tennis')) return 'Tennis';
    if (t.contains('bóng rổ') || t.contains('basketball')) return 'Bóng rổ';
    if (t.contains('bóng chuyền') || t.contains('volleyball')) return 'Bóng chuyền';
    if (t.contains('cầu lông') || t.contains('badminton')) return 'Cầu lông';
    return 'Thể thao';
  }

  Color _sportColor(String? type) {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('pickleball')) return Colors.blue;
    if (t.contains('bóng đá') || t.contains('football') || t.contains('soccer')) return Colors.orange;
    if (t.contains('tennis')) return Colors.purple;
    if (t.contains('bóng rổ') || t.contains('basketball')) return Colors.deepOrange;
    if (t.contains('bóng chuyền') || t.contains('volleyball')) return Colors.teal;
    return Colors.green; // cầu lông mặc định
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
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name',
        );
      }
    } else {
      uri = Uri.parse(
        'https://maps.apple.com/?daddr=$lat,$lng&directionsmode=driving',
      );
    }

    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _bookCourt() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
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
      minChildSize: 0.0,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.55],
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
                colors: [Colors.black.withOpacity(0.45), Colors.transparent],
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
                onTap: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                },
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
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _sportColor(court.sportType).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _sportColor(court.sportType).withOpacity(0.35),
                  ),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: _bookCourt,
            child: Builder(
              builder: (context) {
                final l = AppLocalizations.of(context)!;
                return Text(
                  l.bookingNow,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveTabSlivers(
    BuildContext context,
    CourtLocationModel court,
  ) {
    switch (_tabController.index) {
      case 0:
        return _buildInfoTabSlivers(court);
      case 1:
        return _buildServicesTabSlivers(context);
      case 2:
        return _buildImagesTabSlivers(court);
      case 3:
        if (_reviews == null && !_loadingReviews) {
          // start loading if not already
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
        }
        return _buildReviewsTabSlivers(court);
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
                      const Text(
                        'Giá thuê',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
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
                      const Text(
                        'Số sân',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
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
                children: [
                  const Text(
                    'Link đặt sân online',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (court.website != null && court.website!.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(court.website!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text(
                        court.website!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  else
                    const Text(
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Sân chất lượng cao, hệ thống đèn chiếu sáng đầy đủ, bãi đậu xe rộng rãi. Phù hợp cho các buổi tập luyện và thi đấu.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                      height: 1.5,
                    ),
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
      return price
          .toStringAsFixed(0)
          .replaceAllMapped(
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
        icon: Icons.local_drink_rounded,
        label: 'Nước uống / Căn tin',
      ),
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
                          child: Text(
                            s.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
            child: Text(
              'Chưa có hình ảnh',
              style: TextStyle(color: AppColors.textGrey),
            ),
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
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.borderColor),
              ),
            ),
            childCount: 4,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildReviewsTabSlivers(CourtLocationModel court) {
    // Loading state
    if (_loadingReviews) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final reviews = _reviews ?? [];
    final userId = context.read<AppAuthProvider>().userId;
    final canReview =
        (_hasBooked == true) && (_hasReviewed == false) && userId != null;

    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // --- Summary Header ---
            if (reviews.isNotEmpty) ..._buildRatingSummary(court, reviews),

            // --- Write Review Button ---
            if (canReview) ..._buildWriteReviewButton(court, userId),

            // --- Prompt to book if hasn't booked ---
            if (_hasBooked == false) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Bạn cần đặt sân tại đây để có thể viết đánh giá.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // --- Empty State ---
            if (reviews.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      Icons.rate_review_rounded,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có đánh giá nào',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hãy đặt sân và chia sẻ trải nghiệm của bạn!',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              // --- Review List ---
              ...reviews.map((r) => _ReviewCard(review: r)).toList(),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _buildRatingSummary(
    CourtLocationModel court,
    List<ReviewModel> reviews,
  ) {
    final avg = reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length;
    // count per star
    final counts = List.generate(
      5,
      (i) => reviews.where((r) => r.rating == 5 - i).length,
    );
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.floor()
                        ? Icons.star_rounded
                        : (i < avg
                              ? Icons.star_half_rounded
                              : Icons.star_border_rounded),
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${reviews.length} đánh giá',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[i];
                final ratio = reviews.isEmpty ? 0.0 : count / reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: AppColors.borderColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      const Divider(height: 24),
    ];
  }

  List<Widget> _buildWriteReviewButton(
    CourtLocationModel court,
    String userId,
  ) {
    return [
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Viết đánh giá'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => _showReviewDialog(court, userId),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  void _showReviewDialog(CourtLocationModel court, String userId) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Viết đánh giá',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    court.name,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Star selector
                  const Text(
                    'Chất lượng sân',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedRating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            star <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  Center(
                    child: Text(
                      _ratingLabel(selectedRating),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Comment
                  const Text(
                    'Nhận xét của bạn',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn...',
                      hintStyle: const TextStyle(color: AppColors.textLight),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              setModalState(() => submitting = true);
                              try {
                                final review = ReviewModel(
                                  id: '',
                                  courtId: court.id,
                                  userId: userId,
                                  rating: selectedRating,
                                  comment: commentController.text.trim(),
                                  createdAt: DateTime.now(),
                                );
                                await SupabaseRepository().submitReview(review);
                                if (ctx.mounted) Navigator.pop(ctx);
                                // Reload reviews
                                _loadReviews();
                              } catch (e) {
                                setModalState(() => submitting = false);
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Gửi đánh giá',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Tệ';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tốt';
      case 5:
        return 'Tuyệt vời!';
      default:
        return '';
    }
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
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.4,
            ),
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: Colors.white, child: tabBar);

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

// ── Review Card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review.reviewer;
    final displayName = reviewer?.displayName ?? review.reviewerName ?? 'Người dùng';
    final avatarUrl = reviewer?.photoUrl ?? review.reviewerAvatar;
    
    final initials = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';
    final dateStr = DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + date
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textBlack,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
