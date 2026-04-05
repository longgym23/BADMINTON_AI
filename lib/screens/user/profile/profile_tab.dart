import 'dart:io';
import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/language_provider.dart';
import 'package:badminton_ai/screens/user/booking/booking_history_screen.dart';
import 'package:badminton_ai/screens/user/notifications/notifications_screen.dart';
import 'package:badminton_ai/screens/user/profile/edit_profile_screen.dart';
import 'package:badminton_ai/screens/user/profile/favorites_screen.dart';
import 'package:badminton_ai/screens/user/profile/settings_screen.dart';
import 'package:badminton_ai/screens/user/profile/statistics_screen.dart';
import 'package:badminton_ai/screens/course/course_main_screen.dart';
import 'package:badminton_ai/screens/course/watched_courses_screen.dart';
import 'package:badminton_ai/screens/admin/events/admin_event_list_screen.dart';
import 'package:badminton_ai/screens/admin/manage_bookings_screen.dart';
import 'package:badminton_ai/screens/admin/manage_courts_screen.dart';
import 'package:badminton_ai/screens/admin/manage_users_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/utils/notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final authProvider = context.read<AppAuthProvider>();
    final l = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.uploadingAvatar)));
    final success = await authProvider.updateUserAvatar(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? l.avatarUpdateSuccess : l.avatarUpdateFailed)),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    final langProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.selectLanguage, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangOption(
              flag: '🇻🇳',
              label: l.languageVietnamese,
              isSelected: langProvider.isVietnamese,
              onTap: () {
                langProvider.setVietnamese();
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _LangOption(
              flag: '🇺🇸',
              label: l.languageEnglish,
              isSelected: !langProvider.isVietnamese,
              onTap: () {
                langProvider.setEnglish();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final l = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section (Orange Gradient)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandOrangeDark,
                    AppColors.brandOrangeLight,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 60,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Column(
                children: [
                  // User Info Card
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(context),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  backgroundImage: user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null
                                      ? Text(
                                          user.displayName?[0].toUpperCase() ??
                                              'U',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brandOrange,
                                          ),
                                        )
                                      : null,
                                ),
                                if (authProvider.isUpdatingProfile)
                                  const Positioned.fill(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? l.noName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email ?? l.noEmail,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Quick Actions (4 Boxes)
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickActionBtn(
                      icon: Image.asset('assets/images/calendar.png', width: 28, height: 28),
                      label: l.bookedCourts,
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BookingHistoryScreen())),
                    ),
                    _buildQuickActionBtn(
                      icon: Image.asset('assets/images/notification.png', width: 28, height: 28),
                      label: l.notifications,
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    ),
                    _buildQuickActionBtn(
                      icon: Image.asset('assets/images/certificate.png', width: 28, height: 28),
                      label: l.courses,
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CourseMainScreen())),
                    ),
                    _buildQuickActionBtn(
                      icon: Image.asset('assets/images/gift.png', width: 28, height: 28),
                      label: l.offers,
                      onPressed: () => NotificationUtils.showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content Lists
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.role == 'admin') ...[
                    const Text(
                      'QUẢN LÝ ADMIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildListSection([
                      _buildListItem(
                        icon: Icons.store, 
                        title: 'Quản lý lịch đặt', 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageBookingsScreen())),
                      ),
                      const Divider(height: 1, color: AppColors.borderColor),
                      _buildListItem(
                        icon: Icons.event,
                        title: 'Quản lý sự kiện sân',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEventListScreen())),
                      ),
                      const Divider(height: 1, color: AppColors.borderColor),
                      _buildListItem(
                        icon: Icons.people, 
                        title: 'Thông tin khách hàng', 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                      ),
                      const Divider(height: 1, color: AppColors.borderColor),
                      _buildListItem(
                        icon: Icons.add_home_work, 
                        title: 'Thêm / Quản lý sân mới', 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageCourtsScreen())),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    l.activity,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.brandOrangeDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildListSection([
                    _buildListItem(icon: Icons.favorite, title: l.favoriteCourts,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
                    const Divider(height: 1, color: AppColors.borderColor),
                    _buildListItem(icon: Icons.school, title: l.courseList,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchedCoursesScreen()))),
                    const Divider(height: 1, color: AppColors.borderColor),
                    _buildListItem(icon: Icons.dashboard, title: l.statistics,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()))),
                  ]),

                  const SizedBox(height: 24),

                  Text(
                    l.system,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.brandOrangeDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildListSection([
                    _buildListItem(icon: Icons.language, title: l.language,
                        subtitle: langProvider.isVietnamese ? l.languageVietnamese : l.languageEnglish,
                        onTap: () => _showLanguageDialog(context)),
                    const Divider(height: 1, color: AppColors.borderColor),
                    _buildListItem(icon: Icons.settings, title: l.settings,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                    const Divider(height: 1, color: AppColors.borderColor),
                    _buildListItem(icon: Icons.info, title: l.appVersion, onTap: () {}),
                  ]),
                  // Warning / Security Banner
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 120,
                  ), // Add padding for bottom navigation logic
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color.fromARGB(255, 229, 130, 16), size: 24),
      title: Text(title, style: const TextStyle(color: AppColors.textBlack, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
    );
  }
}

// ─── Language Option Tile ─────────────────────────────────────────────────────

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textBlack,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
