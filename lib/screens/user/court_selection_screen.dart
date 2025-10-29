import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
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

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  int? _selectedCourtNumber;
  int? _selectedTimeSlot;

  // Danh sách các khung giờ (5:00 -> 22:00)
  final List<int> _timeSlots =
      List.generate(18, (index) => index + 5); // 5, 6, ..., 22

  @override
  void initState() {
    super.initState();
    // Yêu cầu Provider lắng nghe TẤT CẢ các booking của Sân Lớn này trong Ngày này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookingsForDay(
            widget.selectedCourt.id,
            widget.selectedDate,
          );
    });
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


  // Hàm xử lý khi nhấn nút Đặt sân
  void _onConfirmBooking() async {
    if (_selectedCourtNumber == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vui lòng chọn một ô (sân + giờ) còn trống"),
            backgroundColor: Colors.red),
      );
      return;
    }

    final provider = context.read<BookingProvider>();
    final bool success = await provider.createBooking(
      courtId: widget.selectedCourt.id,
      courtName: widget.selectedCourt.name,
      courtNumber: _selectedCourtNumber!,
      date: widget.selectedDate,
      timeSlot: _selectedTimeSlot!,
      price: widget.selectedCourt.pricePerHour.toInt(), // Đổi sang int
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Đặt sân $_selectedCourtNumber lúc $_selectedTimeSlot:00 thành công!"),
              backgroundColor: Colors.green),
        );
        // Tự động quay về sau khi đặt thành công
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Đặt sân thất bại: ${provider.errorMessage ?? 'Lỗi không xác định'}"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<BookingProvider>();

    // Format ngày giờ để hiển thị
    final String formattedDate =
        DateFormat('dd/MM/yyyy', 'vi_VN').format(widget.selectedDate);
    final String formattedPrice =
        NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0)
            .format(widget.selectedCourt.pricePerHour);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedCourt.name),
        backgroundColor: colors.primary, // Màu xanh đậm
      ),
      body: Column(
        children: [
          // Thông tin chi tiết
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: colors.primary, // Màu xanh đậm
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ngày: $formattedDate",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text("Giá: $formattedPrice / giờ",
                    style:
                        TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 12),
                // Chú thích màu sắc
                _buildLegend(colors),
              ],
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
                  return Center(child: Text("Lỗi: ${snapshot.error}", style: TextStyle(color: Colors.white)));
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
                    selectedCourtNumber: _selectedCourtNumber,
                    selectedTimeSlot: _selectedTimeSlot,
                    onSlotSelected: (courtNum, timeSlot) {
                      // Kiểm tra xem slot này đã bị đặt chưa
                      bool isBooked = bookings.any((booking) =>
                          booking.courtNumber == courtNum &&
                          booking.timeSlot == timeSlot);
                      
                      if (!isBooked) {
                        setState(() {
                          _selectedCourtNumber = courtNum;
                          _selectedTimeSlot = timeSlot;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // Nút Xác nhận
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            width: double.infinity,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text("Xác nhận Đặt sân",
                        style: TextStyle(fontSize: 18)),
                    onPressed: _onConfirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.secondary, // Màu vàng
                      foregroundColor: colors.primary, // Chữ màu xanh đậm
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Chú thích
  Widget _buildLegend(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(colors.secondary, "Đang chọn"), // Vàng
        _buildLegendItem(Colors.redAccent[100]!, "Đã đặt"), // Đỏ
        _buildLegendItem(colors.background, "Còn trống"), // Xanh nền
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 1)
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

// Widget Biểu Đồ Đặt Sân (Gantt Chart) - ĐÃ SỬA LỖI LAYOUT
class _BookingTimeline extends StatelessWidget {
  final int availableCourts;
  final List<int> timeSlots;
  final List<BookingModel> bookings;
  final int? selectedCourtNumber;
  final int? selectedTimeSlot;
  final Function(int courtNum, int timeSlot) onSlotSelected;

  const _BookingTimeline({
    required this.availableCourts,
    required this.timeSlots,
    required this.bookings,
    this.selectedCourtNumber,
    this.selectedTimeSlot,
    required this.onSlotSelected,
  });

  // Hàm kiểm tra slot đã bị đặt chưa
  bool _isSlotBooked(int courtNum, int timeSlot) {
    return bookings.any(
        (b) => b.courtNumber == courtNum && b.timeSlot == timeSlot);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const double colWidth = 70.0; // Chiều rộng của mỗi cột giờ
    const double rowHeaderWidth = 65.0; // Chiều rộng của cột "Sân 1"

    // Bọc trong SingleChildScrollView (Cuộn ngang)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        // Màu nền nhẹ cho biểu đồ
        color: colors.primary.withOpacity(0.1), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hàng Tiêu Đề (Giờ)
            _buildHeaderTime(context, colWidth, rowHeaderWidth),
            
            // 2. Các Hàng Sân (Sân 1, Sân 2, ...)
            // Không dùng Expanded, tạo danh sách các Row
            ...List.generate(availableCourts, (index) {
              final courtNum = index + 1;
              return _buildCourtRow(context, courtNum, colWidth, rowHeaderWidth);
            }),
          ],
        ),
      ),
    );
  }

  // Widget cho Hàng Tiêu Đề (Giờ)
  Widget _buildHeaderTime(BuildContext context, double colWidth, double rowHeaderWidth) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(width: rowHeaderWidth), // Ô trống đầu tiên
        ...timeSlots
            .map((time) => Container(
                  width: colWidth,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.primary, // Màu xanh đậm
                    border: Border(
                      bottom: BorderSide(color: Colors.white24, width: 1),
                      right: BorderSide(color: Colors.white10, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${time}:00",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                      ),
                    ),
                  ),
                ))
            .toList(),
      ],
    );
  }

  // Widget cho 1 hàng sân (ví dụ: "Sân 1" và tất cả các slot giờ)
  Widget _buildCourtRow(BuildContext context, int courtNum, double colWidth, double rowHeaderWidth) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Tiêu đề hàng (Sân 1)
        Container(
          width: rowHeaderWidth,
          height: 60, // Chiều cao của 1 hàng
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colors.primary, // Màu xanh đậm
            border: Border(
              bottom: BorderSide(color: Colors.white24, width: 1),
              right: BorderSide(color: Colors.white24, width: 1),
            ),
          ),
          child: Center(
            child: Text(
              "Sân $courtNum",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Các ô slot giờ
        ...timeSlots.map((timeSlot) {
          final isBooked = _isSlotBooked(courtNum, timeSlot);
          final isSelected = selectedCourtNumber == courtNum &&
              selectedTimeSlot == timeSlot;

          Color cellColor;
          Widget? cellIcon;

          if (isSelected) {
            cellColor = colors.secondary; // Màu vàng (Đang chọn)
            cellIcon = Icon(Icons.check_circle, color: colors.primary, size: 20);
          } else if (isBooked) {
            cellColor = Colors.redAccent[100]!.withOpacity(0.8); // Màu đỏ nhạt (Đã đặt)
            cellIcon = Icon(Icons.lock, color: Colors.white.withOpacity(0.8), size: 18);
          } else {
            cellColor = colors.background; // Màu nền (Còn trống)
            cellIcon = null;
          }

          return GestureDetector(
            onTap: () => onSlotSelected(courtNum, timeSlot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: colWidth,
              height: 60, // Chiều cao của 1 hàng
              decoration: BoxDecoration(
                color: cellColor,
                border: Border(
                  bottom: BorderSide(color: Colors.white10, width: 1),
                  right: BorderSide(color: Colors.white10, width: 1),
                ),
              ),
              child: Center(child: cellIcon),
            ),
          );
        }).toList(),
      ],
    );
  }
}

