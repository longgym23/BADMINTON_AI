import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/screens/user/booking/checkout_screen.dart';
import 'package:badminton_ai/screens/user/booking/event_detail_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';

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
  late Stream<List<EventModel>> _eventsStream;

  // Time slots from 05:00 to 22:00
  final List<double> _timeSlots = List.generate(18, (index) {
    return 5 + (index * 1.0);
  });

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    if (widget.selectedDate.isBefore(todayMidnight)) {
      _currentDate = todayMidnight;
    } else {
      _currentDate = widget.selectedDate;
    }
    _eventsStream = context.read<SupabaseRepository>().getEventsStream(
      courtId: widget.selectedCourt.id,
    );
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
      AppToast.show(
        context,
        'screens.pleaseSelectAtLeastOneSlo'.tr(),
        type: ToastType.error,
      );
      return;
    }

    _reserveAndGoCheckout();
  }

  Future<void> _reserveAndGoCheckout() async {
    final now = DateTime.now();
    final isToday = isSameDay(_currentDate, now);
    final isPastDay = _currentDate.isBefore(
      DateTime(now.year, now.month, now.day),
    );

    if (isPastDay) {
      AppToast.show(
        context,
        'screens.coursesCannotBeBookedForD'.tr(),
        type: ToastType.error,
      );
      return;
    }

    if (_selectedSlots.any((s) => isToday && s.timeSlot <= now.hour)) {
      AppToast.show(
        context,
        'screens.someOfTheTimeFramesYouSe'.tr(),
        type: ToastType.error,
      );
      return;
    }

    final auth = context.read<AppAuthProvider>();
    if (auth.authState != AuthState.authenticated) {
      AppToast.show(
        context,
        'screens.pleaseLogInToReserveAPit'.tr(),
        type: ToastType.error,
      );
      return;
    }

    final repo = context.read<SupabaseRepository>();
    final totalPrice = _getTotalPrice();

    // Generate transaction id (must be stable across reserve + payment reference).
    final transactionId =
        '${widget.selectedCourt.id.substring(0, 5)}${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Build slots payload for RPC
    final slots = _selectedSlots
        .map(
          (s) => {
            'court_number': s.courtNumber,
            'time_slot': s.timeSlot.toInt(),
            'price': widget.selectedCourt.pricePerHour.round(),
          },
        )
        .toList();

    DialogUtils.showCustomDialog(
      context,
      title: '',
      content: Row(
        children: [
          CupertinoActivityIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('screens.holdingASeat'.tr())),
        ],
      ),
    );

    try {
      final result = await repo.reserveBookingSlots(
        courtId: widget.selectedCourt.id,
        courtName: widget.selectedCourt.name,
        bookingDate: _currentDate,
        transactionId: transactionId,
        slots: slots,
        holdMinutes: 5,
      );

      if (mounted) Navigator.pop(context); // close loading

      final success = result['success'] == true;
      if (!success) {
        final conflicts = result['conflicts'];
        final msg = conflicts is List && conflicts.isNotEmpty
            ? 'screens.someTimeSlotsHaveJustBeen'.tr()
            : 'screens.reservationsCannotBeMadeP'.tr();
        AppToast.show(context, msg, type: ToastType.error);
        _fetchBookingsForCurrentDate();
        return;
      }

      DateTime? expiresAt;
      final expiresRaw = result['expires_at'];
      if (expiresRaw != null) {
        expiresAt = DateTime.tryParse(expiresRaw.toString());
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            selectedCourt: widget.selectedCourt,
            selectedDate: _currentDate,
            selectedSlots: _selectedSlots.toList(),
            totalHours: _getTotalHours(),
            totalPrice: totalPrice,
            reservedTransactionId: transactionId,
            reservedExpiresAt: expiresAt,
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppToast.show(context, 'Lỗi giữ chỗ: $e', type: ToastType.error);
    }
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
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      locale: 'vi_VN',
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: tempFocusedDate.isBefore(DateTime.now())
                          ? DateTime.now()
                          : tempFocusedDate,
                      currentDay: DateTime.now(),
                      enabledDayPredicate: (day) => !day.isBefore(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      ),
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
                      headerStyle: HeaderStyle(
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
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: AppColors.textGrey),
                        weekendStyle: TextStyle(color: AppColors.textGrey),
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
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
                        todayTextStyle: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        defaultDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        weekendDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        outsideDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('screens.cancel1'.tr(),
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, tempSelectedDate),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text('screens.confirm'.tr(),
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
      appBar: CustomGradientAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('screens.scheduleOnline'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: _selectDate,
              child: Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(_currentDate),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
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
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LegendItem(
                      color: Colors.white,
                      label: 'screens.drum'.tr(),
                      labelColor: Colors.white,
                    ),
                    _LegendItem(
                      color: Color(0xFFEF5350),
                      label: 'screens.booked'.tr(),
                      labelColor: Colors.white,
                    ),
                    _LegendItem(
                      color: Color(0xFFE0E0E0),
                      label: 'screens.lockedExpired'.tr(),
                      labelColor: AppColors.textGrey,
                      icon: Icons.block,
                      iconSize: 12,
                    ),
                    _LegendItem(
                      color: Color(0xFFBA68C8),
                      label: 'screens.event'.tr(),
                      labelColor: Colors.white,
                    ),
                  ],
                ),
                SizedBox(height: 12),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'screens.note'.tr(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    'screens.theYardHasARetractableCan'.tr(),
                    style: TextStyle(color: AppColors.textBlack, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final allEvents = snapshot.data ?? [];
                final events = allEvents.where((e) {
                  return _eventOverlapsSelectedDate(e);
                }).toList();
                return StreamBuilder<List<BookingModel>>(
                  stream: bookingProvider.bookingsStream,
                  builder: (context, bookingSnapshot) {
                    if (bookingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final bookings = bookingSnapshot.data ?? [];
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row (Independent from Table to avoid vertical borders)
                            Container(
                              decoration: BoxDecoration(
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
                                    padding: EdgeInsets.only(
                                      left: 0,
                                      right: 20,
                                    ),
                                    child: Text('screens.yardHour'.tr(),
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
                                                  style: TextStyle(
                                                    color: AppColors.textBlack,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                Container(
                                                  width: 3,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
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
                                                _formatTime(
                                                  _timeSlots.last + 1,
                                                ),
                                                style: TextStyle(
                                                  color: AppColors.textBlack,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 6),
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
                                ],
                              ),
                            ),
                            // TABLE for cells
                            Table(
                              defaultColumnWidth: const FixedColumnWidth(60),
                              border: TableBorder(
                                left: BorderSide(color: AppColors.borderColor),
                                right: BorderSide(color: AppColors.borderColor),
                                bottom: BorderSide(
                                  color: AppColors.borderColor,
                                ),
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
                                        color: Color(
                                          0xFFFFF8E1,
                                        ), // Very light yellow-orange for court column
                                        padding: EdgeInsets.symmetric(
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
                                              style: TextStyle(
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
                                        final eventForSlot = _getEventForSlot(
                                          events,
                                          courtNum,
                                          t,
                                        );
                                        final isEventSlot =
                                            eventForSlot != null;
                                        final isSelected = _selectedSlots
                                            .contains(
                                              SelectedSlot(
                                                courtNumber: courtNum,
                                                timeSlot: t,
                                              ),
                                            );

                                        final now = DateTime.now();
                                        final isToday = isSameDay(
                                          _currentDate,
                                          now,
                                        );
                                        final isPastDay = _currentDate.isBefore(
                                          DateTime(
                                            now.year,
                                            now.month,
                                            now.day,
                                          ),
                                        );
                                        final isPastTime =
                                            isToday && t <= now.hour;
                                        final isDisable =
                                            isPastDay || isPastTime;

                                        Color bgColor = AppColors.surface;
                                        Widget? child;

                                        if (isDisable) {
                                          bgColor = Color(
                                            0xFFE0E0E0,
                                          ); // Grey for past/disabled
                                          child = Icon(
                                            Icons.block,
                                            color: Colors.white,
                                            size: 16,
                                          );
                                        } else if (isBooked) {
                                          bgColor = Color(
                                            0xFFEF5350,
                                          ); // Red
                                          child = null;
                                        } else if (isEventSlot) {
                                          bgColor = Color(
                                            0xFFBA68C8,
                                          ); // Event purple
                                          child = null;
                                        } else if (isSelected) {
                                          bgColor = AppColors.primary;
                                          child = Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          );
                                        }

                                        return InkWell(
                                          onTap: (isBooked || isDisable)
                                              ? null
                                              : () {
                                                  if (eventForSlot != null) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            EventDetailScreen(
                                                              event:
                                                                  eventForSlot,
                                                              court: widget
                                                                  .selectedCourt,
                                                            ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  setState(() {
                                                    final slot = SelectedSlot(
                                                      courtNumber: courtNum,
                                                      timeSlot: t,
                                                    );
                                                    if (isSelected) {
                                                      _selectedSlots.remove(
                                                        slot,
                                                      );
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
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFFFFFDF7), // Very pale tint
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
                          Text('screens.totalHours'.tr(),
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _displayTotalHours(_getTotalHours()),
                            style: TextStyle(
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
                          Text('screens.totalAmount'.tr(),
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            NumberFormat.simpleCurrency(
                              locale: 'vi_VN',
                              decimalDigits: 0,
                            ).format(_getTotalPrice()),
                            style: TextStyle(
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors
                            .primary, // Đổi màu sắc để khớp với Đặt Ngay
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('screens.nEXT'.tr(),
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

  bool _eventOverlapsSelectedDate(EventModel event) {
    final dayStart = DateTime(
      _currentDate.year,
      _currentDate.month,
      _currentDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    final eventStart = event.startDateTime;
    final eventEnd = event.endDateTime;

    if (eventStart == null || eventEnd == null) return false;
    return eventStart.isBefore(dayEnd) && eventEnd.isAfter(dayStart);
  }

  EventModel? _getEventForSlot(
    List<EventModel> events,
    int courtNum,
    double time,
  ) {
    final slotStart = DateTime(
      _currentDate.year,
      _currentDate.month,
      _currentDate.day,
      time.floor(),
      0,
    );
    final slotEnd = slotStart.add(const Duration(hours: 1));

    for (final event in events) {
      final eventCourtNum = _extractCourtNumber(event.courtArea);
      if (eventCourtNum != null && eventCourtNum != courtNum) continue;

      final eventStart = event.startDateTime;
      final eventEnd = event.endDateTime;
      if (eventStart == null || eventEnd == null) continue;

      if (eventStart.isBefore(slotEnd) && eventEnd.isAfter(slotStart)) {
        return event;
      }
    }

    return null;
  }

  int? _extractCourtNumber(String courtArea) {
    final match = RegExp(r'\d+').firstMatch(courtArea);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;
  final double? iconSize;
  final Color? labelColor;

  const _LegendItem({
    required this.color,
    required this.label,
    this.icon,
    this.iconSize,
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
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: Colors.white, size: iconSize ?? 14)
              : null,
        ),
        SizedBox(width: 6),
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
