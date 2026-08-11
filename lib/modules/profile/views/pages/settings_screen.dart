import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badminton_ai/core/services/push_notification_service.dart';
import 'package:badminton_ai/modules/profile/views/pages/change_password_screen.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

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
        title: Text('screens.setting'.tr(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cài đặt thông báo (Có Switch Tắt/Bật)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VColors.borderDefault, width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: SwitchListTile(
                activeThumbColor: VColors.brandPrimary,
                value: _notificationsEnabled,
                onChanged: _toggleNotification,
                secondary: Icon(Icons.notifications_active_outlined, color: VColors.textPrimary),
                title: Text('screens.receiveNotifications'.tr(), style: TextStyle(color: VColors.textPrimary, fontWeight: FontWeight.w500)),
                subtitle: Text('screens.reportToTheSystemWhenTher'.tr(), style: TextStyle(fontSize: 12, color: VColors.textSecondary)),
              ),
            ),
            _buildSettingItem(
              context,
              icon: Icons.lock_outline,
              title: 'screens.changePassword'.tr(),
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
              title: 'screens.signOutOfYourAccount'.tr(),
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
    Color titleColor = VColors.textPrimary,
    Color iconColor = VColors.textPrimary,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VColors.borderDefault, width: 0.5),
        boxShadow: [
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
        trailing: Icon(Icons.chevron_right, color: VColors.textSecondary),
      ),
    );
  }
}
