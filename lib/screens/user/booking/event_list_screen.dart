import 'package:provider/provider.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/screens/user/booking/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/custom_date_range_picker_dialog.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class EventListScreen extends StatefulWidget {
  final CourtLocationModel court;

  const EventListScreen({super.key, required this.court});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  DateTimeRange? _selectedDateRange;

  Future<void> _presentDateRangePicker() async {
    final result = await showCustomDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      cancelLabel: 'Huỷ',
      confirmLabel: 'Xác nhận',
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text(
          'Đặt lịch sự kiện',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color:Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedDateRange != null)
                  TextButton.icon(
                    onPressed: _clearDateFilter,
                    icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                    label: const Text('Bỏ lọc', style: TextStyle(color: Colors.red)),
                  )
                else
                  const SizedBox.shrink(),
                GestureDetector(
                  onTap: _presentDateRangePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedDateRange == null
                              ? 'Hôm nay trở đi'
                              : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: context.read<SupabaseRepository>().getEventsStream(courtId: widget.court.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải dữ liệu.', style: TextStyle(color: AppColors.textGrey)));
                }

                final allEvents = snapshot.data ?? [];
                
                // Lọc theo khoảng ngày
                final events = allEvents.where((e) {
                  if (_selectedDateRange == null) {
                    // Nếu không lọc, mặc định lấy sự kiện từ hôm nay trở đi
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final eventDate = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
                    return eventDate.isAfter(today.subtract(const Duration(days: 1)));
                  }
                  
                  final start = _selectedDateRange!.start;
                  final end = _selectedDateRange!.end;
                  final eventDate = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
                  final filterStart = DateTime(start.year, start.month, start.day);
                  final filterEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

                  return eventDate.isAfter(filterStart.subtract(const Duration(days: 1))) && 
                         eventDate.isBefore(filterEnd.add(const Duration(days: 1)));
                }).toList();
                
                if (events.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(context, events[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: AppColors.textGrey),
          SizedBox(height: 16),
          Text(
            'Chưa có sự kiện nào đang mở',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng thử khoảng thời gian thay thế.',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final isBookable = event.isBookable;
    final statusText = event.isEnded
        ? 'Đã kết thúc'
        : (event.availableParticipants == 0 ? 'Hết vé' : 'Đang mở');
    final statusColor = event.isEnded
        ? Colors.grey
        : (event.availableParticipants == 0
              ? AppColors.error
              : const Color(0xFF22B97A));

    return GestureDetector(
      onTap: !isBookable
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event, court: widget.court),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor, width: 0.5),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Date Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${event.eventCode}: ${event.title}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(event.dateTime),
                    style: const TextStyle(
                      color: AppColors.brandOrange, // Highlight date
                      fontSize: 13,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Time and Court
              Text(
                '${event.startTime} - ${event.endTime} | ${event.courtArea}',
                style: const TextStyle(
                  color: AppColors.textBlack,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              
              // Sport Badge and Info Icon Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.sports_tennis, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.sportType,
                          style: const TextStyle(color: AppColors.textBlack, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event.level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderColor, height: 1),
              const SizedBox(height: 16),
              // Bottom Row (Avatars, Slots, Price, Arrow)
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$statusText · ${event.currentParticipants}/${event.maxParticipants}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Price Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.brandOrange, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(event.price / 1000).toStringAsFixed(0)}k/Vé',
                      style: const TextStyle(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isBookable) ...[
                const SizedBox(height: 10),
                const Text(
                  'Sự kiện này không còn khả dụng để đặt vé.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
