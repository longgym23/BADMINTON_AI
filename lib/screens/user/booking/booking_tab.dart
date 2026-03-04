import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart'; // Đảm bảo đã import

class BookingTab extends StatefulWidget {
  const BookingTab({super.key});

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  // Trạng thái cho Lịch
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Trạng thái cho Dropdown
  CourtLocationModel? _selectedCourt;

  // Hàm quan trọng: Được gọi khi Ngày hoặc Sân Lớn thay đổi
  void _updateBookingStream() {
    if (_selectedCourt != null && mounted) {
      // Yêu cầu Provider lắng nghe các booking cho Sân Lớn và Ngày đã chọn
      context.read<BookingProvider>().fetchBookingsForDay(
        _selectedCourt!.id,
        _selectedDay,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tải stream lần đầu khi _selectedCourt được gán
    // (chỉ khi _selectedCourt không null)
    if (_selectedCourt != null) {
      _updateBookingStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreRepo = context.read<SupabaseRepository>();
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        // Dùng CustomScrollView để tối ưu layout
        slivers: [
          // Header với gradient
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.primary, colors.primary.withOpacity(0.8)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Đặt sân",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Chọn ngày và sân để đặt lịch",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 1. Lịch chọn ngày
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: _buildCalendar(colors),
              ),
            ),
          ),

          // 2. Chọn sân
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SectionHeader(
                icon: Icons.sports_tennis_rounded,
                title: "1. Chọn sân",
                color: colors.primary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: StreamBuilder<List<CourtLocationModel>>(
                stream: firestoreRepo.getCourtLocationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _selectedCourt == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(
                      "Lỗi tải sân",
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final courts = snapshot.data ?? [];
                  if (courts.isEmpty) {
                    return Text(
                      "Chưa có sân nào.",
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  // Logic an toàn cho Dropdown
                  bool isSelectedCourtValid =
                      _selectedCourt != null && courts.contains(_selectedCourt);

                  if (_selectedCourt == null || !isSelectedCourtValid) {
                    // Dùng addPostFrameCallback để tránh lỗi setState trong build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedCourt = courts.first;
                        });
                        _updateBookingStream(); // Tải stream lần đầu
                      }
                    });
                  }

                  // Hiển thị loading cho đến khi _selectedCourt được gán
                  if (_selectedCourt == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CourtLocationModel>(
                            value: _selectedCourt,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down_circle_rounded,
                              color: colors.primary,
                            ),
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (CourtLocationModel? newValue) {
                              setState(() {
                                _selectedCourt = newValue;
                              });
                              _updateBookingStream(); // Tải lại stream khi đổi sân
                            },
                            items: courts
                                .map<DropdownMenuItem<CourtLocationModel>>((
                                  court,
                                ) {
                                  return DropdownMenuItem<CourtLocationModel>(
                                    value: court,
                                    child: Text(
                                      "${court.name} - (${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(court.pricePerHour)})",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Nút mở màn hình chọn slot
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _selectedCourt == null
                  ? Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Vui lòng chọn sân ở trên",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_view_week_rounded),
                      label: const Text(
                        "Chọn khung giờ",
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        // Navigate đến màn hình chọn slot
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourtSelectionScreen(
                              selectedCourt: _selectedCourt!,
                              selectedDate: _selectedDay,
                            ),
                          ),
                        ).then((_) {
                          // Refresh lại danh sách booking khi quay lại
                          _updateBookingStream();
                        });
                      },
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
          ),
        ],
      ),
    );
  }

