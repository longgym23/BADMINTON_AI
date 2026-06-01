import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/viewmodels/admin_dashboard_viewmodel.dart';
import 'package:badminton_ai/viewmodels/mixins/filterable_viewmodel_mixin.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';
import 'package:badminton_ai/utils/wallet_dialog_utils.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDesktopDashboardScreen extends StatelessWidget {
  const AdminDesktopDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminDashboardViewModel>(
      create: (_) => AdminDashboardViewModel(
        repo: context.read<SupabaseRepository>(),
        auth: context.read<AppAuthProvider>(),
      )..fetchDashboardData(),
      child: const _AdminDesktopDashboardView(),
    );
  }
}

class _AdminDesktopDashboardView extends StatefulWidget {
  const _AdminDesktopDashboardView();

  @override
  State<_AdminDesktopDashboardView> createState() => _AdminDesktopDashboardViewState();
}

class _AdminDesktopDashboardViewState extends State<_AdminDesktopDashboardView> {
  int _selectedIndex = 0;
  String _userSearchQuery = "";
  String _courtSearchQuery = "";

  // Local permissions simulation map
  // Maps userId -> Map of permissionKey -> bool
  final Map<String, Map<String, bool>> _simulatedPermissions = {};

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminDashboardViewModel>();
    final auth = context.watch<AppAuthProvider>();
    final user = auth.userModel;
    final isOwner = user?.role == 'court_owner';
    final isAdmin = user?.role == 'admin';

