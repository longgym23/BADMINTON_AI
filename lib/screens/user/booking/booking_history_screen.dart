import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/services/court_info_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badminton_ai/utils/app_colors.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // colors variable removed
    final repo = context.watch<SupabaseRepository>();
    final userId = context.watch<AppAuthProvider>().userModel?.id;

    return Scaffold(
      backgroundColor: AppColors.background, // Light grey background
      appBar: AppBar(
        title: const Text(
          'Lịch sử đặt sân',
          style: TextStyle(
            color: AppColors.textBlack,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textBlack),
            onPressed: () {
              // Filter action
            },
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text("Vui lòng đăng nhập"))
          : StreamBuilder<List<BookingModel>>(
              stream: repo.getUserBookingHistoryStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }

                final bookings = snapshot.data ?? [];
                // Sort by date descending
                bookings.sort((a, b) {
                  final dateA = DateTime(
                    a.date.year,
                    a.date.month,
                    a.date.day,
                    a.timeSlot,
                  );
                  final dateB = DateTime(
                    b.date.year,
                    b.date.month,
                    b.date.day,
                    b.timeSlot,
                  );
                  return dateB.compareTo(dateA);
                });

                // Calculate summary
                int totalBookings = bookings.length;
                int totalSpend = bookings.fold(
                  0,
                  (sum, item) => sum + item.price,
                );

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Section
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: 'Tổng chi tiêu',
                                value: NumberFormat.simpleCurrency(
                                  locale: 'vi_VN',
                                  decimalDigits: 0,
                                ).format(totalSpend),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Sân đã đặt',
                                value: '$totalBookings Lượt',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section Title
                        const Text(
                          'GẦN ĐÂY',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // List of Bookings
                        if (bookings.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 32.0),
                              child: Text("Chưa có lịch sử đặt sân"),
                            ),
                          )
                        else
                          ...bookings.map(
                            (booking) =>
                                _BookingCard(booking: booking, repo: repo),
                          ),

                        // Bottom spacing
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final SupabaseRepository repo;

  const _BookingCard({required this.booking, required this.repo});

  Future<void> _launchMaps(BuildContext context) async {
    // Show Loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đang lấy vị trí..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final court = await repo.getCourtLocationById(booking.courtId);
      if (court == null || (court.latitude == 0 && court.longitude == 0)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không tìm thấy vị trí sân")),
          );
        }
        return;
      }

      final url = CourtInfoService.getDirectionsUrl(
        LatLng(court.latitude, court.longitude),
        destinationName: court.name,
      );

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine status style
    // Logic:
    // - Cancelled -> Grey, 'Đã hủy'
    // - Date passed -> Green, 'Đã hoàn thành'
    // - Future -> Blue, 'Sắp tới'

    final now = DateTime.now();
    final bookingTime = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      booking.timeSlot,
    );

    // Check status logic
    bool isCancelled = booking.status == 'cancelled';
    bool isCompleted = !isCancelled && bookingTime.isBefore(now);
    bool isUpcoming = !isCancelled && !isCompleted;

    String statusText;
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (isCancelled) {
      statusText = 'Đã hủy';
      statusColor = AppColors.textGrey;
      statusBgColor = AppColors.borderColor;
      statusIcon = Icons.cancel;
    } else if (isCompleted) {
      statusText = 'Đã hoàn thành';
      statusColor = AppColors.success; // Green
      statusBgColor = AppColors.successBg; // Light Green
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'Sắp tới';
      statusColor = AppColors.primary; // Blue
      statusBgColor = AppColors.primaryBg; // Light Blue
      statusIcon = Icons.calendar_today;
    }

    final currencyFormatter = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status Badge & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(booking.price),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Info: Icon + Text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Court Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg, // Light blue bg
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_tennis,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Sân ${booking.courtNumber}",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.courtName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textBlack,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd/MM/yyyy').format(booking.date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${booking.timeSlot}:00 - ${booking.timeSlot + 1}:00 (1h)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[100]),

          // Action Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    // Show details logic or navigaton
                  },
                  child: Text(
                    "Chi tiết",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                const Spacer(),
                if (isUpcoming || isCompleted)
                  OutlinedButton.icon(
                    onPressed: () => _launchMaps(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(
                      Icons.directions,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      "Chỉ đường đến sân",
                      style: TextStyle(
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      // Rebooking simple logic (just navigate back to home or show toast)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Tính năng đặt lại đang được phát triển",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.refresh,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      "Đặt lại sân này",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
