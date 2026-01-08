import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/user/booking_history_screen.dart'; // <-- THÊM IMPORT
import 'package:badminton_ai/screens/user/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Tab 4: Tài khoản
class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tài khoản của tôi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: user == null
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.secondary))
          : ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  child: Icon(Icons.person,
                      size: 60, color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(height: 15),
                Center(
                  child: Text(
                    user.displayName ?? 'Chưa cập nhật tên',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.black),
                  ),
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    user.email ?? 'Không có email', // Sửa lỗi null
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.black),
                  ),
                ),
                SizedBox(height: 16),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            user.phoneNumber!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 25),
                Card(
                  // Sử dụng Card để nhóm các mục
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(Icons.history,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text('Lịch sử đặt sân',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      // SỬA LỖI: Mở màn hình lịch sử đặt sân
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(Icons.edit,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text('Chỉnh sửa thông tin',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout,
                        color: Theme.of(context).colorScheme.error),
                    title: Text('Đăng xuất',
                        style:
                            TextStyle(color: Theme.of(context).colorScheme.error)),
                    onTap: () {
                      context.read<AppAuthProvider>().signOut();
                      // SplashScreen sẽ tự động điều hướng về Login
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

