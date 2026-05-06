import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('profile_screen.uploadingAvatar'.tr())),
    );
    final success = await authProvider.updateUserAvatar(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'profile_screen.avatarUpdateSuccess'.tr()
              : 'profile_screen.avatarUpdateFailed'.tr(),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Container(
          padding: EdgeInsets.only(
            top: 16,
            bottom: 32,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'settings_screen.selectLanguage'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'settings_screen.languagePreference'.tr(),
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              SizedBox(height: 24),
              _LangOption(
                flag: '🇻🇳',
                label: 'settings_screen.languageVietnamese'.tr(),
                isSelected: langProvider.isVietnamese,
                onTap: () async {
                  // Dùng outer context để setLocale ảnh hưởng toàn app
                  await langProvider.setVietnamese(context);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              SizedBox(height: 12),
              _LangOption(
                flag: '🇺🇸',
                label: 'settings_screen.languageEnglish'.tr(),
                isSelected: !langProvider.isVietnamese,
                onTap: () async {
                  await langProvider.setEnglish(context);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final langProvider = context.watch<LanguageProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AppAuthProvider>().reloadUserModel();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Section (Orange Gradient)
              Container(
                decoration: BoxDecoration(
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
                padding: EdgeInsets.only(
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
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage: user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? Text(
                                      user.displayName?[0].toUpperCase() ?? 'U',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandOrange,
                                      ),
                                    )
                                  : null,
                            ),
                            if (authProvider.isUpdatingProfile)
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ??
                                        'profile_screen.noName'.tr(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user.email ?? 'profile_screen.noEmail'.tr(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),

              // Quick Actions (4 Boxes)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionBtn(
                        icon: Image.asset(
                          'assets/images/calendar.png',
                          width: 28,
                          height: 28,
                        ),
                        label: 'profile_screen.bookedCourts'.tr(),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingHistoryScreen(),
                          ),
                        ),
                      ),
                      _buildQuickActionBtn(
                        icon: Image.asset(
                          'assets/images/notification.png',
                          width: 28,
                          height: 28,
                        ),
                        label: 'profile_screen.notifications'.tr(),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                      ),
                      _buildQuickActionBtn(
                        icon: Image.asset(
                          'assets/images/certificate.png',
                          width: 28,
                          height: 28,
                        ),
                        label: 'profile_screen.courses'.tr(),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CourseMainScreen(),
                          ),
                        ),
                      ),
                      _buildQuickActionBtn(
                        icon: Image.asset(
                          'assets/images/gift.png',
                          width: 28,
                          height: 28,
                        ),
                        label: 'profile_screen.offers'.tr(),
                        onPressed: () =>
                            NotificationUtils.showComingSoon(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Content Lists
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ví Nội Bộ Card
                    Container(
                      margin: EdgeInsets.only(bottom: 24),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'profile_screen.walletBalance'.tr(),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  NumberFormat.simpleCurrency(
                                    locale: 'vi_VN',
                                    decimalDigits: 0,
                                  ).format(user.balance),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              NotificationUtils.showComingSoon(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                            ),
                            child: Text(
                              'profile_screen.deposit'.tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (user.role == 'admin') ...[
                      Text(
                        'profile_screen.adminManagement'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildListSection([
                        _buildListItem(
                          icon: Icons.store,
                          title: 'profile_screen.manageBookings'.tr(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageBookingsScreen(),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: AppColors.borderColor),
                        _buildListItem(
                          icon: Icons.event,
                          title: 'profile_screen.manageEvents'.tr(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminEventListScreen(),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: AppColors.borderColor),
                        _buildListItem(
                          icon: Icons.people,
                          title: 'profile_screen.customerInfo'.tr(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageUsersScreen(),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: AppColors.borderColor),
                        _buildListItem(
                          icon: Icons.add_home_work,
                          title: 'profile_screen.manageCourts'.tr(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageCourtsScreen(),
                            ),
                          ),
                        ),
                      ]),
                      SizedBox(height: 24),
                    ],

                    Text(
                      'profile_screen.activity'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.brandOrangeDark,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildListSection([
                      _buildListItem(
                        icon: Icons.favorite,
                        title: 'profile_screen.favoriteCourts'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FavoritesScreen(),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.borderColor),
                      _buildListItem(
                        icon: Icons.school,
                        title: 'profile_screen.courseList'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WatchedCoursesScreen(),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.borderColor),
                      _buildListItem(
                        icon: Icons.dashboard,
                        title: 'profile_screen.statistics'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatisticsScreen(),
                          ),
                        ),
                      ),
                    ]),

                    SizedBox(height: 24),

                    Text(
                      'profile_screen.system'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.brandOrangeDark,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildListSection([
                      _buildListItem(
                        icon: Icons.language,
                        title: 'settings_screen.language'.tr(),
                        subtitle: langProvider.isVietnamese
                            ? 'settings_screen.languageVietnamese'.tr()
                            : 'settings_screen.languageEnglish'.tr(),
                        onTap: () => _showLanguageDialog(context),
                      ),
                      Divider(height: 1, color: AppColors.borderColor),
                      _buildListItem(
                        icon: Icons.settings,
                        title: 'profile_screen.settings'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.borderColor),
                      _buildListItem(
                        icon: Icons.info,
                        title: 'profile_screen.appVersion'.tr(),
                        onTap: () {},
                      ),
                    ]),
                    // Warning / Security Banner
                    SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                    ), // Add padding for bottom navigation logic
                  ],
                ),
              ),
            ],
          ),
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
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
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
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
        boxShadow: [
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
      leading: Icon(
        icon,
        color: Color.fromARGB(255, 229, 130, 16),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textBlack, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textGrey,
        size: 20,
      ),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Text(flag, style: TextStyle(fontSize: 22)),
            SizedBox(width: 12),
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
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

