import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.brandOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Cài đặt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              context,
              icon: Icons.notifications_active_outlined,
              title: 'Cài đặt thông báo',
              onTap: () {},
            ),
            _buildSettingItem(
              context,
              icon: Icons.language_outlined,
              title: 'Ngôn ngữ - Tiếng Việt',
              onTap: () {},
            ),
            _buildSettingItem(
              context,
              icon: Icons.lock_outline,
              title: 'Đổi mật khẩu',
              onTap: () {},
            ),
            _buildSettingItem(
              context,
              icon: Icons.logout,
              title: 'Đăng xuất tài khoản',
              onTap: () {
                context.read<AppAuthProvider>().signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color titleColor = AppColors.textBlack,
    Color iconColor = AppColors.textBlack,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
      ),
    );
  }
}
