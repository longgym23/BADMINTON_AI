import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // White background for the whole screen
    final authProvider = context.watch<AppAuthProvider>();
    final userId = authProvider.userModel?.id;
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background like the design
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (userId != null)
            IconButton(
              onPressed: () {
                notificationProvider.markAllAsRead(userId);
              },
              icon: const Icon(Icons.done_all, color: Colors.grey),
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem thông báo'))
          : StreamBuilder<List<NotificationModel>>(
              stream: notificationProvider.getNotificationsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có thông báo nào',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Group notifications
                final now = DateTime.now();
                final todayNotifications = <NotificationModel>[];
                final olderNotifications = <NotificationModel>[];

                for (var notification in notifications) {
                  final date = notification.createdAt;
                  if (date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day) {
                    todayNotifications.add(notification);
                  } else {
                    olderNotifications.add(notification);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (todayNotifications.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'HÔM NAY',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...todayNotifications.map(
                        (n) => _NotificationCard(notification: n),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (olderNotifications.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'CŨ HƠN',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...olderNotifications.map(
                        (n) => _NotificationCard(notification: n),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  Future<void> _launchMaps(String address) async {
    // Simple encoding for query
    final query = Uri.encodeComponent(address);
    final googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBooking = notification.type == 'booking_success';
    final isReminder =
        notification.type ==
        'reminder'; // Assuming 'reminder' type exists or mapping to it
    final isPayment =
        notification.type == 'payment_success'; // Assuming 'payment_success'

    // Determine Icon and Color
    IconData iconData = Icons.notifications;
    Color iconColor = Colors.blue;
    Color iconBgColor = Colors.blue.withOpacity(0.1);

    if (isBooking) {
      iconData = Icons.check;
      iconColor = Colors.white;
      iconBgColor = const Color(0xFF4ADE80); // Green 400
    } else if (isPayment) {
      iconData = Icons.history;
      iconColor = Colors.grey[600]!;
      iconBgColor = Colors.grey[200]!;
    } else if (isReminder) {
      iconData = Icons.calendar_today;
      iconColor = Colors.blue[600]!;
      iconBgColor = Colors.blue[100]!;
    } else if (notification.type == 'booking_success') {
      // Fallback/Double check logic
      iconData = Icons.check;
      iconColor = Colors.white;
      iconBgColor = Colors.green[400]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationProvider>().markAsRead(notification.id!);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Heading
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title + Time + Dot
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 4, top: 2),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                      // Details Box (Only for booking/specific types that have details)
                      if (isBooking || notification.courtName != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB), // Very light grey
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                Icons.location_on,
                                notification.courtAddress ?? 'Không xác định',
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.calendar_today,
                                '${DateFormat('dd/MM/yyyy').format(notification.bookingDate ?? DateTime.now())} • ${notification.timeSlot ?? 0}:00 - ${(notification.timeSlot ?? 0) + 1}:00',
                              ), // Fallback time logic
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.sports_tennis,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sân ${notification.courtNumber ?? "1"}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    notification.price != null
                                        ? NumberFormat.simpleCurrency(
                                            locale: 'vi_VN',
                                            decimalDigits: 0,
                                          ).format(notification.price)
                                        : '0 đ',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Directions Button
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              if (notification.courtAddress != null) {
                                _launchMaps(notification.courtAddress!);
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue[50],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.directions,
                              size: 18,
                              color: Colors.blue,
                            ),
                            label: const Text(
                              'Chỉ đường',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Specific UI for Payment success (simpler details)
                      if (isPayment &&
                          notification.message.contains('Mã GD')) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                // Extract transaction ID properly or just hardcode for demo if not in model
                                'Mã GD: #Transaction-${notification.id?.substring(0, 4) ?? "0000"}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
