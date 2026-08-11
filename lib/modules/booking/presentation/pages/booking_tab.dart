import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';
import 'package:badminton_ai/modules/booking/presentation/controllers/booking_provider.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/court_selection_screen.dart';
import 'package:flutter/material.dart';
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
    final bookingRepo = context.read<IBookingRepository>();
    final colors = Theme.of(context).colorScheme;

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
                  colors: [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'screens.setThePitch1'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'screens.selectDateAndCourseToSche'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 1. Lịch chọn ngày
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SectionHeader(
                icon: Icons.sports_tennis_rounded,
                title: 'screens.1ChooseAYard'.tr(),
                color: colors.primary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: StreamBuilder<List<CourtLocationModel>>(
                stream: bookingRepo.watchCourts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _selectedCourt == null) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'screens.pitchLoadingError'.tr(),
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final courts = snapshot.data ?? [];
                  if (courts.isEmpty) {
                    return Text(
                      'screens.thereIsNoYardYet'.tr(),
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
                    return Center(child: CircularProgressIndicator());
                  }

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
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
              padding: EdgeInsets.all(16.0),
              child: _selectedCourt == null
                  ? Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'screens.pleaseSelectACourseAbove'.tr(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      icon: Icon(Icons.calendar_view_week_rounded),
                      label: Text(
                        'screens.chooseATimeFrame'.tr(),
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
          color: colors.primary.withValues(alpha: 0.3), // Xanh nhạt
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
          color: Colors.black.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
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
        SizedBox(width: 8),
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
