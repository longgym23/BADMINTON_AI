import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/user/booking/booking_history_screen.dart';
import 'package:badminton_ai/screens/user/profile/edit_profile_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/screens/user/friends/friends_main_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hồ sơ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textBlack),
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Avatar & Info Section
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user.displayName ?? 'Chưa cập nhật tên',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email ?? 'Không có email',
              style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'THÀNH VIÊN VÀNG',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Row (Mock Data)
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.sports_tennis,
                  value: '12',
                  label: 'TRẬN ĐẤU',
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.access_time_filled,
                  value: '24h',
                  label: 'GIỜ CHƠI',
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.emoji_events,
                  value: '68%',
                  label: 'THẮNG',
                  color: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Menu Options
            _buildMenuItem(
              context,
              icon: Icons.edit,
              color: Colors.blue,
              title: 'Chỉnh sửa thông tin',
              subtitle: 'Cập nhật tên, số điện thoại',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.history,
              color: Colors.purple,
              title: 'Lịch sử đặt sân',
              subtitle: 'Xem lại các trận đấu đã đặt',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingHistoryScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.account_balance_wallet,
              color: AppColors.success,
              title: 'Ví của tôi',
              // trailingText: '500k đ',
              onTap: () {
                // Wallet action
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications,
              color: AppColors.textGrey,
              title: 'Thông báo',
              isSwitch: true,
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              color: AppColors.textGrey,
              title: 'Hỗ trợ & Chính sách',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.group,
              color: AppColors.primary,
              title: 'Cộng đồng & Bạn bè',
              subtitle: 'Tìm bạn, quản lý kết bạn',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FriendsMainScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Logout Button
            InkWell(
              onTap: () {
                context.read<AppAuthProvider>().signOut();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.errorBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    String? trailingText,
    bool isSwitch = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textBlack,
          ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              )
            : null,
        trailing: isSwitch
            ? CupertinoSwitch(
                value: true,
                activeColor: AppColors.success,
                onChanged: (val) {},
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailingText != null)
                    Text(
                      trailingText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontSize: 14,
                      ),
                    ),
                  if (trailingText != null) const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}
