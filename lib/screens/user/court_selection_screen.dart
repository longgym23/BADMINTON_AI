import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:badminton_ai/screens/user/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CourtSelectionScreen extends StatefulWidget {
  final CourtLocationModel selectedCourt;
  final DateTime selectedDate;

  const CourtSelectionScreen({
    super.key,
    required this.selectedCourt,
    required this.selectedDate,
  });

  @override
  State<CourtSelectionScreen> createState() => _CourtSelectionScreenState();
}

// Class để lưu trữ slot đã chọn
class _SelectedSlot {
  final int courtNumber;
  final double timeSlot;

  _SelectedSlot({required this.courtNumber, required this.timeSlot});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SelectedSlot &&
          runtimeType == other.runtimeType &&
          courtNumber == other.courtNumber &&
          timeSlot == other.timeSlot;

  @override
  int get hashCode => courtNumber.hashCode ^ timeSlot.hashCode;
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  // Thay đổi từ single selection sang multiple selection
  Set<_SelectedSlot> _selectedSlots = {}; // Set các slot đã chọn

  // Lưu ngày hiện tại trong state để có thể thay đổi
  late DateTime _currentDate;

  // Danh sách các khung giờ với slot 30 phút (6:00 -> 22:00)
  // Tạo danh sách: 6.0, 6.5, 7.0, 7.5, ..., 22.0
  final List<double> _timeSlots = List.generate(32, (index) {
    final hour = 6 + (index ~/ 2);
    final minute = (index % 2) * 0.5;
    return hour + minute;
  }); // 6.0, 6.5, 7.0, 7.5, ..., 22.0

