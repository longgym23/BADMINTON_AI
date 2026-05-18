import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:badminton_ai/screens/user/booking/booking_method_modal.dart';
import 'package:badminton_ai/screens/user/booking/event_list_screen.dart';
import 'package:badminton_ai/screens/user/notifications/notifications_screen.dart';
import 'package:badminton_ai/screens/user/scanner/qr_scanner_screen.dart';
import 'package:badminton_ai/screens/user/booking/court_reviews_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_state.dart';
import 'package:badminton_ai/screens/user/home/components/home_search_bar.dart';
import 'package:badminton_ai/screens/user/home/components/home_filter_bar.dart';
import 'package:badminton_ai/screens/user/home/components/home_filter_modal.dart';
import 'package:badminton_ai/screens/user/profile/edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted)
        setState(
          () =>
              _currentLocation = LatLng(position.latitude, position.longitude),
        );
    } catch (e) {
      debugPrint("Lỗi lấy vị trí: $e");
    }
  }

  double _calculateDistance(CourtLocationModel court) {
    if (_currentLocation == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          court.latitude,
          court.longitude,
        ) /
        1000;
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final appleUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleUrl)) {
      await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('home_tab.cannotOpenMap'.tr())));
    }
  }

  void _showBookingMethodModal(CourtLocationModel court) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingMethodModal(
        court: court,
        onVisualBooking: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourtSelectionScreen(
                selectedCourt: court,
                selectedDate: DateTime.now(),
              ),
            ),
          );
        },
        onEventBooking: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventListScreen(court: court)),
          );
        },
      ),
    );
  }

  Future<void> _handleQRCodeResult(String scannedCode) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('home_tab.processingQR'.tr()),
        duration: const Duration(seconds: 1),
      ),
    );

    final court = await context.read<SupabaseRepository>().getCourtLocationById(
      scannedCode,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (court != null) {
      _showBookingMethodModal(court);
      return;
    }

    final uri = Uri.tryParse(scannedCode);
    final isLink =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isLink) {
      DialogUtils.showConfirmDialog(
        context,
        title: 'home_tab.openLink'.tr(),
        content: scannedCode,
        cancelText: 'common.cancel'.tr(),
        confirmText: 'home_tab.open'.tr(),
        onConfirm: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      );
    } else {
      DialogUtils.showAlertDialog(
        context,
        title: 'home_tab.scanResult'.tr(),
        content: scannedCode,
        confirmText: 'common.cancel'.tr(),
      );
    }
  }

  void _showFilterModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<HomeFilterBloc>(),
          child: HomeFilterModal(
            initialCriteria: context
                .read<HomeFilterBloc>()
                .state
                .filterCriteria,
          ),
        ),
      ),
    );
  }

  Stream<List<NotificationModel>> _getUnreadNotificationsCount() {
    final userId = context.read<AppAuthProvider>().userModel?.id;
    if (userId == null) return Stream.value([]);
    return context
        .read<NotificationProvider>()
        .getNotificationsStream(userId)
        .map((ns) => ns.where((n) => !n.isRead).toList())
        .handleError((e) {
          debugPrint("Lỗi đếm notifications chưa đọc: $e");
          return <NotificationModel>[];
        });
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // Bàn phím trượt đè lên chống đẩy UI
      body: Column(
        children: [
          _buildHeader(user),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── Widget Helpers ───────────────────────────────────────────────────────────

  Widget _buildHeader(user) {
    return Container(
      padding: EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/home.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.brandOrange.withValues(
              alpha: 0.4,
            ), // Darken slightly for readability of white text
            BlendMode.darken,
          ),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  backgroundColor: Colors.orange[100],
                  child: user?.photoUrl == null
                      ? Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.orange[800],
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, dd/MM/yyyy',
                        context.locale.toString(),
                      ).format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      user?.displayName ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildNotificationIcon(),
            ],
          ),
          SizedBox(height: 16),
          HomeSearchBar(
            controller: _searchController,
            onQrScan: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
              if (result is String) _handleQRCodeResult(result);
            },
            onFilterTap: _showFilterModal,
          ),
          SizedBox(height: 16),
          const HomeFilterBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<HomeFilterBloc, HomeFilterState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  _buildSectionHeader(
                    title: 'home_tab.specialOffers'.tr(),
                    onSeeAll: () {},
                  ),
                  _buildSpecialOfferCard(),
                  SizedBox(height: 20),
                  _buildCourtsListHeader(),
                  SizedBox(height: 10),
                ],
              ),
            ),
            _buildSliverCourtsList(state),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onSeeAll}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'home_tab.seeAll'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourtsListHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'home_tab.courtList'.tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Container(
          //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: AppColors.borderColor),
          //     borderRadius: BorderRadius.circular(4),
          //   ),
          //   child: Row(
          //     children: [
          //       Text(
          //         'screens.aRRANGE'.tr(),
          //         style: TextStyle(fontSize: 10, color: Colors.grey),
          //       ),
          //       Icon(Icons.sort, size: 14, color: Colors.grey),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.length ?? 0;
        return Stack(
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSliverCourtsList(HomeFilterState state) {
    if (state.status == HomeFilterStatus.loading ||
        state.status == HomeFilterStatus.initial) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (state.status == HomeFilterStatus.failure) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(state.errorMessage ?? 'home_tab.errorOccurred'.tr()),
          ),
        ),
      );
    }

    final courts = state.filteredCourts;
    if (courts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'home_tab.noCourtsMatchFilter'.tr(),
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final sorted = List<CourtLocationModel>.from(courts);
    if (_currentLocation != null) {
      sorted.sort(
        (a, b) => _calculateDistance(a).compareTo(_calculateDistance(b)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final court = sorted[index];
        return _CourtListItem(
          court: court,
          distance: _currentLocation != null ? _calculateDistance(court) : 0.0,
          onTap: () => _showBookingMethodModal(court),
          onDirections: () => _launchMaps(court.latitude, court.longitude),
        );
      }, childCount: sorted.length),
    );
  }

  Widget _buildSpecialOfferCard() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildOfferItem(
            'home_tab.weekendExplosion'.tr(),
            'home_tab.discount20'.tr(),
            null,
            AppColors.primary,
          ),
          _buildOfferItem(
            'home_tab.goldenHour'.tr(),
            'home_tab.flatRate50k'.tr(),
            null,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferItem(
    String title,
    String subtitle,
    String? imagePath,
    Color bannerColor,
  ) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16, bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor.withValues(alpha: 0.1),
            bannerColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bannerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'home_tab.offers'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textBlack,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (imagePath != null)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: bannerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_offer, color: bannerColor, size: 30),
            ),
        ],
      ),
    );
  }
}

