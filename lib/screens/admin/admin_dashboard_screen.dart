import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/admin/manage_bookings_screen.dart';
import 'package:badminton_ai/screens/admin/manage_courts_screen.dart';
import 'package:badminton_ai/screens/admin/manage_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang Quản Trị (Admin)'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              context.read<AppAuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
              Text(
                'Chào mừng Admin, ${user?.displayName ?? user?.email}!',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppColors.textBlack),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              // Các nút chức năng
              ElevatedButton.icon(
                onPressed: () {
                  // 2. SỬA CHỖ NÀY: Mở màn hình quản lý booking
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageBookingsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.calendar_month_rounded),
                label: Text('Quản lý Lịch đặt'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageCourtsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.sports_tennis_rounded),
                label: Text('Quản lý Địa điểm Sân'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageUsersScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.people_alt_rounded),
                label: Text('Quản lý Người dùng'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