    // List of navigation items
    final navigationItems = [
      _NavigationItem(
        icon: Icons.dashboard_outlined,
        label: 'Tổng quan',
        index: 0,
      ),
      if (isAdmin)
        _NavigationItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Phân quyền & Vai trò',
          index: 1,
        ),
      _NavigationItem(
        icon: Icons.sports_tennis_outlined,
        label: 'Danh sách sân',
        index: 2,
      ),
      _NavigationItem(
        icon: Icons.calendar_month_outlined,
        label: 'Lịch đặt & Giao dịch',
        index: 3,
      ),
      _NavigationItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Yêu cầu rút tiền',
        index: 4,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // 1. Sleek Sidebar
          Container(
            width: 280,
            color: AppColors.brandDarkBlue, // Dark Blue of Dai Nam University
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo1.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Badminton AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOwner ? 'Chủ Sân Portal' : 'Admin Portal',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),
                
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    itemCount: navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = navigationItems[index];
                      final isSelected = _selectedIndex == item.index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedIndex = item.index);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primary.withValues(alpha: 0.15) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primary.withValues(alpha: 0.3) 
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade300,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                    fontFamily: 'Arial',
                                  ),
                                ),
                                if (isSelected) ...[
                                  const Spacer(),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // User profile footer
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: isOwner
                            ? const AssetImage('assets/images/personnel.gif')
                            : const AssetImage('assets/images/admin.gif'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? user?.email ?? 'Quản trị viên',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOwner ? 'Chủ Sân' : 'Admin Hệ Thống',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          context.read<AppAuthProvider>().signOut();
                        },
                        tooltip: 'Đăng xuất',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 2. Main Content Workspace
          Expanded(
            child: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header bar
                      _buildHeader(user, vm),
                      
                      // Panel space
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedIndex == 0) _buildOverviewPanel(isOwner, isAdmin, vm),
                              if (_selectedIndex == 1 && isAdmin) _buildPermissionsPanel(isAdmin, vm),
                              if (_selectedIndex == 2) _buildCourtsPanel(isOwner, user?.id, vm),
                              if (_selectedIndex == 3) _buildBookingsPanel(isOwner, user?.id, vm),
                              if (_selectedIndex == 4) _buildWithdrawalsPanel(isOwner, user?.id),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- Common Widgets ---

  Widget _buildHeader(UserModel? user, AdminDashboardViewModel vm) {
    String titleText = "";
    switch (_selectedIndex) {
      case 0:
        titleText = "Bảng Thống Kê & Tổng Quan";
        break;
      case 1:
        titleText = "Phân Quyền & Quản Lý Thành Viên";
        break;
      case 2:
        titleText = "Quản Lý Danh Sách Cơ Sở Sân";
        break;
      case 3:
        titleText = "Quản Lý Đơn Đặt Sân & Giao Dịch";
        break;
      case 4:
        titleText = "Duyệt Yêu Cầu Rút Tiền";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppColors.textBlack,
            ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: vm.fetchDashboardData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Làm mới', style: TextStyle(fontFamily: 'Arial')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Panels ---

  // 1. Overview Panel
  Widget _buildOverviewPanel(bool isOwner, bool isAdmin, AdminDashboardViewModel vm) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDesktopFilterControls(vm),
        
        // 4 KPI Cards in a Row
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: vm.filterMode == FilterMode.last7Days
                    ? "TỔNG DOANH THU (7 ngày qua)"
                    : vm.filterMode == FilterMode.month
                        ? "DOANH THU THÁNG ${vm.selectedMonth}/${vm.selectedYear}"
                        : vm.filterMode == FilterMode.year
                            ? "DOANH THU NĂM ${vm.selectedYear}"
                            : "TỔNG DOANH THU (Khoảng ngày)",
                value: formatCurrency.format(vm.totalRevenue),
                icon: Icons.monetization_on_outlined,
                gradientColors: [const Color(0xFFFF6B00), const Color(0xFFFF9E53)],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildKPICard(
                title: "TỔNG LƯỢT ĐẶT SÂN",
                value: "${vm.totalBookingsCount} lượt",
                icon: Icons.shopping_bag_outlined,
                gradientColors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildKPICard(
                title: "CƠ SỞ SÂN ĐANG HOẠT ĐỘNG",
                value: "${vm.activeCourtsCount} cơ sở",
                icon: Icons.sports_tennis_outlined,
                gradientColors: [const Color(0xFF1565C0), const Color(0xFF2196F3)],
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: context.read<SupabaseRepository>().getAllUsersStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? vm.totalUsersCount;
                    return _buildKPICard(
                      title: "TỔNG SỐ THÀNH VIÊN",
                      value: "$count người dùng",
                      icon: Icons.people_outline,
                      gradientColors: [const Color(0xFF6A1B9A), const Color(0xFF9C27B0)],
                    );
                  }
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 32),

        // Split view: Charts
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue growth line chart card
            Expanded(
              flex: 2,
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.filterMode == FilterMode.last7Days
                            ? "Biểu Đồ Tăng Trưởng Doanh Thu Tuần Gần Nhất"
                            : vm.filterMode == FilterMode.month
                                ? "Biểu Đồ Tăng Trưởng Doanh Thu Tháng ${vm.selectedMonth}/${vm.selectedYear}"
                                : vm.filterMode == FilterMode.year
                                    ? "Biểu Đồ Tăng Trưởng Doanh Thu Năm ${vm.selectedYear}"
                                    : "Biểu Đồ Tăng Trưởng Doanh Thu Theo Bộ Lọc",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                          fontFamily: 'Arial',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: _buildLineChartWidget(vm),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            
            // Booking Status Pie Chart Card
            Expanded(
              flex: 1,
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tỷ Lệ Trạng Thái Lịch Đặt",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                          fontFamily: 'Arial',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildPieChartWidget(vm),
                      ),
                      const SizedBox(height: 24),
                      _buildPieChartLegend(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
 
        // Recent Bookings Table
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Giao Dịch Gần Đây",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                        fontFamily: 'Arial',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedIndex = 3);
                      },
                      child: const Text(
                        "Xem tất cả lịch",
                        style: TextStyle(color: AppColors.primary, fontFamily: 'Arial'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                vm.bookings.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Text(
                          "Chưa có dữ liệu đặt sân nào.",
                          style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Arial'),
                        ),
                      )
                    : Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2.5),
                          3: FlexColumnWidth(1.5),
                          4: FlexColumnWidth(1.5),
                          5: FlexColumnWidth(1.5),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        children: [
                          // Headers
                          TableRow(
                            children: [
                              _buildTableHeader("Mã đơn"),
                              _buildTableHeader("Sân & Số"),
                              _buildTableHeader("Thời gian chơi"),
                              _buildTableHeader("Khách hàng"),
                              _buildTableHeader("Tổng tiền"),
                              _buildTableHeader("Trạng thái"),
                            ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: w)).toList(),
                          ),
                          // Rows
                          ...vm.bookings.take(5).map((booking) {
                            final dateStr = DateFormat('dd/MM/yyyy').format(booking.date);
                            final timeStr = "${booking.timeSlot}:00 - ${booking.timeSlot + 1}:00";
                            
                            return TableRow(
                              children: [
                                Text(
                                  "#${booking.id != null && booking.id!.length > 8 ? booking.id!.substring(0, 8).toUpperCase() : (booking.id ?? '').toUpperCase()}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
                                ),
                                Text("${booking.courtName} - Sân #${booking.courtNumber}", style: const TextStyle(fontFamily: 'Arial')),
                                Text("$dateStr\n$timeStr", style: const TextStyle(fontSize: 12, fontFamily: 'Arial')),
                                Text(vm.userNames[booking.userId] ?? booking.userName, style: const TextStyle(fontFamily: 'Arial')),
                                Text(formatCurrency.format(booking.price), style: const TextStyle(fontFamily: 'Arial')),
                                _buildStatusBadge(booking.status),
                              ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: w)).toList(),
                            );
                          }),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arial',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: Colors.white.withOpacity(0.55),
            size: 40,
          ),
        ],
      ),
    );
  }

  // Line chart growth helper
  Widget _buildLineChartWidget(AdminDashboardViewModel vm) {
    final validStates = ['PAID', 'confirmed', 'completed'];
    
    // Calculate date bounds just like in VM
    DateTime start, end;
    final now = DateTime.now();
    if (vm.filterMode == FilterMode.dateRange && vm.selectedDateRange != null) {
      start = vm.selectedDateRange!.start;
      end = vm.selectedDateRange!.end;
    } else if (vm.filterMode == FilterMode.month && vm.selectedMonth != null && vm.selectedYear != null) {
      start = DateTime(vm.selectedYear!, vm.selectedMonth!, 1);
      end = DateTime(vm.selectedYear!, vm.selectedMonth! + 1, 0);
    } else if (vm.filterMode == FilterMode.year && vm.selectedYear != null) {
      start = DateTime(vm.selectedYear!, 1, 1);
      end = DateTime(vm.selectedYear!, 12, 31);
    } else {
      end = now;
      start = end.subtract(const Duration(days: 6));
    }

    Map<int, double> groupedRevenue = {};
    int totalPoints = 0;

    if (vm.filterMode == FilterMode.year) {
      totalPoints = 12;
      for (int i = 0; i < 12; i++) {
        groupedRevenue[i] = 0;
      }
      for (var b in vm.bookings) {
        if (validStates.contains(b.status.toUpperCase())) {
          final mIndex = b.date.month - 1;
          groupedRevenue[mIndex] = (groupedRevenue[mIndex] ?? 0) + b.price;
        }
      }
    } else {
      totalPoints = end.difference(start).inDays + 1;
      if (totalPoints < 1) totalPoints = 1;
      for (int i = 0; i < totalPoints; i++) {
        groupedRevenue[i] = 0;
      }
      for (var b in vm.bookings) {
        if (validStates.contains(b.status.toUpperCase())) {
          final diff = b.date.difference(start).inDays;
          if (diff >= 0 && diff < totalPoints) {
            groupedRevenue[diff] = (groupedRevenue[diff] ?? 0) + b.price;
          }
        }
      }
    }

    List<FlSpot> spots = [];
    double cumulativeSum = 0;
    double maxVal = 0;

    for (int i = 0; i < totalPoints; i++) {
      cumulativeSum += groupedRevenue[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), cumulativeSum));
      if (cumulativeSum > maxVal) {
        maxVal = cumulativeSum;
      }
    }

    if (maxVal == 0) {
      maxVal = 1000000;
    }
    final double maxY = (maxVal * 1.15).roundToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: (totalPoints / 7).clamp(1.0, double.infinity),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (totalPoints / 6).clamp(1.0, double.infinity),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= totalPoints) return const SizedBox.shrink();

                String label = "";
                if (vm.filterMode == FilterMode.year) {
                  label = "T${idx + 1}";
                } else if (vm.filterMode == FilterMode.month) {
                  label = "${idx + 1}";
                } else if (vm.filterMode == FilterMode.last7Days) {
                  final date = start.add(Duration(days: idx));
                  final weekday = date.weekday;
                  label = weekday == 7 ? "CN" : "T${weekday + 1}";
                } else {
                  final date = start.add(Duration(days: idx));
                  label = DateFormat('dd/MM').format(date);
                }

                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Arial',
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 70,
              getTitlesWidget: (value, meta) {
                final formatCompact = NumberFormat.compact(locale: 'vi_VN');
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    formatCompact.format(value),
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Arial',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        minX: 0,
        maxX: (totalPoints - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.brandDarkBlue,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final val = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(touchedSpot.y);
                return LineTooltipItem(
                  'Tổng doanh thu:\n$val',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Arial'),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            gradient: const LinearGradient(
              colors: [AppColors.brandOrangeDark, AppColors.brandOrangeLight],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.brandOrange.withOpacity(0.3),
                  AppColors.brandOrange.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, AdminDashboardViewModel vm) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: vm.selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brandOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.brandDarkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      vm.setFilterDateRange(picked);
    }
  }

  Future<void> _pickMonth(BuildContext context, AdminDashboardViewModel vm) async {
    final now = DateTime.now();
    int? tempMonth = vm.selectedMonth ?? now.month;
    int? tempYear = vm.selectedYear ?? now.year;

    final picked = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chọn Tháng & Năm", style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: tempMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text("Tháng ${index + 1}", style: const TextStyle(fontFamily: 'Arial')),
                      );
                    }),
                    onChanged: (val) {
                      setDialogState(() => tempMonth = val);
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: tempYear,
                    items: List.generate(11, (index) {
                      final year = now.year - 5 + index;
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text("Năm $year", style: const TextStyle(fontFamily: 'Arial')),
                      );
                    }),
                    onChanged: (val) {
                      setDialogState(() => tempYear = val);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontFamily: 'Arial')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Chọn", style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.bold, fontFamily: 'Arial')),
            ),
          ],
        );
      },
    );

    if (picked == true && tempMonth != null && tempYear != null) {
      vm.setFilterMonth(tempMonth!, tempYear!);
    }
  }

  Future<void> _pickYear(BuildContext context, AdminDashboardViewModel vm) async {
    final now = DateTime.now();
    int? tempYear = vm.selectedYear ?? now.year;

    final picked = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chọn Năm", style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButton<int>(
                value: tempYear,
                items: List.generate(11, (index) {
                  final year = now.year - 5 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text("Năm $year", style: const TextStyle(fontFamily: 'Arial')),
                  );
                }),
                onChanged: (val) {
                  setDialogState(() => tempYear = val);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontFamily: 'Arial')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Chọn", style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.bold, fontFamily: 'Arial')),
            ),
          ],
        );
      },
    );

    if (picked == true && tempYear != null) {
      vm.setFilterYear(tempYear!);
    }
  }

  Widget _buildDesktopFilterControls(AdminDashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Sân Lọc Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: vm.selectedCourtId,
                hint: const Text("Tất cả các sân", style: TextStyle(fontSize: 14, fontFamily: 'Arial', color: AppColors.textGrey)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("Tất cả các sân", style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.w600)),
                  ),
                  ...vm.courtsList.map((c) {
                    return DropdownMenuItem<String?>(
                      value: c['id'] as String,
                      child: Text(c['name'] as String, style: const TextStyle(fontSize: 14, fontFamily: 'Arial')),
                    );
                  }),
                ],
                onChanged: (val) {
                  vm.setSelectedCourtId(val);
                },
              ),
            ),
          ),
          const SizedBox(width: 24),
          const Spacer(),
          
          Text(
            "Bộ lọc thời gian: ",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 14, fontFamily: 'Arial'),
          ),
          const SizedBox(width: 8),
          
          _buildFilterChip(
            label: "7 ngày qua",
            isSelected: vm.filterMode == FilterMode.last7Days,
            onTap: () {
              vm.setFilterLast7Days();
            },
          ),
          const SizedBox(width: 8),
          
          _buildFilterChip(
            label: vm.filterMode == FilterMode.month && vm.selectedMonth != null && vm.selectedYear != null
                ? "Tháng ${vm.selectedMonth}/${vm.selectedYear}"
                : "Chọn Tháng",
            isSelected: vm.filterMode == FilterMode.month,
            onTap: () => _pickMonth(context, vm),
          ),
          const SizedBox(width: 8),
          
          _buildFilterChip(
            label: vm.filterMode == FilterMode.year && vm.selectedYear != null
                ? "Năm ${vm.selectedYear}"
                : "Chọn Năm",
            isSelected: vm.filterMode == FilterMode.year,
            onTap: () => _pickYear(context, vm),
          ),
          const SizedBox(width: 8),
          
          _buildFilterChip(
            label: vm.filterMode == FilterMode.dateRange && vm.selectedDateRange != null
                ? "${DateFormat('dd/MM').format(vm.selectedDateRange!.start)} - ${DateFormat('dd/MM').format(vm.selectedDateRange!.end)}"
                : "Khoảng ngày",
            isSelected: vm.filterMode == FilterMode.dateRange,
            onTap: () => _pickDateRange(context, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandOrange : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandOrange : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }

  // Pie chart helper
  Widget _buildPieChartWidget(AdminDashboardViewModel vm) {
    int paid = vm.bookings.where((b) => ['PAID', 'confirmed', 'completed'].contains(b.status.toUpperCase())).length;
    int pending = vm.bookings.where((b) => ['PENDING'].contains(b.status.toUpperCase())).length;
    int cancelled = vm.bookings.where((b) => ['CANCELLED', 'cancelled'].contains(b.status.toUpperCase())).length;
    int total = paid + pending + cancelled;
    
    if (total == 0) {
      paid = 70;
      pending = 20;
      cancelled = 10;
      total = 100;
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.green.shade600,
            value: paid.toDouble(),
            title: '${(paid * 100 / total).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Arial'),
          ),
          PieChartSectionData(
            color: Colors.amber.shade600,
            value: pending.toDouble(),
            title: '${(pending * 100 / total).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Arial'),
          ),
          PieChartSectionData(
            color: Colors.red.shade600,
            value: cancelled.toDouble(),
            title: '${(cancelled * 100 / total).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Arial'),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartLegend() {
    return Column(
      children: [
        _buildLegendRow("Thành công (PAID)", Colors.green.shade600),
        const SizedBox(height: 8),
        _buildLegendRow("Chờ thanh toán (PENDING)", Colors.amber.shade600),
        const SizedBox(height: 8),
        _buildLegendRow("Đã huỷ (CANCELLED)", Colors.red.shade600),
      ],
    );
  }

  Widget _buildLegendRow(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: AppColors.textBlack),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textGrey,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    String text = status;

    if (['PAID', 'confirmed', 'completed'].contains(status.toUpperCase())) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      text = "Thành công";
    } else if (['PENDING'].contains(status.toUpperCase())) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade700;
      text = "Đang chờ";
    } else if (['CANCELLED', 'cancelled'].contains(status.toUpperCase())) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      text = "Đã huỷ";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 2. Roles & Permissions Panel (THE CORE OF THIS WORK)
  Widget _buildPermissionsPanel(bool isAdmin, AdminDashboardViewModel vm) {
    final repo = context.read<SupabaseRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role Hierarchy and Guidelines Card
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ma Trận Phân Quyền Vai Trò Hệ Thống (System Role Access Control Matrix)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 20),
                // Matrix Grid Representation
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Scope Card
                    Expanded(
                      child: _buildRolePermissionSummaryCard(
                        roleTitle: "QUẢN TRỊ VIÊN (SUPER ADMIN)",
                        gradientColors: [const Color(0xFFE65100), const Color(0xFFFF8F00)],
                        permissions: [
                          "Toàn quyền quản trị hệ thống",
                          "Phân vai trò & Cấp phát tài khoản",
                          "Duyệt yêu cầu thanh toán / Rút tiền",
                          "Xem & Quản lý tất cả cơ sở sân",
                          "Truy xuất toàn bộ doanh thu tổng quát",
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Court Owner Scope Card
                    Expanded(
                      child: _buildRolePermissionSummaryCard(
                        roleTitle: "CHỦ SÂN (COURT OWNER)",
                        gradientColors: [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
                        permissions: [
                          "Quản lý danh sách sân thuộc sở hữu",
                          "Điều chỉnh lịch trống & Đặt slot cho sân",
                          "Xem báo cáo tài chính & Doanh thu riêng",
                          "Tạo và quản lý sự kiện thi đấu",
                          "Gửi yêu cầu rút tiền về tài khoản ví",
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User Scope Card
                    Expanded(
                      child: _buildRolePermissionSummaryCard(
                        roleTitle: "NGƯỜI CHƠI (PLAYER)",
                        gradientColors: [const Color(0xFF33691E), const Color(0xFF689F38)],
                        permissions: [
                          "Đặt sân cầu lông online trực tiếp",
                          "Chatbot tư vấn & Hỗ trợ lịch đặt thông minh",
                          "Giao lưu & Nhắn tin bạn bè cộng đồng",
                          "Nạp tiền ví điện tử qua mã VietQR",
                          "Đánh giá & Góp ý cơ sở sân",
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Live User Permission Matrix Grid Table
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Quản Lý Quyền Hạn Từng Thành Viên",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    // Search box
                    SizedBox(
                      width: 320,
                      height: 42,
                      child: TextField(
                        onChanged: (val) {
                          setState(() => _userSearchQuery = val.toLowerCase());
                        },
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm tên, email, sđt...",
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                StreamBuilder<List<UserModel>>(
                  stream: repo.getAllUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                    }
                    
                    var users = snapshot.data ?? [];
                    
                    // Filter query
                    if (_userSearchQuery.isNotEmpty) {
                      users = users.where((u) {
                        final name = (u.displayName ?? "").toLowerCase();
                        final email = (u.email ?? "").toLowerCase();
                        final phone = (u.phoneNumber ?? "").toLowerCase();
                        return name.contains(_userSearchQuery) || 
                               email.contains(_userSearchQuery) || 
                               phone.contains(_userSearchQuery);
                      }).toList();
                    }

                    if (users.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Text(
                          "Không tìm thấy thành viên nào phù hợp.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5), // User info
                        1: FlexColumnWidth(1.5), // Role dropdown
                        2: FlexColumnWidth(1.2), // Rights: Courts
                        3: FlexColumnWidth(1.2), // Rights: Bookings
                        4: FlexColumnWidth(1.2), // Rights: Finance
                        5: FlexColumnWidth(1.2), // Rights: Chatbot
                        6: FlexColumnWidth(1.5), // Wallet Balance
                        7: FlexColumnWidth(1.2), // Actions
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      children: [
                        // Header
                        TableRow(
                          children: [
                            _buildTableHeader("Thành viên"),
                            _buildTableHeader("Vai trò"),
                            _buildTableHeader("Cơ sở Sân"),
                            _buildTableHeader("Lịch Đặt"),
                            _buildTableHeader("Tài Chính"),
                            _buildTableHeader("Trợ lý AI"),
                            _buildTableHeader("Số dư ví"),
                            _buildTableHeader("Thao tác"),
                          ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: w)).toList(),
                        ),
                        // Rows
                        ...users.map((item) {
                          // Initialize simulated individual permissions
                          if (!_simulatedPermissions.containsKey(item.id)) {
                            _simulatedPermissions[item.id] = {
                              'courts': item.role == 'admin' || item.role == 'court_owner',
                              'bookings': true,
                              'finance': item.role == 'admin',
                              'chatbot': true,
                            };
                          }
                          
                          final perms = _simulatedPermissions[item.id]!;
                          final formattedBalance = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(item.balance);

                          return TableRow(
                            children: [
                              // 1. User details
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      (item.displayName ?? item.email ?? "?")[0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.displayName ?? "Khách hàng",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.email ?? "",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // 2. Role Dropdown selector
                              DropdownButtonHideUnderline(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButton<String>(
                                    value: item.role,
                                    isDense: true,
                                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                                    items: const [
                                      DropdownMenuItem(value: 'user', child: Text("Người dùng")),
                                      DropdownMenuItem(value: 'court_owner', child: Text("Chủ Sân")),
                                      DropdownMenuItem(value: 'admin', child: Text("Quản trị")),
                                    ],
                                    onChanged: !isAdmin ? null : (newVal) async {
                                      if (newVal != null && newVal != item.role) {
                                        _showRoleChangeConfirmation(item, newVal);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              // 3. Permission matrix: Courts
                              Checkbox(
                                activeColor: AppColors.primary,
                                value: perms['courts'],
                                onChanged: !isAdmin ? null : (bool? value) {
                                  setState(() {
                                    perms['courts'] = value ?? false;
                                  });
                                  AppToast.show(context, "Đã cập nhật quyền quản lý sân của ${item.displayName}", type: ToastType.success);
                                },
                              ),
                              // 4. Permission matrix: Bookings
                              Checkbox(
                                activeColor: AppColors.primary,
                                value: perms['bookings'],
                                onChanged: !isAdmin ? null : (bool? value) {
                                  setState(() {
                                    perms['bookings'] = value ?? false;
                                  });
                                  AppToast.show(context, "Đã cập nhật quyền đặt lịch của ${item.displayName}", type: ToastType.success);
                                },
                              ),
                              // 5. Permission matrix: Finance
                              Checkbox(
                                activeColor: AppColors.primary,
                                value: perms['finance'],
                                onChanged: !isAdmin ? null : (bool? value) {
                                  setState(() {
                                    perms['finance'] = value ?? false;
                                  });
                                  AppToast.show(context, "Đã cập nhật quyền tài chính của ${item.displayName}", type: ToastType.success);
                                },
                              ),
                              // 6. Permission matrix: Chatbot
                              Checkbox(
                                activeColor: AppColors.primary,
                                value: perms['chatbot'],
                                onChanged: !isAdmin ? null : (bool? value) {
                                  setState(() {
                                    perms['chatbot'] = value ?? false;
                                  });
                                  AppToast.show(context, "Đã cập nhật quyền chatbot của ${item.displayName}", type: ToastType.success);
                                },
                              ),
                              // 7. Wallet Balance
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      formattedBalance,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_calendar_outlined, size: 16, color: Colors.blueGrey),
                                    onPressed: () {
                                      WalletDialogUtils.showAdjustBalanceDialog(context, item, () {
                                        setState(() {});
                                      });
                                    },
                                    tooltip: 'Điều chỉnh số dư ví',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              // 8. Actions
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                    onPressed: () {
                                      _showUserFormDialog(context, item);
                                    },
                                    tooltip: 'Sửa thông tin',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () {
                                      _showUserDeleteConfirmation(item);
                                    },
                                    tooltip: 'Xóa tài khoản',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: w)).toList(),
                          );
                        }),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRolePermissionSummaryCard({
    required String roleTitle,
    required List<Color> gradientColors,
    required List<String> permissions,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              roleTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          ...permissions.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textBlack),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showRoleChangeConfirmation(UserModel user, String newRole) {
    String newRoleName = newRole == 'admin' 
        ? "Quản trị viên" 
        : (newRole == 'court_owner' ? "Chủ Sân" : "Người chơi");

    DialogUtils.showConfirmDialog(
      context,
      title: "Xác nhận thay đổi vai trò",
      content: "Bạn có chắc chắn muốn thay đổi vai trò của thành viên \"${user.displayName ?? user.email}\" sang [$newRoleName]?",
      confirmText: "Xác nhận",
      onConfirm: () async {
        try {
          final repo = context.read<SupabaseRepository>();
          await repo.updateUserRole(user.id, newRole);
          if (!mounted) return;
          AppToast.show(context, "Đã cập nhật vai trò của ${user.displayName ?? user.email} thành $newRoleName!", type: ToastType.success);
        } catch (e) {
          AppToast.show(context, "Lỗi khi cập nhật vai trò: $e", type: ToastType.error);
        }
      },
    );
  }

  void _showUserFormDialog(BuildContext context, UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.displayName);
    final phoneController = TextEditingController(text: user.phoneNumber);

    DialogUtils.showCustomDialog(
      context,
      title: "Chỉnh sửa thành viên",
      content: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên hiển thị"),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập tên" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Hủy"),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              try {
                final repo = context.read<SupabaseRepository>();
                final updated = user.copyWith(
                  displayName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                );
                await repo.updateUser(updated);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                AppToast.show(context, "Đã cập nhật thông tin thành công!", type: ToastType.success);
              } catch (e) {
                AppToast.show(context, "Lỗi: $e", type: ToastType.error);
              }
            }
          },
          child: const Text("Lưu"),
        ),
      ],
    );
  }

  void _showUserDeleteConfirmation(UserModel user) {
    DialogUtils.showConfirmDialog(
      context,
      title: "Xác nhận xóa thành viên",
      content: "Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản của \"${user.displayName ?? user.email}\"? Tác vụ này không thể khôi phục.",
      confirmText: "Xóa ngay",
      isDestructive: true,
      onConfirm: () async {
        try {
          final repo = context.read<SupabaseRepository>();
          await repo.deleteUser(user.id);
          if (!mounted) return;
          AppToast.show(context, "Đã xóa thành viên thành công!", type: ToastType.success);
        } catch (e) {
          AppToast.show(context, "Lỗi khi xóa thành viên: $e", type: ToastType.error);
        }
      },
    );
  }

  // 3. Courts Panel
  Widget _buildCourtsPanel(bool isOwner, String? userId, AdminDashboardViewModel vm) {
    final repo = context.read<SupabaseRepository>();
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Danh Sách Sân Đang Quản Lý",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 250,
                  height: 40,
                  child: TextField(
                    onChanged: (val) {
                      setState(() => _courtSearchQuery = val.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm cơ sở sân...",
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Redirect / Launch Add Court Screen or Dialog
                    AppToast.show(context, "Hãy chuyển sang ứng dụng mobile hoặc sử dụng form add sân", type: ToastType.success);
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Thêm Sân Mới"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),

        StreamBuilder<List<CourtLocationModel>>(
          stream: repo.getCourtLocationsStream(ownerId: isOwner ? userId : null),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
            }

            var courts = snapshot.data ?? [];
            if (_courtSearchQuery.isNotEmpty) {
              courts = courts.where((c) => c.name.toLowerCase().contains(_courtSearchQuery) || c.address.toLowerCase().contains(_courtSearchQuery)).toList();
            }

            if (courts.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Text("Chưa có cơ sở sân nào được tạo.", style: TextStyle(color: Colors.grey.shade500)),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, idx) {
                final court = courts[idx];
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Court image
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: court.imageUrl != null && court.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: court.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => CachedNetworkImage(
                                    imageUrl: _getDefaultSportImageUrl(court.sportType),
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: _getDefaultSportImageUrl(court.sportType),
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              court.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textBlack),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              court.address,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${formatCurrency.format(court.pricePerHour)}/h",
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${court.totalCourts} sân con",
                                    style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // 4. Bookings Panel
  Widget _buildBookingsPanel(bool isOwner, String? userId, AdminDashboardViewModel vm) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tất Cả Lịch Đặt Trực Tuyến & Giao Dịch",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                ),
                const SizedBox(height: 20),
                vm.bookings.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        alignment: Alignment.center,
                        child: Text("Không có giao dịch đặt sân nào.", style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Arial')),
                      )
                    : Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2.5),
                          3: FlexColumnWidth(1.5),
                          4: FlexColumnWidth(1.5),
                          5: FlexColumnWidth(1.5),
                          6: FlexColumnWidth(1),
                        },
                        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1)),
                        children: [
                          TableRow(
                            children: [
                              _buildTableHeader("Mã đơn"),
                              _buildTableHeader("Sân con"),
                              _buildTableHeader("Thời gian đặt"),
                              _buildTableHeader("Khách hàng"),
                              _buildTableHeader("Doanh thu"),
                              _buildTableHeader("Trạng thái"),
                              _buildTableHeader("Thao tác"),
                            ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: w)).toList(),
                          ),
                          ...vm.bookings.map((booking) {
                            final dateStr = DateFormat('dd/MM/yyyy').format(booking.date);
                            final timeStr = "${booking.timeSlot}:00 - ${booking.timeSlot + 1}:00";
                            return TableRow(
                              children: [
                                Text(
                                  "#${booking.id != null && booking.id!.length > 8 ? booking.id!.substring(0, 8).toUpperCase() : (booking.id ?? '').toUpperCase()}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
                                ),
                                Text("${booking.courtName} - Sân #${booking.courtNumber}", style: const TextStyle(fontFamily: 'Arial')),
                                Text("$dateStr\n$timeStr", style: const TextStyle(fontSize: 12, fontFamily: 'Arial')),
                                Text(vm.userNames[booking.userId] ?? booking.userName, style: const TextStyle(fontFamily: 'Arial')),
                                Text(formatCurrency.format(booking.price), style: const TextStyle(fontFamily: 'Arial')),
                                _buildStatusBadge(booking.status),
                                TextButton(
                                  onPressed: () {
                                    // Custom actions
                                    AppToast.show(context, "Chi tiết đơn hàng đã được in ra terminal", type: ToastType.success);
                                  },
                                  child: const Text("Chi tiết", style: TextStyle(fontFamily: 'Arial')),
                                ),
                              ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: w)).toList(),
                            );
                          }),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 5. Withdrawals Panel
  Widget _buildWithdrawalsPanel(bool isOwner, String? userId) {
    final repo = context.read<SupabaseRepository>();
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Yêu Cầu Rút Tiền Đang Chờ Duyệt (Pending Withdrawal Approvals)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                ),
                const SizedBox(height: 20),
                
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: repo.getPendingWithdrawalsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                    }

                    final reqs = snapshot.data ?? [];
                    if (reqs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        alignment: Alignment.center,
                        child: Text(
                          "Hiện tại không có yêu cầu rút tiền nào đang chờ duyệt.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2), // Creator info
                        1: FlexColumnWidth(1.5), // Amount
                        2: FlexColumnWidth(2.5), // Bank Info
                        3: FlexColumnWidth(1.5), // Created Date
                        4: FlexColumnWidth(1.5), // Actions
                      },
                      border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1)),
                      children: [
                        TableRow(
                          children: [
                            _buildTableHeader("Chủ sân / Đối tác"),
                            _buildTableHeader("Số tiền rút"),
                            _buildTableHeader("Thông tin Ngân hàng"),
                            _buildTableHeader("Ngày yêu cầu"),
                            _buildTableHeader("Quyết định"),
                          ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: w)).toList(),
                        ),
                        ...reqs.map((req) {
                          final amount = (req['amount'] as num?)?.toInt() ?? 0;
                          final bankInfo = req['bank_info'] ?? "Không có thông tin";
                          final createdStr = req['created_at'] != null 
                              ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(req['created_at']))
                              : "";
                          
                          return TableRow(
                            children: [
                              Text(req['user_id'] ?? "Chủ sân"),
                              Text(formatCurrency.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              Text(bankInfo),
                              Text(createdStr),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      _processWithdrawal(req['id'], 'SUCCESS');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text("Duyệt", style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      _processWithdrawal(req['id'], 'REJECTED');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text("Từ chối", style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ].map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: w)).toList(),
                          );
                        }),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _processWithdrawal(String txId, String status) {
    final statusText = status == 'SUCCESS' ? "phê duyệt" : "từ chối";
    DialogUtils.showConfirmDialog(
      context,
      title: "Xác nhận giao dịch",
      content: "Bạn có chắc chắn muốn $statusText yêu cầu rút tiền này?",
      confirmText: "Xác nhận",
      onConfirm: () async {
        try {
          final repo = context.read<SupabaseRepository>();
          await repo.updateWalletTransactionStatus(txId, status);
          if (!mounted) return;
          AppToast.show(context, "Đã xử lý yêu cầu rút tiền thành công!", type: ToastType.success);
        } catch (e) {
          AppToast.show(context, "Lỗi khi xử lý giao dịch: $e", type: ToastType.error);
        }
      },
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final int index;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