// ─── Court List Item Widget ────────────────────────────────────────────────────

class _CourtListItem extends StatelessWidget {
  final CourtLocationModel court;
  final double distance;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const _CourtListItem({
    required this.court,
    required this.distance,
    required this.onTap,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(),
                  SizedBox(height: 8),
                  _buildRatingAndDistance(context),
                  SizedBox(height: 16),
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
    return Stack(
      children: [
        // Court image
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: court.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: court.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                )
              : Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
        ),
        // 'screens.emptyYard1'.tr() badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'home_tab.emptyCourt'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.verified, size: 16, color: AppColors.primary),
            ],
          ),
        ),
        SizedBox(width: 8),
        Text(
          NumberFormat.simpleCurrency(
            locale: 'vi_VN',
            decimalDigits: 0,
          ).format(court.pricePerHour),
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingAndDistance(BuildContext context) {
    final rating = court.rating > 0 ? court.rating : 4.8;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourtReviewsScreen(court: court),
              ),
            );
          },
          child: Row(
            children: [
              Icon(Icons.star, size: 16, color: Colors.amber),
              SizedBox(width: 4),
              Text(
                '$rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textBlack,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textGrey,
              ),
            ],
          ),
        ),
        SizedBox(width: 4),
        Text('•', style: TextStyle(color: AppColors.textLight)),
        SizedBox(width: 8),
        Icon(Icons.location_on, size: 14, color: AppColors.textGrey),
        SizedBox(width: 4),
        Text(
          '${distance.toStringAsFixed(1)} km',
          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        SizedBox(width: 8),
        Text('•', style: TextStyle(color: AppColors.textLight)),
        SizedBox(width: 8),
        Text(
          '${court.totalCourts} ${'home_tab.courts'.tr()}',
          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'home_tab.bookNow'.tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: 12),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onDirections,
            icon: Icon(Icons.directions, color: AppColors.primary),
            tooltip: 'home_tab.directions'.tr(),
          ),
        ),
      ],
    );
  }
}
