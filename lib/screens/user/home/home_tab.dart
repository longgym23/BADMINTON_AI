import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:badminton_ai/screens/user/booking/booking_method_modal.dart';
import 'package:badminton_ai/screens/user/chat/chatbot_tab.dart';
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

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;

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

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy vị trí: $e");
    }
  }

  Stream<List<NotificationModel>> _getUnreadNotificationsCount(
    BuildContext context,
  ) {
    final userId = context.read<AppAuthProvider>().userModel?.id;
    if (userId == null) {
      return Stream.value([]);
    }
    final notificationProvider = context.read<NotificationProvider>();
    return notificationProvider
        .getNotificationsStream(userId)
        .map((notifications) => notifications.where((n) => !n.isRead).toList())
        .handleError((error) {
          debugPrint("Lỗi đếm notifications chưa đọc: $error");
          return <NotificationModel>[];
        });
  }

  double _calculateDistance(CourtLocationModel court) {
    if (_currentLocation == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          court.latitude,
          court.longitude,
        ) /
        1000; // Convert to km
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng bản đồ')),
        );
      }
    }
  }

  void _showBookingMethodModal(CourtLocationModel court) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingMethodModal(
        court: court,
        onVisualBooking: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourtSelectionScreen(
                selectedCourt: court,
                selectedDate: DateTime.now(),
              ),
            ),
          );
        },
        onEventBooking: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tính năng đặt sự kiện đang được phát triển"),
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

    final firestoreRepo = context.read<FirestoreRepository>();
    final court = await firestoreRepo.getCourtLocationById(scannedCode);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (court != null) {
      _showBookingMethodModal(court);
    } else {
      final uri = Uri.tryParse(scannedCode);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mở liên kết?'),
            content: Text(scannedCode),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: const Text('Mở'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kết quả quét'),
            content: Text(scannedCode),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.userModel;
    final firestoreRepo = context.watch<FirestoreRepository>();

    // Using a dark blue color for header background like the reference
    // final headerColor = const Color(0xFF1F2937); // Moved to AppColors.darkHeader

    return Scaffold(
      backgroundColor: AppColors.background, // Light background for body
      body: Column(
        children: [
          // Header Section (Dark Background)
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.darkHeader,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Top Row: Avatar + Greeting + Notification
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
                              user?.displayName
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
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
                            user?.displayName ?? 'Minh Nguyen',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildNotificationIcon(context),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm sân, vị trí...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.grey,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                          if (result != null && result is String) {
                            _handleQRCodeResult(result);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.mic, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Tags
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHeaderFilterChip('Cầu lông gần tôi', true),
                      const SizedBox(width: 8),
                      _buildHeaderFilterChip('Pickleball', false),
                      const SizedBox(width: 8),
                      _buildHeaderFilterChip('Sân mới', false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildCategoryItem(
                          'Pickleball',
                          Icons.sports_tennis,
                          AppColors.primary,
                        ),
                        _buildCategoryItem(
                          'Cầu lông',
                          Icons.sports_tennis,
                          AppColors.success,
                        ),
                        _buildCategoryItem(
                          'Bóng đá',
                          Icons.sports_soccer,
                          Colors.orange,
                        ),
                        _buildCategoryItem(
                          'Bóng chuyền',
                          Icons.sports_volleyball,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  // "Bộ lọc tìm kiếm"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc tìm kiếm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Xóa bộ lọc',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterTag('Có điều hòa', true),
                        const SizedBox(width: 8),
                        _buildFilterTag('< 100k', true),
                        const SizedBox(width: 8),
                        _buildFilterTag('Tất cả', false, isDark: true),
                        const SizedBox(width: 8),
                        _buildFilterTag('Giá cả', false, hasArrow: true),
                        const SizedBox(width: 8),
                        _buildFilterTag('Tiện nghi', false, hasArrow: true),
                      ],
                    ),
                  ),

                  // "Ưu đãi đặc biệt"
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ưu đãi đặc biệt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'XEM TẤT CẢ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSpecialOfferCard(),

                  // "Danh sách sân"
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Danh sách sân',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: const [
                              Text(
                                'SẮP XẾP',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              Icon(Icons.sort, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Courts List
                  StreamBuilder<List<CourtLocationModel>>(
                    stream: firestoreRepo.getCourtLocationsStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final courts = snapshot.data!;
                      if (courts.isEmpty)
                        return const Center(child: Text("Chưa có sân nào"));

                      // Simple sort by distance
                      final sortedCourts = List<CourtLocationModel>.from(
                        courts,
                      );
                      if (_currentLocation != null) {
                        sortedCourts.sort(
                          (a, b) => _calculateDistance(
                            a,
                          ).compareTo(_calculateDistance(b)),
                        );
                      }

                      return Column(
                        children: sortedCourts
                            .map(
                              (court) => _CourtListItem(
                                court: court,
                                distance: _currentLocation != null
                                    ? _calculateDistance(court)
                                    : 0.0,
                                onTap: () => _showBookingMethodModal(court),
                                onDirections: () => _launchMaps(
                                  court.latitude,
                                  court.longitude,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotTab(),
            ), // Navigate to Chatbot
          );
        },
        backgroundColor: AppColors.darkHeader,
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.android, color: Colors.white, size: 16),
        ),
        label: const Text('Chat với AI', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _getUnreadNotificationsCount(context),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.length ?? 0;
        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
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

  Widget _buildHeaderFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.grey[700]
            : Colors
                  .grey[800], // Keep dark theme specific greys or move to AppColors if needed, but safe for now to keep as is for header
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: Colors.grey[500]!) : null,
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(
    String label,
    bool isSelected, {
    bool isDark = false,
    bool hasArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkHeader
            : (isSelected ? AppColors.primaryBg : AppColors.surface),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          if (isDark) const Icon(Icons.tune, color: Colors.white, size: 14),
          if (isDark) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.surface
                  : (isSelected ? AppColors.primary : AppColors.textBlack),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected && !isDark) ...[
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 14, color: AppColors.primary),
          ],
          if (hasArrow) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialOfferCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage(
                  'assets/images/badminton_logo.jpg',
                ), // Placeholder or asset
                fit: BoxFit.cover,
              ),
            ),
            child: const Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: Text(
                  '-20%',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.red,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuối tuần bùng nổ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giảm giá 20% cho tất cả các đặt sân tại Victor Courts.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Nhận ngay'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(24), // Rounded Card
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding inside card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section with Badges
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16), // Rounded Image
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
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                  // 'Trống sân' Badge - Top Right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green),
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
                  // Distance & 'Đặt ngay' - Bottom Left
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkHeader.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Đặt ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info Section
              Row(
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
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${NumberFormat.compact().format(court.pricePerHour)}k',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const TextSpan(
                          text: '/giờ',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Sàn gỗ • ${court.totalCourts} sân',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 12),
              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 20, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${court.rating > 0 ? court.rating : 4.8}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' (${court.totalReviews > 0 ? court.totalReviews : 120} đánh giá)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onDirections,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions,
                            size: 20,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Chi tiết',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