  @override
  void initState() {
    super.initState();
    // Khởi tạo currentDate từ widget.selectedDate
    _currentDate = widget.selectedDate;
    // Yêu cầu Provider lắng nghe TẤT CẢ các booking của Sân Lớn này trong Ngày này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookingsForCurrentDate();
    });
  }

  // Hàm fetch bookings cho ngày hiện tại
  void _fetchBookingsForCurrentDate() {
    context.read<BookingProvider>().fetchBookingsForDay(
      widget.selectedCourt.id,
      _currentDate,
    );
  }

  // Hàm xử lý khi chọn ngày mới
  void _onDateChanged(DateTime newDate) {
    if (newDate != _currentDate) {
      setState(() {
        _currentDate = newDate;
        // Xóa tất cả các slot đã chọn khi đổi ngày
        _selectedSlots.clear();
      });
      // Fetch lại bookings cho ngày mới
      _fetchBookingsForCurrentDate();
    }
  }

  @override
  void dispose() {
    // Khi màn hình này đóng, hủy stream để tránh rò rỉ bộ nhớ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BookingProvider>().disposeStream();
      }
    });
    super.dispose();
  }

  // Tính tổng giờ đã chọn
  double _getTotalHours() {
    return _selectedSlots.length * 0.5; // Mỗi slot là 30 phút = 0.5 giờ
  }

  // Tính tổng tiền
  int _getTotalPrice() {
    return (_getTotalHours() * widget.selectedCourt.pricePerHour).round();
  }

  // Format tổng giờ (ví dụ: 2.5 -> "2h30")
  String _formatTotalHours(double hours) {
    final h = hours.toInt();
    final m = ((hours - h) * 60).toInt();
    if (m == 0) {
      return "${h}h";
    }
    return "${h}h${m}";
  }

  // Hàm xử lý khi nhấn nút TIẾP THEO
  void _onNext() async {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn ít nhất một slot còn trống"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final userId = context.read<AppAuthProvider>().userModel?.id;

    int successCount = 0;
    int failCount = 0;

    // Đặt từng slot
    for (final slot in _selectedSlots) {
      final int timeSlotHour = slot.timeSlot.toInt();

      final bookingId = await provider.createBooking(
        courtId: widget.selectedCourt.id,
        courtName: widget.selectedCourt.name,
        courtNumber: slot.courtNumber,
        date: _currentDate,
        timeSlot: timeSlotHour,
        price: widget.selectedCourt.pricePerHour.toInt(),
      );

      if (bookingId != null) {
        successCount++;

        // Tạo notification khi đặt sân thành công
        if (userId != null) {
          await notificationProvider.createBookingSuccessNotification(
            userId: userId,
            bookingId: bookingId,
            courtName: widget.selectedCourt.name,
            courtAddress: widget.selectedCourt.address,
            courtNumber: slot.courtNumber,
            bookingDate: _currentDate,
            timeSlot: timeSlotHour,
            price: widget.selectedCourt.pricePerHour.toInt(),
          );
        }
      } else {
        failCount++;
      }
    }

    if (mounted) {
      if (failCount == 0) {
        // Hiển thị thông báo thành công với icon và thông tin chi tiết
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Đặt sân thành công!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Đã đặt $successCount slot. Xem chi tiết trong thông báo.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Xem',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to notifications screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ),
        );

        // Quay về sau 1 giây để user có thể thấy thông báo
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Đặt sân: $successCount thành công, $failCount thất bại",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<BookingProvider>();

    // Format ngày giờ để hiển thị
    final String formattedDate = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    ).format(_currentDate);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Đặt lịch ngày trực quan"),
        backgroundColor: colors.primary, // Màu xanh đậm
        actions: [
          // Nút chọn ngày như hình ảnh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _currentDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  // Cập nhật ngày và fetch lại bookings
                  _onDateChanged(picked);
                }
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(formattedDate, style: const TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chú thích màu sắc - Di chuyển lên trên
          _buildLegend(colors),

          // Link "Xem sân & bảng giá"
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to price list screen
                },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text(
                  "Xem sân & bảng giá",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: colors.primary),
              ),
            ),
          ),

          // Thông báo lưu ý
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Lưu ý: Nếu bạn cần đặt lịch cố định vui lòng liên hệ: 0963.877.778 để được hỗ trợ.",
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
          ),

          // Biểu đồ đặt sân (Gantt Chart)
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: provider.bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Lỗi: ${snapshot.error}",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Lấy danh sách các booking đã đặt
                final List<BookingModel> bookings = snapshot.data ?? [];

                // CẤU TRÚC LAYOUT ĐÃ SỬA
                // Bọc trong SingleChildScrollView (Cuộn dọc)
                return SingleChildScrollView(
                  child: _BookingTimeline(
                    availableCourts: widget.selectedCourt.totalCourts,
                    timeSlots: _timeSlots,
                    bookings: bookings,
                    selectedSlots: _selectedSlots,
                    onSlotSelected: (courtNum, timeSlot) {
                      // Kiểm tra xem slot này đã bị đặt chưa
                      final hour = timeSlot.toInt();
                      bool isBooked = bookings.any(
                        (booking) =>
                            booking.courtNumber == courtNum &&
                            booking.timeSlot == hour,
                      );

                      if (!isBooked) {
                        setState(() {
                          final slot = _SelectedSlot(
                            courtNumber: courtNum,
                            timeSlot: timeSlot,
                          );
                          if (_selectedSlots.contains(slot)) {
                            // Nếu đã chọn thì bỏ chọn (toggle)
                            _selectedSlots.remove(slot);
                          } else {
                            // Nếu chưa chọn thì thêm vào
                            _selectedSlots.add(slot);
                          }
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Footer với tổng giờ, tổng tiền và nút TIẾP THEO
          Container(
            color: colors.primary, // Màu xanh đậm
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              children: [
                // Tổng giờ và tổng tiền
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tổng giờ: ${_formatTotalHours(_getTotalHours())}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Tổng tiền: ${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(_getTotalPrice())}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Nút TIẾP THEO
                SizedBox(
                  width: double.infinity,
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.secondary, // Màu vàng
                            foregroundColor: colors.primary, // Chữ màu xanh đậm
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "TIẾP THEO",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Chú thích - Cập nhật theo hình ảnh
  Widget _buildLegend(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.white, "Trống", Colors.black87),
          _buildLegendItem(Colors.redAccent[100]!, "Đã đặt", Colors.black87),
          _buildLegendItem(Colors.grey[300]!, "Khoá", Colors.black87),
          _buildLegendItem(Colors.purple[200]!, "Sự kiện", Colors.black87),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: textColor, fontSize: 13)),
      ],
    );
  }
}

// Widget Biểu Đồ Đặt Sân (Gantt Chart) - ĐÃ SỬA LỖI LAYOUT
class _BookingTimeline extends StatelessWidget {
  final int availableCourts;
  final List<double> timeSlots; // Đổi sang double để hỗ trợ 30 phút
  final List<BookingModel> bookings;
  final Set<_SelectedSlot>
  selectedSlots; // Đổi sang Set để hỗ trợ multiple selection
  final Function(int courtNum, double timeSlot) onSlotSelected;

  const _BookingTimeline({
    required this.availableCourts,
    required this.timeSlots,
    required this.bookings,
    required this.selectedSlots,
    required this.onSlotSelected,
  });

  // Hàm format time slot để hiển thị (6.0 -> "6:00", 6.5 -> "6:30")
  String _formatTimeSlot(double timeSlot) {
    final hour = timeSlot.toInt();
    final minute = ((timeSlot - hour) * 60).toInt();
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  // Hàm kiểm tra slot đã bị đặt chưa
  // Kiểm tra xem có booking nào bắt đầu từ giờ này không
  bool _isSlotBooked(int courtNum, double timeSlot) {
    final hour = timeSlot.toInt();
    // Kiểm tra xem có booking nào bắt đầu từ giờ này không
    // Hoặc booking bắt đầu từ giờ trước đó và kéo dài đến giờ này
    return bookings.any((b) {
      if (b.courtNumber != courtNum) return false;
      // Nếu booking bắt đầu từ giờ này
      if (b.timeSlot == hour) return true;
      // Nếu booking bắt đầu từ giờ trước đó (giả sử mỗi booking kéo dài 1 giờ)
      // Có thể mở rộng logic này nếu cần
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double colWidth =
        60.0; // Giảm chiều rộng vì có nhiều cột hơn (30 phút)
    const double rowHeaderWidth =
        80.0; // Tăng chiều rộng để hiển thị "Pickleball 1"

    // Bọc trong SingleChildScrollView (Cuộn ngang)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        // Màu nền nhẹ cho biểu đồ
        color: Colors.grey[100],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hàng Tiêu Đề (Giờ) - Màu xanh nhạt
            _buildHeaderTime(context, colWidth, rowHeaderWidth),

            // 2. Các Hàng Sân (Pickleball 1, Pickleball 2, ...)
            ...List.generate(availableCourts, (index) {
              final courtNum = index + 1;
              return _buildCourtRow(
                context,
                courtNum,
                colWidth,
                rowHeaderWidth,
              );
            }),
          ],
        ),
      ),
    );
  }

  // Widget cho Hàng Tiêu Đề (Giờ) - Màu xanh nhạt như hình ảnh
  Widget _buildHeaderTime(
    BuildContext context,
    double colWidth,
    double rowHeaderWidth,
  ) {
    return Container(
      color: Colors.lightBlue[100], // Màu xanh nhạt như hình ảnh
      child: Row(
        children: [
          SizedBox(width: rowHeaderWidth), // Ô trống đầu tiên
          ...timeSlots
              .map(
                (time) => Container(
                  width: colWidth,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _formatTimeSlot(time),
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  // Widget cho 1 hàng sân (ví dụ: "Pickleball 1" và tất cả các slot giờ)
  Widget _buildCourtRow(
    BuildContext context,
    int courtNum,
    double colWidth,
    double rowHeaderWidth,
  ) {
    return Row(
      children: [
        // Tiêu đề hàng (Pickleball 1) - Màu xanh nhạt như hình ảnh
        Container(
          width: rowHeaderWidth,
          height: 60, // Chiều cao của 1 hàng
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.lightBlue[50], // Màu xanh nhạt
            border: Border(
              bottom: BorderSide(color: Colors.white, width: 1),
              right: BorderSide(color: Colors.white, width: 1),
            ),
          ),
          child: Center(
            child: Text(
              "Pickleball $courtNum", // Đổi tên theo hình ảnh
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // Các ô slot giờ
        ...timeSlots.map((timeSlot) {
          final isBooked = _isSlotBooked(courtNum, timeSlot);
          final slot = _SelectedSlot(courtNumber: courtNum, timeSlot: timeSlot);
          final isSelected = selectedSlots.contains(slot);

          Color cellColor;
          Widget? cellIcon;
          Border? border;

          if (isSelected) {
            cellColor = Colors
                .lightGreen[100]!; // Màu xanh nhạt (Đang chọn) - theo hình ảnh
            border = Border.all(color: Colors.black, width: 2); // Viền đen đậm
            cellIcon = null; // Không hiển thị icon khi chọn
          } else if (isBooked) {
            cellColor = Colors.redAccent[100]!; // Màu đỏ nhạt (Đã đặt)
            border = Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              right: BorderSide(color: Colors.grey[300]!, width: 1),
            );
            cellIcon = Icon(
              Icons.lock,
              color: Colors.white.withOpacity(0.8),
              size: 18,
            );
          } else {
            cellColor = Colors.white; // Màu trắng (Còn trống) - theo hình ảnh
            border = Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              right: BorderSide(color: Colors.grey[300]!, width: 1),
            );
            cellIcon = null;
          }

          return GestureDetector(
            onTap: () {
              if (!isBooked) {
                onSlotSelected(courtNum, timeSlot);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: colWidth,
              height: 60, // Chiều cao của 1 hàng
              decoration: BoxDecoration(color: cellColor, border: border),
              child: Center(child: cellIcon),
            ),
          );
        }).toList(),
      ],
    );
  }
}
