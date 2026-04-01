import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/screens/user/booking/checkout_screen.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

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

class SelectedSlot {
  final int courtNumber;
  final double timeSlot;

  SelectedSlot({required this.courtNumber, required this.timeSlot});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedSlot &&
          runtimeType == other.runtimeType &&
          courtNumber == other.courtNumber &&
          timeSlot == other.timeSlot;

  @override
  int get hashCode => courtNumber.hashCode ^ timeSlot.hashCode;
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  Set<SelectedSlot> _selectedSlots = {};
  late DateTime _currentDate;

  // Time slots from 05:00 to 22:00
  final List<double> _timeSlots = List.generate(18, (index) {
    return 5 + (index * 1.0);
  });

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookingsForCurrentDate();
    });
  }

  void _fetchBookingsForCurrentDate() {
    context.read<BookingProvider>().fetchBookingsForDay(
      widget.selectedCourt.id,
      _currentDate,
    );
  }

  void _onDateChanged(DateTime newDate) {
    if (newDate != _currentDate) {
      setState(() {
        _currentDate = newDate;
        _selectedSlots.clear();
      });
      _fetchBookingsForCurrentDate();
    }
  }

  double _getTotalHours() {
    return _selectedSlots.length * 1.0;
  }

  int _getTotalPrice() {
    return (_getTotalHours() * widget.selectedCourt.pricePerHour).round();
  }

  void _onNext() {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất một slot")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          selectedCourt: widget.selectedCourt,
          selectedDate: _currentDate,
          selectedSlots: _selectedSlots.toList(),
          totalHours: _getTotalHours(),
          totalPrice: _getTotalPrice(),
        ),
      ),
    );
  }

  void _selectDate() async {
    DateTime tempSelectedDate = _currentDate;
    DateTime tempFocusedDate = _currentDate;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      locale: 'vi_VN',
                      firstDay: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: tempFocusedDate,
                      currentDay: DateTime.now(),
                      selectedDayPredicate: (day) =>
                          isSameDay(tempSelectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          tempSelectedDate = selectedDay;
                          tempFocusedDate = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        tempFocusedDate = focusedDay;
                      },
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: AppColors.textGrey),
                        weekendStyle: TextStyle(color: AppColors.textGrey),
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        defaultDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        weekendDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        outsideDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, tempSelectedDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  String _displayTotalHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đặt lịch trực tuyến',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent, // Nền trong suốt để hiển thị gradient từ flexibleSpace
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brandOrangeDark, AppColors.brandOrangeLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: _selectDate,
              child: Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(_currentDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            color: Colors.transparent, // Background trong suốt
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _LegendItem(
                      color: Colors.white,
                      label: 'Trống',
                      labelColor: Colors.white,
                    ),
                    const _LegendItem(
                      color: Color(0xFFEF5350),
                      label: 'Đã đặt',
                      labelColor: Colors.white,
                    ),
                    const _LegendItem(
                      color: Color(0xFF9E9E9E),
                      label: 'Khoá',
                      labelColor: Colors.white,
                    ),
                    const _LegendItem(
                      color: Color(0xFFBA68C8),
                      label: 'Sự kiện',
                      labelColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Lưu ý: ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Cụm sân có hệ thống mái che bạt rút (nắng mưa đều chơi được)',
                    style: TextStyle(color: AppColors.textBlack, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: bookingProvider.bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bookings = snapshot.data ?? [];
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row (Independent from Table to avoid vertical borders)
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0), // Light orange header
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFFFCC80)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 100,
                                height: 48,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.only(
                                  left: 0,
                                  right: 20,
                                  ),
                                child: const Text(
                                  'Sân / Giờ',
                                  style: TextStyle(
                                    color: AppColors.textBlack,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              ..._timeSlots.map(
                                (t) => SizedBox(
                                  width: 60,
                                  height: 48,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: -20,
                                        bottom: 0,
                                        width: 40,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              _formatTime(t),
                                              style: const TextStyle(
                                                color: AppColors.textBlack,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 3,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (t == _timeSlots.last)
                                        Positioned(
                                          right: -20,
                                          bottom: 0,
                                          width: 40,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                _formatTime(t + 1),
                                                style: const TextStyle(
                                                  color: AppColors.textBlack,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                width: 3,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // TABLE for cells
                        Table(
                          defaultColumnWidth: const FixedColumnWidth(60),
                          border: const TableBorder(
                            left: BorderSide(color: AppColors.borderColor),
                            right: BorderSide(color: AppColors.borderColor),
                            bottom: BorderSide(color: AppColors.borderColor),
                            horizontalInside: BorderSide(
                              color: AppColors.borderColor,
                            ),
                            verticalInside: BorderSide(
                              color: AppColors.borderColor,
                            ),
                          ),
                          columnWidths: const {
                            0: FixedColumnWidth(100), // Sân column
                          },
                          children: [
                            // Court Rows
                            ...List.generate(widget.selectedCourt.totalCourts, (
                              index,
                            ) {
                              final courtNum = index + 1;
                              return TableRow(
                                children: [
                                  // Court Name Cell
                                  Container(
                                    height: 50,
                                    color: const Color(
                                      0xFFFFF8E1,
                                    ), // Very light yellow-orange for court column
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sân $courtNum',
                                          style: const TextStyle(
                                            color: AppColors.textBlack,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Time Slots
                                  ..._timeSlots.map((t) {
                                    final isBooked = _isSlotBooked(
                                      bookings,
                                      courtNum,
                                      t,
                                    );
                                    final isSelected = _selectedSlots.contains(
                                      SelectedSlot(
                                        courtNumber: courtNum,
                                        timeSlot: t,
                                      ),
                                    );

                                    Color bgColor = AppColors.surface;
                                    Widget? child;

                                    if (isBooked) {
                                      bgColor = const Color(0xFFEF5350); // Red
                                      child = null;
                                    } else if (isSelected) {
                                      bgColor = AppColors
                                          .primary; // Đồng bộ màu nút chính
                                      child = const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      );
                                    }

                                    // Example logic for "Khoá" (Lock) based on time or random for demo?
                                    // For now strictly using booking data for red.

                                    return InkWell(
                                      onTap: isBooked
                                          ? null
                                          : () {
                                              setState(() {
                                                final slot = SelectedSlot(
                                                  courtNumber: courtNum,
                                                  timeSlot: t,
                                                );
                                                if (isSelected) {
                                                  _selectedSlots.remove(slot);
                                                } else {
                                                  _selectedSlots.add(slot);
                                                }
                                              });
                                            },
                                      child: Container(
                                        height: 50,
                                        color: bgColor,
                                        alignment: Alignment.center,
                                        child: child,
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFFDF7), // Very pale tint
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng giờ',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayTotalHours(_getTotalHours()),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Tổng tiền',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.simpleCurrency(
                              locale: 'vi_VN',
                              decimalDigits: 0,
                            ).format(_getTotalPrice()),
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors
                            .primary, // Đổi màu sắc để khớp với Đặt Ngay
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'TIẾP THEO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double t) {
    final h = t.floor();
    final m = ((t - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  bool _isSlotBooked(List<BookingModel> bookings, int courtNum, double time) {
    // Allow for hour blocking
    return bookings.any(
      (b) => b.courtNumber == courtNum && b.timeSlot == time.floor(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool border;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final Color? labelColor;

  const _LegendItem({
    required this.color,
    required this.label,
    this.border = false,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border ? Border.all(color: AppColors.borderColor) : null,
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(
                  icon,
                  color: iconColor ?? Colors.white,
                  size: iconSize ?? 14,
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor ?? AppColors.textBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
