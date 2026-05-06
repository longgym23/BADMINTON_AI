import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // White background for the whole screen
    final authProvider = context.watch<AppAuthProvider>();
    final userId = authProvider.userModel?.id;
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(
          'notification_screen.title'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (userId != null)
            IconButton(
              onPressed: () {
                notificationProvider.markAllAsRead(userId);
              },
              icon: Icon(Icons.done_all, color: Colors.white),
              tooltip: 'notification_screen.markAllAsRead'.tr(),
            ),
        ],
      ),
      body: userId == null
          ? Center(child: Text('notification_screen.pleaseLoginToView'.tr()))
          : StreamBuilder<List<NotificationModel>>(
              stream: notificationProvider.getNotificationsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('${'notification_screen.error'.tr()}${snapshot.error}'));
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
                        SizedBox(height: 16),
                        Text(
                          'notification_screen.noNotifications'.tr(),
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
                  padding: EdgeInsets.all(16),
                  children: [
                    if (todayNotifications.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'notification_screen.today'.tr(),
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
                      SizedBox(height: 20),
                    ],
                    if (olderNotifications.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'notification_screen.older'.tr(),
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

    // Trích xuất dữ liệu từ chuỗi message (Vì database không sinh ra metadata chi tiết)
    String address = notification.courtAddress ?? 'notification_screen.unknown'.tr();
    String priceText = notification.price != null ? NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(notification.price) : 'screens.0Pt'.tr();
    String dateText = '${DateFormat('dd/MM/yyyy').format(notification.bookingDate ?? DateTime.now())} • ${notification.timeSlot ?? 0}:00 - ${(notification.timeSlot ?? 0) + 1}:00';
    String courtString = 'Sân ${notification.courtNumber ?? "1"}';
    String displayMsg = notification.message;

    if (isBooking || notification.title.contains('screens.success'.tr())) {
      final msg = notification.message;
      final addressMatch = RegExp(r'screens.Yard'.tr()).firstMatch(msg);
      if (addressMatch != null) {
        address = addressMatch.group(1)!;
        // Xóa phần địa chỉ sân "(XXX)" trong message để tránh trùng lặp
        displayMsg = msg.replaceFirst(' ($address)', '');
      }

      final priceMatch = RegExp(r'screens.withPrice'.tr()).firstMatch(msg);
      if (priceMatch != null) priceText = priceMatch.group(1)!;

      final dateMatch = RegExp(r'screens.enterD2D2D4From'.tr()).firstMatch(msg);
      if (dateMatch != null) dateText = '${dateMatch.group(1)} • ${dateMatch.group(2)!.trim()}';
      
      final courtMatch = RegExp(r'screens.YardDEnters'.tr()).firstMatch(msg);
      if (courtMatch != null) courtString = 'Sân ${courtMatch.group(1)}';
    }

    // Determine Icon and Color
    IconData iconData = Icons.notifications;
    Color iconColor = Colors.blue;
    Color iconBgColor = Colors.blue.withValues(alpha: 0.1);

    if (isBooking) {
      iconData = Icons.check;
      iconColor = Colors.white;
      iconBgColor = Color(0xFF4ADE80); // Green 400
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
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            padding: EdgeInsets.all(16),
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
                SizedBox(width: 16),

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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              margin: EdgeInsets.only(left: 4, top: 2),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        displayMsg,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                      // Details Box (Only for booking/specific types that have details)
                      if (isBooking || notification.courtName != null) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF9FAFB), // Very light grey
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                Icons.location_on,
                                address,
                              ),
                              SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.calendar_today,
                                dateText,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.sports_tennis,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    courtString,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    priceText,
                                    style: TextStyle(
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
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              if (address != 'screens.notDetermined'.tr()) {
                                _launchMaps(address);
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(
                              Icons.directions,
                              size: 18,
                              color: Colors.blue,
                            ),
                            label: Text(
                              'notification_screen.directions'.tr(),
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
                          notification.message.contains('screens.gDCode'.tr())) ...[
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 8),
                              Text(
                                // Extract transaction ID properly or just hardcode for demo if not in model
                                '${'notification_screen.transactionId'.tr()}#Transaction-${notification.id?.substring(0, 4) ?? "0000"}',
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
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