  // Widget cho Lịch (Đã sửa lỗi tràn viền)
  Widget _buildCalendar(ColorScheme colors) {
    return TableCalendar(
      locale: 'vi_VN',
      firstDay: DateTime.now().subtract(const Duration(days: 1)),
      lastDay: DateTime.now().add(const Duration(days: 30)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _updateBookingStream(); // Tải lại stream khi đổi ngày
        }
      },
      // SỬA LỖI TRÀN VIỀN:
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: colors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: colors.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: colors.primary),
        // titlePadding: EdgeInsets.zero, // LỖI 1: Đã Xóa dòng này
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: colors.secondary, // Vàng
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
        todayDecoration: BoxDecoration(
          color: colors.primary.withOpacity(0.3), // Xanh nhạt
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
        defaultTextStyle: TextStyle(color: Colors.black87),
        weekendTextStyle: TextStyle(color: Colors.red[600]),
        outsideDaysVisible: false,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        // SỬA LỖI TRÀN VIỀN & LỖI 2:
        // Đảm bảo logic đúng: format(date).substring(0, 1)
        dowTextFormatter: (date, locale) =>
            DateFormat.E(locale).format(date).substring(0, 1),
        weekendStyle: TextStyle(
          color: Colors.red[600],
          fontWeight: FontWeight.w500,
        ),
        weekdayStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Chú thích
  Widget _buildLegend(ColorScheme colors) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(colors.secondary, "Đang chọn", colors.primary),
            _buildLegendItem(Colors.redAccent[100]!, "Đã đặt", Colors.black54),
            _buildLegendItem(
              Colors.grey.shade200,
              "Còn trống",
              Colors.black54,
            ), // Sửa màu
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, Color textColor) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Widget Tiêu đề Mục
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Widget Biểu Đồ Đặt Sân (Gantt Chart)
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

  bool _isSlotBooked(int courtNum, int timeSlot) {
    return bookings.any(
      (b) => b.courtNumber == courtNum && b.timeSlot == timeSlot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const double colWidth = 70.0;
    const double rowHeaderWidth = 65.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderTime(context, colWidth, rowHeaderWidth, colors),
          ...List.generate(availableCourts, (index) {
            final courtNum = index + 1;
            return _buildCourtRow(
              context,
              courtNum,
              colWidth,
              rowHeaderWidth,
              colors,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderTime(
    BuildContext context,
    double colWidth,
    double rowHeaderWidth,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        Container(
          // Ô trống đầu tiên
          width: rowHeaderWidth,
          height: 45, // Chiều cao hàng Header
          decoration: BoxDecoration(
            color: colors.primary, // Màu xanh đậm
            border: Border(
              bottom: BorderSide(color: Colors.white24, width: 1),
              right: BorderSide(color: Colors.white24, width: 1),
            ),
          ),
        ),
        ...timeSlots
            .map(
              (time) => Container(
                width: colWidth,
                height: 45, // Chiều cao hàng Header
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
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildCourtRow(
    BuildContext context,
    int courtNum,
    double colWidth,
    double rowHeaderWidth,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        Container(
          width: rowHeaderWidth,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(
              0.9,
            ), // Màu xanh đậm (nhạt hơn header)
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
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        ...timeSlots.map((timeSlot) {
          final isBooked = _isSlotBooked(courtNum, timeSlot);
          final isSelected =
              selectedCourtNumber == courtNum && selectedTimeSlot == timeSlot;

          Color cellColor;
          Widget? cellIcon;

          if (isSelected) {
            cellColor = colors.secondary; // Vàng
            cellIcon = Icon(
              Icons.check_circle,
              color: colors.primary,
              size: 20,
            );
          } else if (isBooked) {
            cellColor = Colors.redAccent[100]!.withOpacity(0.8); // Đỏ
            cellIcon = Icon(
              Icons.lock,
              color: Colors.white.withOpacity(0.8),
              size: 18,
            );
          } else {
            cellColor = Colors.grey.shade200; // Trống (màu xám nhạt)
            cellIcon = null;
          }

          return GestureDetector(
            onTap: () => onSlotSelected(courtNum, timeSlot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: colWidth,
              height: 60,
              decoration: BoxDecoration(
                color: cellColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                  right: BorderSide(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
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
