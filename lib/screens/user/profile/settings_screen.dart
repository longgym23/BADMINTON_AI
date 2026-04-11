import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badminton_ai/services/push_notification_service.dart';
import 'package:badminton_ai/screens/user/profile/change_password_screen.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true; // Mặc định là bật

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  void _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  void _toggleNotification(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    // Xử lý bật tắt Push (FCM). 
    // Nếu tắt -> xóa token trên server. Nếu bật -> Khởi tạo lại.
    if (value) {
      PushNotificationService().initialize();
    } else {
      // Để triệt để khỏi bị làm phiền, xóa token khỏi DB (Backend không push được nữa)
      PushNotificationService().deleteToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
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
            // Cài đặt thông báo (Có Switch Tắt/Bật)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor, width: 0.5),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: SwitchListTile(
                activeColor: AppColors.primary,
                value: _notificationsEnabled,
                onChanged: _toggleNotification,
                secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.textBlack),
                title: const Text('Nhận thông báo', style: TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.w500)),
                subtitle: const Text('Báo về hệ thống khi có thay đổi', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.logout,
              title: 'Đăng xuất tài khoản',
              onTap: () {
                context.read<AppAuthProvider>().signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              iconColor: Colors.redAccent,
              titleColor: Colors.redAccent,
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
