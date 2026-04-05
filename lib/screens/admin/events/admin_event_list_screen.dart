import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/screens/admin/events/admin_create_event_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/screens/user/booking/components/booking_history/calendar_theme.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminEventListScreen extends StatefulWidget {
  const AdminEventListScreen({super.key});

  @override
  State<AdminEventListScreen> createState() => _AdminEventListScreenState();
}

class _AdminEventListScreenState extends State<AdminEventListScreen> {
  DateTimeRange? _selectedDateRange;

  void _selectDateRange(BuildContext context) async {
    DateTime? tempStart = _selectedDateRange?.start;
    DateTime? tempEnd = _selectedDateRange?.end;
    DateTime focusedDay = tempStart ?? DateTime.now();

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: BookingCalendarTheme.dialogShape,
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            content: SizedBox(
              width: BookingCalendarTheme.dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableCalendar(
                    focusedDay: focusedDay,
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    rangeStartDay: tempStart,
                    rangeEndDay: tempEnd,
                    rangeSelectionMode: RangeSelectionMode.enforced,
                    onRangeSelected: (start, end, focused) {
                      setState(() {
                        tempStart = start;
                        tempEnd = end;
                        focusedDay = focused;
                      });
                    },
                    locale: 'vi_VN',
                    headerStyle: BookingCalendarTheme.headerStyle(
                      formatter: (date, locale) => 'Tháng ${date.month}, ${date.year}',
                    ),
                    calendarStyle: BookingCalendarTheme.calendarStyle,
                    daysOfWeekStyle: BookingCalendarTheme.daysOfWeekStyle,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      BookingCalendarTheme.cancelButton(onPressed: () => Navigator.pop(ctx), label: 'Huỷ'),
                      const SizedBox(width: 16),
                      BookingCalendarTheme.confirmButton(
                        onPressed: () {
                          if (tempStart != null) {
                            Navigator.pop(ctx, DateTimeRange(start: tempStart!, end: tempEnd ?? tempStart!));
                          } else {
                            Navigator.pop(ctx);
                          }
                        }, 
                        label: 'Xác nhận',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _confirmDelete(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá sự kiện "${event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                MockEventData.globalEvents.removeWhere((e) => e.id == event.id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa sự kiện!')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter events by selected date range
    final allEvents = MockEventData.globalEvents;
    final filteredEvents = allEvents.where((e) {
      if (_selectedDateRange == null) return true;
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end.add(const Duration(days: 1, milliseconds: -1));
      return e.dateTime.isAfter(start) && e.dateTime.isBefore(end);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Quản lý sự kiện',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brandOrangeDark, AppColors.brandOrangeLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _selectDateRange(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedDateRange != null ? AppColors.brandOrangeLight.withOpacity(0.1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedDateRange != null ? AppColors.brandOrangeDark : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedDateRange != null
                              ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                              : 'Chọn khoảng ngày',
                          style: TextStyle(
                            color: _selectedDateRange != null ? AppColors.brandOrangeDark : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: _selectedDateRange != null ? AppColors.brandOrangeDark : Colors.grey[600],
                        ),
                        if (_selectedDateRange != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDateRange = null;
                              });
                            },
                            child: const Icon(Icons.close, size: 18, color: Colors.red),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(
                    child: Text(
                      'Tạm thời chưa có sự kiện nào\ntrong khoảng thời gian này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date & Time Column
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandOrangeLight.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('dd/MM').format(event.dateTime),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brandOrangeDark,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.startTime,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Information Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${event.eventCode} - ${event.title}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              event.courtArea,
                                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.people, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Đã tham gia: ${event.currentParticipants}/${event.maxParticipants}',
                                            style: TextStyle(
                                              color: event.currentParticipants >= event.maxParticipants 
                                                  ? Colors.red 
                                                  : Colors.green,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${event.price.toInt()}đ',
                                            style: const TextStyle(
                                              color: AppColors.brandOrangeDark,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Actions
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _confirmDelete(event),
                                      tooltip: 'Xóa sự kiện',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCreateEventScreen()),
          );
          setState(() {});
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sự kiện', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
