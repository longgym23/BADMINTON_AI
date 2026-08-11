import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/data/models/booking_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/admin/views/pages/manage_bookings_screen.dart';
import 'package:badminton_ai/modules/admin/views/pages/manage_courts_screen.dart';
import 'package:badminton_ai/modules/admin/views/pages/manage_users_screen.dart';
import 'package:badminton_ai/modules/admin/views/pages/events/admin_event_list_screen.dart';
import 'package:badminton_ai/modules/admin/views/pages/admin_desktop_dashboard_screen.dart';
import 'package:badminton_ai/modules/admin/views/pages/manage_withdrawals_screen.dart';
import 'package:badminton_ai/modules/wallet/views/pages/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_date_range_picker_dialog.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/components/booking_history/calendar_theme.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  List<BookingModel> _last7DaysBookings = [];
  int _todayRevenue = 0;
  int _todayBookings = 0;

  int _filterMode = 3; // 0: DateRange, 1: Month, 2: Year, 3: 7 Days
  DateTimeRange? _selectedDateRange;
  int? _selectedMonth;
  int? _selectedYear;

  List<Map<String, dynamic>> _courtsList = [];
  String? _selectedCourtId;

  @override
  void initState() {
    super.initState();
    _fetchCourts().then((_) => _fetchDashboardData());
  }

  Future<void> _fetchCourts() async {
    final user = context.read<AppAuthProvider>().userModel;
    if (user == null) return;
    final isOwner = user.role == 'court_owner';
    final repo = context.read<SupabaseRepository>();
    final courts = await repo.getSimpleCourtsList(
      ownerId: isOwner ? user.id : null,
    );
    if (mounted) setState(() => _courtsList = courts);
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final user = context.read<AppAuthProvider>().userModel;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final isOwner = user.role == 'court_owner';
    final filterOwnerId = isOwner ? user.id : null;
    final repo = context.read<SupabaseRepository>();

    DateTime start, end;
    final now = DateTime.now();

    if (_filterMode == 0 && _selectedDateRange != null) {
      start = _selectedDateRange!.start;
      end = _selectedDateRange!.end;
    } else if (_filterMode == 1 &&
        _selectedMonth != null &&
        _selectedYear != null) {
      start = DateTime(_selectedYear!, _selectedMonth!, 1);
      end = DateTime(_selectedYear!, _selectedMonth! + 1, 0);
    } else if (_filterMode == 2 && _selectedYear != null) {
      start = DateTime(_selectedYear!, 1, 1);
      end = DateTime(_selectedYear!, 12, 31);
    } else {
      end = now;
      start = end.subtract(const Duration(days: 6));
    }

    try {
      final bookings = await repo.getBookingsForDateRange(
        start,
        end,
        ownerId: filterOwnerId,
        courtId: _selectedCourtId,
      );

      final validStates = ['PAID', 'confirmed', 'completed'];

      final validList = bookings.where((b) {
        final isValidStatus =
            validStates.contains(b.status.toUpperCase()) ||
            validStates.contains(b.status.toLowerCase());
        return isValidStatus;
      }).toList();

      int rev = 0;
      for (var b in validList) {
        rev += b.price;
      }

      setState(() {
        _last7DaysBookings = bookings;
        _todayBookings = validList.length;
        _todayRevenue = rev;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi fetch dashboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width > 900) {
      return const AdminDesktopDashboardScreen();
    }

    final user = context.watch<AppAuthProvider>().userModel;
    final isOwner = user?.role == 'court_owner';
    final isAdmin = user?.role == 'admin';

    String title = isOwner
        ? 'screens.stadiumOwnerManager'.tr()
        : isAdmin
        ? 'Super Admin'
        : 'screens.administrationPage'.tr();
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppAuthProvider>().signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VColors.brandPrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(user, isOwner),
                  const SizedBox(height: 16),
                  _buildRevenueCard(),
                  const SizedBox(height: 16),

                  _buildFilterControls(),
                  const SizedBox(height: 16),

                  Text(
                    'screens.rEVENUESTATISTICS'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBarChart(),
                  const SizedBox(height: 24),

                  Text(
                    'screens.sTATUSRATE'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPieChart(),
                  const SizedBox(height: 24),

                  Text(
                    'screens.mANAGEMENTTOOLS'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildToolGrid(isOwner, isAdmin),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader(user, bool isOwner) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: isOwner
              ? AssetImage('assets/images/personnel.gif')
              : AssetImage('assets/images/admin.gif'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, ${user?.displayName ?? user?.email ?? 'Quản trị viên'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: VColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isOwner
                    ? 'screens.roleStadiumOwner'.tr()
                    : 'screens.roleSuperAdmin'.tr(),
                style: const TextStyle(fontSize: 14, color: VColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VColors.brandPrimaryDark, VColors.brandPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: VColors.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'screens.tOTALREVENUE'.tr(),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: _glassDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_todayBookings lượt',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.simpleCurrency(
              locale: 'vi_VN',
              decimalDigits: 0,
            ).format(_todayRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Tiện ích làm background mờ (Glassmorphism)
  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1.5,
      ),
    );
  }

  Widget _buildBarChart() {
    if (_last7DaysBookings.isEmpty) {
      return _emptyCard('screens.noTransactionDataYet'.tr());
    }

    final validStates = ['PAID', 'confirmed', 'completed'];
    Map<int, double> groupedRevenue = {};
    int totalBars = 0;

    DateTime start, end;
    final now = DateTime.now();
    if (_filterMode == 0 && _selectedDateRange != null) {
      start = _selectedDateRange!.start;
      end = _selectedDateRange!.end;
    } else if (_filterMode == 1 &&
        _selectedMonth != null &&
        _selectedYear != null) {
      start = DateTime(_selectedYear!, _selectedMonth!, 1);
      end = DateTime(_selectedYear!, _selectedMonth! + 1, 0);
    } else if (_filterMode == 2 && _selectedYear != null) {
      start = DateTime(_selectedYear!, 1, 1);
      end = DateTime(_selectedYear!, 12, 31);
    } else {
      end = now;
      start = end.subtract(const Duration(days: 6));
    }

    if (_filterMode == 2) {
      totalBars = 12;
      for (int i = 1; i <= 12; i++) {
        groupedRevenue[i] = 0;
      }
      for (var b in _last7DaysBookings) {
        if (validStates.contains(b.status.toUpperCase()) ||
            validStates.contains(b.status.toLowerCase())) {
          groupedRevenue[b.date.month] =
              (groupedRevenue[b.date.month] ?? 0) + b.price;
        }
      }
    } else {
      totalBars = end.difference(start).inDays + 1;
      if (totalBars < 1) totalBars = 1;
      for (int i = 0; i < totalBars; i++) {
        groupedRevenue[i] = 0;
      }

      for (var b in _last7DaysBookings) {
        if (validStates.contains(b.status.toUpperCase()) ||
            validStates.contains(b.status.toLowerCase())) {
          final diff = b.date.difference(start).inDays;
          if (diff >= 0 && diff < totalBars) {
            groupedRevenue[diff] = (groupedRevenue[diff] ?? 0) + b.price;
          }
        }
      }
    }

    double maxRevenueLimit = 100000000;
    double barW = (220 / totalBars).clamp(4.0, 24.0);

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < totalBars; i++) {
      final key = _filterMode == 2 ? i + 1 : i;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: groupedRevenue[key] ?? 0,
              color: VColors.brandPrimary,
              width: barW,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VColors.borderDefault, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxRevenueLimit,
          barTouchData: BarTouchData(
            enabled: false,
          ), // Đơn giản hóa, không hiện tooltip
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (_filterMode == 2) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'T${value.toInt() + 1}',
                        style: const TextStyle(
                          color: VColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  final int total = end.difference(start).inDays + 1;
                  if (total > 15 &&
                      value.toInt() % 7 != 0 &&
                      value.toInt() != total - 1 &&
                      value.toInt() != 0) {
                    return const SizedBox();
                  }

                  final d = start.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(
                        color: VColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 20000000,
                getTitlesWidget: (value, meta) {
                  if (value % 20000000 != 0) return const SizedBox();
                  String title = (value / 1000000).toInt().toString();
                  return Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: VColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20000000, // Khoảng cách lưới 20tr
            getDrawingHorizontalLine: (val) => FlLine(
              color: VColors.textSecondary.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_last7DaysBookings.isEmpty) return _emptyCard('screens.noDataYet'.tr());

    int paid = 0;
    int pending = 0;
    int cancelled = 0;

    for (var b in _last7DaysBookings) {
      final s = b.status.toUpperCase();
      if (s == 'PAID' || s == 'CONFIRMED' || s == 'COMPLETED') {
        paid++;
      } else if (s == 'CANCELLED') {
        cancelled++;
      } else {
        pending++;
      }
    }

    final total = paid + pending + cancelled;
    if (total == 0) return _emptyCard('screens.thereAreNoBookingsYet'.tr());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  if (paid > 0)
                    PieChartSectionData(
                      color: Colors.green,
                      value: paid.toDouble(),
                      title: '${((paid / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (pending > 0)
                    PieChartSectionData(
                      color: Colors.orange,
                      value: pending.toDouble(),
                      title: '${((pending / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (cancelled > 0)
                    PieChartSectionData(
                      color: Colors.redAccent,
                      value: cancelled.toDouble(),
                      title:
                          '${((cancelled / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _indicator(Colors.green, 'Thành công ($paid)'),
              _indicator(Colors.orange, 'Đang chờ ($pending)'),
              _indicator(Colors.redAccent, 'Đã hủy ($cancelled)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: VColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildToolGrid(bool isOwner, bool isAdmin) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildGridAction(
          title: isOwner
              ? 'screens.lChTCATI'.tr()
              : 'screens.manageBookingSchedule'.tr(),
          icon: Icons.calendar_month_rounded,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ManageBookingsScreen()),
          ),
        ),
        _buildGridAction(
          title: isOwner
              ? 'screens.stadiumEvents'.tr()
              : 'screens.eventManagement'.tr(),
          icon: Icons.event,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminEventListScreen()),
          ),
        ),
        _buildGridAction(
          title: isOwner
              ? 'screens.yardList'.tr()
              : 'screens.locationManagement'.tr(),
          icon: Icons.sports_tennis_rounded,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ManageCourtsScreen()),
          ),
        ),
        if (isOwner)
          _buildGridAction(
            title: 'Ví doanh thu',
            icon: Icons.account_balance_wallet,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
          ),
        if (isAdmin) ...[
          _buildGridAction(
            title: 'screens.usersPermissions'.tr(),
            icon: Icons.people_alt_rounded,
            color: Colors.redAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
            ),
          ),
          _buildGridAction(
            title: 'Yêu cầu rút tiền',
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageWithdrawalsScreen()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGridAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: VColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: VColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // Tiện ích Dropdown Lọc + Nút lọc thời gian
  Widget _buildFilterControls() {
    final timeFilterWidget = Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<int>(
        color: VColors.brandPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 4,
        offset: const Offset(0, 45),
        onSelected: (value) {
          if (value == 0) {
            _pickDateRange(context);
          } else if (value == 1) {
            _pickMonth(context);
          } else if (value == 2) {
            _pickYear(context);
          } else {
            setState(() => _filterMode = 3);
            _fetchDashboardData();
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem(0, 'screens.selectDateRange'.tr()),
          _buildMenuItem(1, 'screens.filterByMonth'.tr()),
          _buildMenuItem(2, 'screens.filterByYear'.tr()),
          _buildMenuItem(3, 'screens.last7Days'.tr()),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: VColors.brandPrimary),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _filterMode == 3 ? 'screens.last7Days'.tr() : _getFilterLabel(),
                style: const TextStyle(
                  color: Color.fromARGB(255, 108, 108, 108),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.calendar_month,
                color: VColors.brandPrimary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );

    // Nếu không có danh sách sân => chỉ hiện nút lọc thời gian
    if (_courtsList.isEmpty) {
      return Align(alignment: Alignment.centerLeft, child: timeFilterWidget);
    }

    // Có danh sách sân => hiện cả 2 cùng 1 hàng
    return Row(
      children: [
        // Dropdown chọn sân (chiếm phần lớn chiều ngang)
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VColors.borderDefault),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCourtId,
                hint: Text(
                  'screens.allYards'.tr(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: VColors.brandPrimary,
                  size: 20,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: VColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'screens.allYards'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ..._courtsList.map(
                    (c) => DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(
                        c['name'],
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedCourtId = val);
                  _fetchDashboardData();
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Nút lọc thời gian
        timeFilterWidget,
      ],
    );
  }

  String _getFilterLabel() {
    if (_filterMode == 0 && _selectedDateRange != null) {
      return '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    } else if (_filterMode == 1 && _selectedMonth != null) {
      return 'Tháng $_selectedMonth/$_selectedYear';
    } else if (_filterMode == 2 && _selectedYear != null) {
      return 'Năm $_selectedYear';
    }
    return 'screens.last7Days'.tr();
  }

  PopupMenuItem<int> _buildMenuItem(int value, String text) {
    return PopupMenuItem<int>(
      value: value,
      height: 40,
      padding: EdgeInsets.zero,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color.fromARGB(255, 248, 255, 252),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final result = await showCustomDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      cancelLabel: 'screens.cancel'.tr(),
      confirmLabel: 'screens.select'.tr(),
    );
    if (result != null) {
      setState(() {
        _filterMode = 0;
        _selectedDateRange = result;
      });
      _fetchDashboardData();
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    int tempMonth = _selectedMonth ?? now.month;
    int tempYear = _selectedYear ?? now.year;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: BookingCalendarTheme.dialogShape,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          content: SizedBox(
            width: BookingCalendarTheme.dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BookingCalendarTheme.yearNavigator(
                  label: '$tempYear',
                  onPrevious: () => setStateDialog(() => tempYear--),
                  onNext: () => setStateDialog(() => tempYear++),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final selected = m == tempMonth;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => tempMonth = m),
                      child: Container(
                        decoration: BookingCalendarTheme.gridItemDecoration(
                          selected: selected,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Tháng $m',
                          style: BookingCalendarTheme.gridItemTextStyle(
                            selected: selected,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BookingCalendarTheme.cancelButton(
                  onPressed: () => Navigator.pop(ctx),
                  label: 'screens.cancel'.tr(),
                ),
                const SizedBox(width: 16),
                BookingCalendarTheme.confirmButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMode = 1;
                      _selectedMonth = tempMonth;
                      _selectedYear = tempYear;
                    });
                    _fetchDashboardData();
                  },
                  label: 'screens.select'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickYear(BuildContext context) async {
    final now = DateTime.now();
    int tempYear = _selectedYear ?? now.year;
    int startYear = (tempYear ~/ 12) * 12;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: BookingCalendarTheme.dialogShape,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          content: SizedBox(
            width: BookingCalendarTheme.dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BookingCalendarTheme.yearNavigator(
                  label: '$startYear - ${startYear + 11}',
                  onPrevious: () => setStateDialog(() => startYear -= 12),
                  onNext: () => setStateDialog(() => startYear += 12),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: List.generate(12, (i) {
                    final year = startYear + i;
                    final selected = year == tempYear;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => tempYear = year),
                      child: Container(
                        decoration: BookingCalendarTheme.gridItemDecoration(
                          selected: selected,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$year',
                          style: BookingCalendarTheme.gridItemTextStyle(
                            selected: selected,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BookingCalendarTheme.cancelButton(
                  onPressed: () => Navigator.pop(ctx),
                  label: 'screens.cancel'.tr(),
                ),
                const SizedBox(width: 16),
                BookingCalendarTheme.confirmButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMode = 2;
                      _selectedYear = tempYear;
                    });
                    _fetchDashboardData();
                  },
                  label: 'screens.select'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
