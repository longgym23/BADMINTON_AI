import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  // Hàm hiển thị Dialog xác nhận xóa
  void _confirmDelete(BuildContext context, String bookingId, FirestoreRepository repo) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Xác nhận hủy sân",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          content: Text(
            "Bạn có chắc chắn muốn hủy lịch đặt sân này không?",
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Không", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
            ),
            TextButton(
              child: Text("Hủy sân", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await repo.deleteBooking(bookingId);
                  Navigator.of(dialogContext).pop(); // Đóng dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Hủy sân thành công"),
                        backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Hủy sân thất bại: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final repo = context.watch<FirestoreRepository>();
    final userId = context.watch<AppAuthProvider>().userModel?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử đặt sân'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: userId == null
          ? Center(
              child: Text("Không tìm thấy thông tin người dùng",
                  style: TextStyle(color: colors.onSurface)))
          : StreamBuilder<List<BookingModel>>(
              stream: repo.getUserBookingHistoryStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: colors.secondary));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Lỗi tải lịch sử: ${snapshot.error}",
                          style: TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text("Bạn chưa đặt sân nào.",
                          style: TextStyle(color: colors.onSurface, fontSize: 18)));
                }

                final bookings = snapshot.data!;
                final currencyFormatter = NumberFormat.simpleCurrency(
                    locale: 'vi_VN', decimalDigits: 0);
                final dateFormatter = DateFormat('dd/MM/yyyy', 'vi_VN');

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final bool isPast = booking.date.isBefore(
                        DateTime.now().subtract(const Duration(days: 1)));

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isPast ? Colors.white.withOpacity(0.7) : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        // Icon
                        leading: CircleAvatar(
                          backgroundColor: isPast ? Colors.grey : colors.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            "Sân\n${booking.courtNumber}",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Thông tin
                        title: Text(
                          booking.courtName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                              decoration: isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          "${dateFormatter.format(booking.date)} - ${booking.timeSlot}:00\nGiá: ${currencyFormatter.format(booking.price)}",
                          style: TextStyle(
                            color: isPast ? Colors.black54 : Colors.black87,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        // Nút Hủy (chỉ hiển thị nếu chưa qua)
                        trailing: isPast
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red[700]),
                                tooltip: "Hủy sân",
                                onPressed: () {
                                  _confirmDelete(context, booking.id!, repo);
                                },
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

