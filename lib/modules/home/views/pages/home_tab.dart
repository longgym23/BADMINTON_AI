import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/notification_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/notifications/viewmodels/notification_provider.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/booking_method_modal.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/event_list_screen.dart';
import 'package:badminton_ai/modules/notifications/views/pages/notifications_screen.dart';
import 'package:badminton_ai/modules/scanner/views/pages/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/court_selection_screen.dart';
import 'package:badminton_ai/core/utils/dialog_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/modules/home/viewmodels/home_filter_bloc.dart';
import 'package:badminton_ai/modules/home/viewmodels/home_filter_state.dart';
import 'package:badminton_ai/modules/home/views/widgets/home_search_bar.dart';
import 'package:badminton_ai/modules/home/views/widgets/home_filter_bar.dart';
import 'package:badminton_ai/modules/home/views/widgets/home_filter_modal.dart';
import 'package:badminton_ai/modules/profile/views/pages/edit_profile_screen.dart';
import 'package:badminton_ai/modules/home/views/widgets/court_list_item.dart';

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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(
          () =>
              _currentLocation = LatLng(position.latitude, position.longitude),
        );
      }
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

  /// Các pattern nhận dạng QR ngân hàng / thanh toán — bị chặn.
  static const _bankingPatterns = <String>[
    'vietqr.io',
    'vietqr.vn',
    'napas.com.vn',
    'zalopay.vn',
    'momo.vn',
    'vnpay.vn',
    'shopeepay',
    'payos',
    'banking',
    'transfer',
    'qr.vn',
    'bidv',
    'vcb.com.vn',
    'vietcombank',
    'techcombank',
    'tpbank',
    'mbbank',
    'acb.com.vn',
    'vpbank',
    'agribank',
    'vib.com.vn',
    'ocb.com.vn',
    'seabank',
  ];

  /// Trả về `true` nếu chuỗi QR trông như mã QR ngân hàng / thanh toán.
  bool _isBankingQR(String raw) {
    final lower = raw.toLowerCase();

    // Scheme đặc biệt của ngân hàng (ví dụ: napas://, zalopay://)
    if (RegExp(r'^(napas|zalopay|momo|vnpay|payos|shopeepay):').hasMatch(lower)) {
      return true;
    }

    // Chuỗi EMV / VietQR dạng plain text (bắt đầu bằng "000201")
    if (lower.startsWith('000201')) return true;

    // Kiểm tra domain
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      return _bankingPatterns.any((p) => host.contains(p));
    }

    // Plain text chứa keyword ngân hàng
    return _bankingPatterns.any((p) => lower.contains(p));
  }



  Future<void> _handleQRCodeResult(String scannedCode) async {
    if (!mounted) return;

    // ── 1. Kiểm tra QR ngân hàng trước — bỏ qua hoàn toàn ──────────────────
    if (_isBankingQR(scannedCode)) {
      DialogUtils.showAlertDialog(
        context,
        title: 'home_tab.scanResult'.tr(),
        content: 'home_tab.bankingQrNotSupported'.tr(),
        confirmText: 'common.ok'.tr(),
      );
      return;
    }

    // ── 2. Tìm sân theo court ID ─────────────────────────────────────────────
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

    // ── 3. Kiểm tra có phải là Web URL không ───────────────────────────────
    final uri = Uri.tryParse(scannedCode);
    final isHttpLink =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isHttpLink) {
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
      confirmText: 'common.ok'.tr(),
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
      backgroundColor: VColors.background,
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
            VColors.brandPrimary.withValues(
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
          //     border: Border.all(color: VColors.borderDefault),
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
                    color: VColors.statusCritical,
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
        return CourtListItem(
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
            VColors.brandPrimary,
          ),
          _buildOfferItem(
            'home_tab.goldenHour'.tr(),
            'home_tab.flatRate50k'.tr(),
            null,
            VColors.statusSuccess,
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
                    color: VColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: VColors.textSecondary,
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
