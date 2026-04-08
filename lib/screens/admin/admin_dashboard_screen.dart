import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/admin/manage_bookings_screen.dart';
import 'package:badminton_ai/screens/admin/manage_courts_screen.dart';
import 'package:badminton_ai/screens/admin/manage_users_screen.dart';
import 'package:badminton_ai/screens/admin/events/admin_event_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().userModel;
    final isOwner = user?.role == 'court_owner';
    final isAdmin = user?.role == 'admin';

    // Xác định title
    String title = 'Trang Quản Trị';
    if (isOwner) title = 'Quản lý Chủ Sân';
    else if (isAdmin) title = 'Super Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AppAuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Welcome Section
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.shield, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, ${user?.displayName ?? user?.email}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOwner ? 'Vai trò: Chủ Sân' : 'Vai trò: Quản trị viên Max',
                        style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue Section
            _buildRevenueSection(context, user?.id, isOwner),
            
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('CÔNG CỤ QUẢN LÝ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
            ),
            const SizedBox(height: 12),

            // Các nút chức năng Chung
            _buildActionCard(
              context, 
              title: isOwner ? 'Lịch Đặt Sân Của Tôi' : 'Tất Cả Lịch Đặt', 
              icon: Icons.calendar_month_rounded, 
              color: Colors.blue, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageBookingsScreen()))
            ),
            _buildActionCard(
              context, 
              title: isOwner ? 'Sự Kiện Sân Của Tôi' : 'Quản Lý Sự Kiện Toàn Cục', 
              icon: Icons.event, 
              color: Colors.orange, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEventListScreen()))
            ),
            _buildActionCard(
              context, 
              title: isOwner ? 'Xem Danh Sách Sân Của Tôi' : 'Quản Lý Tất Cả Địa Điểm', 
              icon: Icons.sports_tennis_rounded, 
              color: Colors.green, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageCourtsScreen()))
            ),

            // Các nút dành riêng cho Admin
            if (isAdmin)
              _buildActionCard(
                context, 
                title: 'Quản Lý Người Dùng & Phân Quyền', 
                icon: Icons.people_alt_rounded, 
                color: Colors.redAccent, 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen()))
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSection(BuildContext context, String? userId, bool isOwner) {
    if (userId == null) return const SizedBox();
    
    // Lấy stream theo ownerId nếu là court_owner, null nếu là admin
    final repo = context.read<SupabaseRepository>();
    final filterOwnerId = isOwner ? userId : null;

    return StreamBuilder<List<BookingModel>>(
      stream: repo.getAllBookingsForDay(DateTime.now(), ownerId: filterOwnerId),
      builder: (context, snapshot) {
        int todayRevenue = 0;
        int todayBookings = 0;

        if (snapshot.hasData && snapshot.data != null) {
          final bookings = snapshot.data!;
          // Lọc các booking được xác nhận / đã thanh toán
          final validStates = ['PAID', 'confirmed', 'completed'];
          final validBookings = bookings.where((b) => validStates.contains(b.status.toUpperCase()) || validStates.contains(b.status.toLowerCase())).toList();
          
          todayBookings = validBookings.length;
          todayRevenue = validBookings.fold(0, (sum, b) => sum + b.price);
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.brandOrangeDark, AppColors.brandOrangeLight]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.brandOrange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              const Text('HÔM NAY', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting)
                const CircularProgressIndicator(color: Colors.white)
              else
                Text(
                  NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(todayRevenue),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              Text('${snapshot.connectionState == ConnectionState.waiting ? "..." : todayBookings} Lượt khách đặt', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textBlack)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
