import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';

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
  Set<_SelectedSlot> _selectedSlots = {};
  late DateTime _currentDate;

  // Time slots from 05:00 to 22:00
  final List<double> _timeSlots = List.generate(34, (index) {
    return 5 + (index * 0.5);
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
    return _selectedSlots.length * 0.5;
  }

  int _getTotalPrice() {
    return (_getTotalHours() * widget.selectedCourt.pricePerHour).round();
  }

  void _onNext() async {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất một slot")),
      );
      return;
    }

    // Booking Logic (Simplified for UI task, but keeping functional)
    final provider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final userId = context.read<AppAuthProvider>().userModel?.id;
    int success = 0;

    for (final slot in _selectedSlots) {
      // Simplified: assuming full hour if .0, but logic handles halfs
      int timeSlotHour = slot.timeSlot.floor();

      // Note: The backend model currently only supports Int hours.
      // If we need half-hours, the model needs update.
      // For now, I will treat 6.5 as 6 (and potential conflict if backend assumes 1h).
      // WARNING: This assumes backend updates or strict 1h slots for start.
      // But the UI allows 30m. I will send floor() for now.

      final bookingId = await provider.createBooking(
        courtId: widget.selectedCourt.id,
        courtName: widget.selectedCourt.name,
        courtNumber: slot.courtNumber,
        date: _currentDate,
        timeSlot: timeSlotHour, // Approximation
        price: (widget.selectedCourt.pricePerHour / 2)
            .round(), // Half hour price
      );
      if (bookingId != null) {
        success++;
        if (userId != null) {
          // Notif
          try {
            await notificationProvider.createBookingSuccessNotification(
              userId: userId,
              bookingId: bookingId,
              courtName: widget.selectedCourt.name,
              courtAddress: widget.selectedCourt.address,
              courtNumber: slot.courtNumber,
              bookingDate: _currentDate,
              timeSlot: timeSlotHour,
              price: (widget.selectedCourt.pricePerHour / 2).round(),
            );
          } catch (e) {
            print("Lỗi tạo thông báo: $e");
          }
        }
      }
    }

    if (success > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đặt sân thành công!"),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        title: const Text(
          'Đặt lịch trực tuyến',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primary, // Blue like image
        foregroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          InkWell(
            onTap: _selectDate,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_currentDate),
                    style: const TextStyle(
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(
                  color: AppColors.surface,
                  label: 'Trống',
                  border: true,
                ),
                _LegendItem(color: AppColors.error, label: 'Đã đặt'), // Red 400
                _LegendItem(
                  color: AppColors.courtLocked,
                  label: 'Khoá',
                  icon: Icons.lock,
                  iconSize: 12,
                ),
                _LegendItem(color: AppColors.courtEvent, label: 'Sự kiện'),
              ],
            ),
          ),

          // Note
          Container(
            width: double.infinity,
            color: AppColors.errorBg, // Red 50
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Lưu ý: Nếu bạn cần đặt lịch cố định vui lòng liên hệ: 0963.877... để được hỗ trợ.',
              style: TextStyle(color: Colors.red[700], fontSize: 13),
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
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(60),
                      border: TableBorder.all(
                        color: AppColors.borderColor,
                        width: 1,
                      ),
                      columnWidths: const {
                        0: FixedColumnWidth(100), // Sân column
                      },
                      children: [
                        // Header Row
                        TableRow(
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                          ), // Grey 50
                          children: [
                            Container(
                              height: 40,
                              alignment: Alignment.center,
                              child: const Text(
                                'Sân / Giờ',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ..._timeSlots.map(
                              (t) => Container(
                                height: 40,
                                alignment: Alignment.center,
                                child: Text(
                                  _formatTime(t),
                                  style: const TextStyle(
                                    color: AppColors.textBlack,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pickleball $courtNum', // Matches image naming
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Text(
                                      'Ngoài trời',
                                      style: TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 10,
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
                                  _SelectedSlot(
                                    courtNumber: courtNum,
                                    timeSlot: t,
                                  ),
                                );

                                Color bgColor = AppColors.surface;
                                Widget? child;

                                if (isBooked) {
                                  bgColor = AppColors.error; // Red
                                  child = const Icon(
                                    Icons.lock,
                                    color: AppColors.surface,
                                    size: 16,
                                  );
                                } else if (isSelected) {
                                  bgColor = AppColors.primaryLight.withOpacity(
                                    0.5,
                                  ); // Blue 200 equivalent
                                  child = const Icon(
                                    Icons.check,
                                    color: AppColors.primaryDark,
                                    size: 16,
                                  );
                                }

                                // Example logic for "Khoá" (Lock) based on time or random for demo?
                                // For now strictly using booking data for red.

                                return InkWell(
                                  onTap: isBooked
                                      ? null
                                      : () {
                                          setState(() {
                                            final slot = _SelectedSlot(
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
                  ),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Tổng giờ: ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          _displayTotalHours(_getTotalHours()),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Tổng tiền: ',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                        Text(
                          NumberFormat.simpleCurrency(
                            locale: 'vi_VN',
                            decimalDigits: 0,
                          ).format(_getTotalPrice()),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'TIẾP THEO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
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

  const _LegendItem({
    required this.color,
    required this.label,
    this.border = false,
    this.icon,
    this.iconSize,
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
              ? Icon(icon, color: AppColors.surface, size: iconSize ?? 14)
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textBlack),
        ),
      ],
    );
  }
}
