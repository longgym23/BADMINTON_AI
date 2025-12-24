import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/services/court_info_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  // Hàm hiển thị Dialog xác nhận xóa
  void _confirmDelete(
    BuildContext context,
    String bookingId,
    FirestoreRepository repo,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Xác nhận hủy sân",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Bạn có chắc chắn muốn hủy lịch đặt sân này không?",
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Không",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Hủy sân", style: TextStyle(fontSize: 16)),
              onPressed: () async {
                try {
                  await repo.deleteBooking(bookingId);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text("Hủy sân thành công"),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text("Hủy sân thất bại: $e"),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Xác định trạng thái booking
  String _getBookingStatus(BookingModel booking) {
    final now = DateTime.now();
    final bookingDateTime = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      booking.timeSlot,
    );

    if (booking.status == 'cancelled') {
      return 'cancelled';
    } else if (bookingDateTime.isBefore(now)) {
      return 'completed';
    } else {
      return 'upcoming';
    }
  }

  // Lấy màu và icon theo trạng thái
  Map<String, dynamic> _getStatusStyle(String status, ColorScheme colors) {
    switch (status) {
      case 'completed':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
          'label': 'Đã hoàn thành',
          'bgColor': Colors.green.withOpacity(0.1),
        };
      case 'upcoming':
        return {
          'color': colors.secondary,
          'icon': Icons.schedule_rounded,
          'label': 'Sắp tới',
          'bgColor': colors.secondary.withOpacity(0.1),
        };
      case 'cancelled':
        return {
          'color': Colors.grey,
          'icon': Icons.cancel_rounded,
          'label': 'Đã hủy',
          'bgColor': Colors.grey.withOpacity(0.1),
        };
      default:
        return {
          'color': colors.primary,
          'icon': Icons.info_rounded,
          'label': 'Đã xác nhận',
          'bgColor': colors.primary.withOpacity(0.1),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final repo = context.watch<FirestoreRepository>();
    final userId = context.watch<AppAuthProvider>().userModel?.id;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Lịch sử đặt sân',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: userId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    "Không tìm thấy thông tin người dùng",
                    style: TextStyle(color: colors.onSurface, fontSize: 16),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<BookingModel>>(
              stream: repo.getUserBookingHistoryStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.secondary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Lỗi tải lịch sử: ${snapshot.error}",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Force rebuild by navigating away and back
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BookingHistoryScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.refresh),
                          label: Text("Thử lại"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.secondary,
                            foregroundColor: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 64,
                            color: colors.primary,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Bạn chưa đặt sân nào",
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Hãy đặt sân để bắt đầu chơi!",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!;
                // Sắp xếp: upcoming trước, sau đó completed, cuối cùng cancelled
                bookings.sort((a, b) {
                  final statusA = _getBookingStatus(a);
                  final statusB = _getBookingStatus(b);
                  final order = {'upcoming': 0, 'completed': 1, 'cancelled': 2};
                  final orderA = order[statusA] ?? 3;
                  final orderB = order[statusB] ?? 3;
                  if (orderA != orderB) return orderA.compareTo(orderB);
                  // Nếu cùng status, sắp xếp theo ngày giờ
                  final dateTimeA = DateTime(
                    a.date.year,
                    a.date.month,
                    a.date.day,
                    a.timeSlot,
                  );
                  final dateTimeB = DateTime(
                    b.date.year,
                    b.date.month,
                    b.date.day,
                    b.timeSlot,
                  );
                  return dateTimeB.compareTo(dateTimeA); // Mới nhất trước
                });

                final currencyFormatter = NumberFormat.simpleCurrency(
                  locale: 'vi_VN',
                  decimalDigits: 0,
                );
                final dateFormatter = DateFormat('dd/MM/yyyy', 'vi_VN');

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final status = _getBookingStatus(booking);
                    final statusStyle = _getStatusStyle(status, colors);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: status == 'cancelled'
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: status == 'completed'
                                        ? [
                                            Colors.green.withOpacity(0.05),
                                            Colors.white,
                                          ]
                                        : [
                                            colors.secondary.withOpacity(0.05),
                                            Colors.white,
                                          ],
                                  ),
                            border: Border.all(
                              color: status == 'cancelled'
                                  ? Colors.grey[300]!
                                  : statusStyle['color']!.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Status và nút hủy
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Status badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusStyle['bgColor'],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusStyle['icon'],
                                            size: 16,
                                            color: statusStyle['color'],
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            statusStyle['label'],
                                            style: TextStyle(
                                              color: statusStyle['color'],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Nút hủy (chỉ hiển thị nếu upcoming)
                                    if (status == 'upcoming')
                                      IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: Colors.red[600],
                                        ),
                                        onPressed: () {
                                          _confirmDelete(
                                            context,
                                            booking.id!,
                                            repo,
                                          );
                                        },
                                        tooltip: "Hủy sân",
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Thông tin chính
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon sân
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: status == 'cancelled'
                                            ? null
                                            : LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  colors.primary,
                                                  colors.secondary,
                                                ],
                                              ),
                                        color: status == 'cancelled'
                                            ? Colors.grey[400]
                                            : null,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.sports_tennis_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "${booking.courtNumber}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    // Thông tin chi tiết
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Tên sân
                                          Text(
                                            booking.courtName,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: status == 'cancelled'
                                                  ? Colors.grey[500]
                                                  : colors.primary,
                                              decoration: status == 'cancelled'
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          // Ngày giờ
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                dateFormatter.format(
                                                  booking.date,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "${booking.timeSlot}:00",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          // Giá
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money_rounded,
                                                size: 18,
                                                color: colors.secondary,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                currencyFormatter.format(
                                                  booking.price,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: status == 'cancelled'
                                                      ? Colors.grey[500]
                                                      : colors.secondary,
                                                  decoration:
                                                      status == 'cancelled'
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Nút chỉ đường (chỉ hiển thị nếu upcoming hoặc completed)
                                if (status != 'cancelled')
                                  FutureBuilder<CourtLocationModel?>(
                                    future: repo.getCourtLocationById(
                                      booking.courtId,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox.shrink();
                                      }
                                      final court = snapshot.data;
                                      if (court == null ||
                                          (court.latitude == 0.0 &&
                                              court.longitude == 0.0)) {
                                        return const SizedBox.shrink();
                                      }

                                      return SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            // Hiển thị loading
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        'Đang lấy vị trí hiện tại...',
                                                      ),
                                                    ],
                                                  ),
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }

                                            // Lấy vị trí hiện tại của user
                                            LatLng? currentLocation;
                                            try {
                                              bool serviceEnabled =
                                                  await Geolocator.isLocationServiceEnabled();
                                              if (!serviceEnabled) {
                                                throw Exception(
                                                  'Dịch vụ vị trí chưa được bật',
                                                );
                                              }

                                              LocationPermission permission =
                                                  await Geolocator.checkPermission();
                                              if (permission ==
                                                  LocationPermission.denied) {
                                                permission =
                                                    await Geolocator.requestPermission();
                                                if (permission ==
                                                    LocationPermission.denied) {
                                                  throw Exception(
                                                    'Quyền truy cập vị trí bị từ chối',
                                                  );
                                                }
                                              }

                                              if (permission ==
                                                  LocationPermission
                                                      .deniedForever) {
                                                throw Exception(
                                                  'Quyền truy cập vị trí bị từ chối vĩnh viễn',
                                                );
                                              }

                                              Position position =
                                                  await Geolocator.getCurrentPosition(
                                                    desiredAccuracy:
                                                        LocationAccuracy.high,
                                                    timeLimit: const Duration(
                                                      seconds: 10,
                                                    ),
                                                  );
                                              currentLocation = LatLng(
                                                position.latitude,
                                                position.longitude,
                                              );
                                            } catch (e) {
                                              print('Lỗi lấy vị trí: $e');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Không thể lấy vị trí: $e. Sử dụng chỉ đường không có điểm xuất phát.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.orange,
                                                    duration: const Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }

                                            // Tạo URL chỉ đường với vị trí hiện tại (nếu có)
                                            final url =
                                                CourtInfoService.getDirectionsUrl(
                                                  LatLng(
                                                    court.latitude,
                                                    court.longitude,
                                                  ),
                                                  destinationName: court.name,
                                                  origin:
                                                      currentLocation, // Truyền vị trí hiện tại nếu có
                                                );
                                            final uri = Uri.parse(url);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Không thể mở Google Maps',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.directions,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            "Chỉ đường đến sân",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: colors.primary,
                                            side: BorderSide(
                                              color: colors.primary,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
