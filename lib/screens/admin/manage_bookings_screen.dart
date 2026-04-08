import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  _ManageBookingsScreenState createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Hàm hiển thị Dialog xác nhận xóa (Giống của User)
  void _confirmDelete(
    BuildContext context,
    String? bookingId,
    SupabaseRepository repo,
  ) {
    if (bookingId == null) return;

    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Xác nhận hủy sân",
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Admin: Bạn có chắc chắn muốn hủy lịch đặt của người dùng này không?",
            style: TextStyle(color: Colors.black87),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Không",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text("Hủy sân"),
              onPressed: () async {
                try {
                  await repo.deleteBooking(bookingId);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Admin đã hủy sân thành công"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Hủy sân thất bại: $e"),
                      backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final repo = context.watch<SupabaseRepository>();
    final currencyFormatter = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Lịch đặt'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Lịch chọn ngày
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: TableCalendar(
              locale: 'vi_VN',
              firstDay: DateTime.now().subtract(
                const Duration(days: 365),
              ), // Cho phép xem quá khứ
              lastDay: DateTime.now().add(
                const Duration(days: 365),
              ), // Cho phép xem tương lai
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: colors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
                todayDecoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) =>
                    DateFormat.E(locale).format(date).substring(0, 1),
                weekendStyle: TextStyle(color: Colors.red[600]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Lịch đặt ngày: ${dateFormatter.format(_selectedDay)}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. StreamBuilder danh sách booking
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: repo.getAllBookingsForDay(
                _selectedDay,
                ownerId: context.read<AppAuthProvider>().userRole == 'court_owner'
                    ? context.read<AppAuthProvider>().userModel?.id
                    : null,
              ), // <-- HÀM QUAN TRỌNG
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.secondary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Lỗi: ${snapshot.error}",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "Không có lịch đặt nào trong ngày này.",
                      style: TextStyle(color: colors.onSurface, fontSize: 16),
                    ),
                  );
                }

                final bookings = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          child: Text(
                            "Sân\n${booking.courtNumber}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Hiển thị tên người đặt
                        title: Text(
                          "Người đặt: ${booking.userName}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        subtitle: Text(
                          "${booking.courtName}\nLúc: ${booking.timeSlot}:00 - Giá: ${currencyFormatter.format(booking.price)}",
                          style: TextStyle(color: Colors.black87),
                        ),
                        // Nút Hủy
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_forever,
                            color: Colors.red[700],
                            size: 30,
                          ),
                          tooltip: "Hủy sân (Admin)",
                          onPressed: () {
                            _confirmDelete(context, booking.id, repo);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
