import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:badminton_ai/screens/user/booking/booking_method_modal.dart';
import 'package:badminton_ai/screens/user/booking/event_list_screen.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';
import 'package:badminton_ai/screens/user/notifications/notifications_screen.dart';
import 'package:badminton_ai/screens/user/scanner/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_state.dart';
import 'package:badminton_ai/screens/user/home/components/home_search_bar.dart';
import 'package:badminton_ai/screens/user/home/components/home_filter_bar.dart';
import 'package:badminton_ai/screens/user/home/components/home_filter_modal.dart';
import 'package:flutter/cupertino.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng bản đồ')),
      );
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
            MaterialPageRoute(
              builder: (_) => EventListScreen(court: court),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleQRCodeResult(String scannedCode) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang xử lý mã QR...'),
        duration: Duration(seconds: 1),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLink ? 'Mở liên kết?' : 'Kết quả quét'),
        content: Text(scannedCode),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.blue)),
          ),
          if (isLink)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Mở', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
    );
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
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/home.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.brandOrange.withValues(alpha: 0.4), // Darken slightly for readability of white text
            BlendMode.darken,
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                backgroundColor: Colors.orange[100],
                child: user?.photoUrl == null
                    ? Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.orange[800],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, dd/MM/yyyy',
                        'vi_VN',
                      ).format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      user?.displayName ?? '',
                      style: const TextStyle(
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          const HomeFilterBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader(title: 'Ưu đãi đặc biệt', onSeeAll: () {}),
          _buildSpecialOfferCard(),
          const SizedBox(height: 20),
          _buildCourtsListHeader(),
          const SizedBox(height: 10),
          _buildCourtsList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'XEM TẤT CẢ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourtsListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Danh sách sân',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            // child: const Row(
            //   children: [
            //     Text(
            //       'SẮP XẾP',
            //       style: TextStyle(fontSize: 10, color: Colors.grey),
            //     ),
            //     Icon(Icons.sort, size: 14, color: Colors.grey),
            //   ],
            // ),
          ),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications, color: Colors.white),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCourtsList() {
    return BlocBuilder<HomeFilterBloc, HomeFilterState>(
      builder: (context, state) {
        if (state.status == HomeFilterStatus.loading ||
            state.status == HomeFilterStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == HomeFilterStatus.failure) {
          return Center(child: Text(state.errorMessage ?? "Có lỗi xảy ra"));
        }

        final courts = state.filteredCourts;
        if (courts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Không có sân nào phù hợp với bộ lọc",
                style: TextStyle(color: Colors.grey),
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

        return Column(
          children: sorted
              .map(
                (court) => _CourtListItem(
                  court: court,
                  distance: _currentLocation != null
                      ? _calculateDistance(court)
                      : 0.0,
                  onTap: () => _showBookingMethodModal(court),
                  onDirections: () =>
                      _launchMaps(court.latitude, court.longitude),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSpecialOfferCard() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildOfferItem(
            'Cuối tuần bùng nổ',
            'Giảm 20% đặt sân',
            'assets/images/logo.jpg',
            AppColors.primary,
          ),
          _buildOfferItem(
            'Khung giờ vàng',
            'Đồng giá 50k/h',
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
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor.withOpacity(0.1), bannerColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bannerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ƯU ĐÃI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
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
                color: bannerColor.withOpacity(0.2),
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(),
                  const SizedBox(height: 8),
                  _buildRatingAndDistance(),
                  const SizedBox(height: 16),
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
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: Colors.grey[200],
            image: court.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(court.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: court.imageUrl == null
              ? const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                )
              : null,
        ),
        // 'Trống sân' badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'Trống sân',
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 16, color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          NumberFormat.simpleCurrency(
            locale: 'vi_VN',
            decimalDigits: 0,
          ).format(court.pricePerHour),
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingAndDistance() {
    final rating = court.rating > 0 ? court.rating : 4.8;
    return Row(
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          '$rating',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(width: 8),
        const Text('•', style: TextStyle(color: AppColors.textLight)),
        const SizedBox(width: 8),
        const Icon(Icons.location_on, size: 14, color: AppColors.textGrey),
        const SizedBox(width: 4),
        Text(
          '${distance.toStringAsFixed(1)} km',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        const SizedBox(width: 8),
        const Text('•', style: TextStyle(color: AppColors.textLight)),
        const SizedBox(width: 8),
        Text(
          '${court.totalCourts} sân',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Đặt ngay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onDirections,
            icon: const Icon(Icons.directions, color: AppColors.primary),
            tooltip: 'Chỉ đường',
          ),
        ),
      ],
    );
  }
}
