import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/event_model.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_date_range_picker_dialog.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';

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
      cancelLabel: 'screens.cancel'.tr(),
      confirmLabel: 'screens.confirm'.tr(),
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
        title: Text('screens.scheduleAnEvent'.tr(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color:Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Filter Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedDateRange != null)
                  TextButton.icon(
                    onPressed: _clearDateFilter,
                    icon: Icon(Icons.clear, size: 16, color: Colors.red),
                    label: Text('screens.unfilter'.tr(), style: TextStyle(color: Colors.red)),
                  )
                else
                  SizedBox.shrink(),
                GestureDetector(
                  onTap: _presentDateRangePicker,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: VColors.brandPrimary, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedDateRange == null
                              ? 'screens.todayOnwards'.tr()
                              : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                          style: TextStyle(color: VColors.brandPrimary, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.calendar_month, color: VColors.brandPrimary, size: 18),
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
                  return Center(child: CircularProgressIndicator(color: VColors.brandPrimary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('screens.errorLoadingData'.tr(), style: TextStyle(color: VColors.textSecondary)));
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
                  padding: EdgeInsets.symmetric(horizontal: 16),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: VColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'screens.thereAreNoOpenEventsYet'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: VColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'screens.pleaseTryAnAlternateInterv'.tr(),
            style: TextStyle(color: VColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final isBookable = event.isBookable;
    final statusText = event.isEnded
        ? 'screens.itSOver'.tr()
        : (event.availableParticipants == 0 ? 'screens.ticketsSoldOut'.tr() : 'screens.open'.tr());
    final statusColor = event.isEnded
        ? Colors.grey
        : (event.availableParticipants == 0
              ? VColors.statusCritical
              : Color(0xFF22B97A));

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
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VColors.borderDefault, width: 0.5),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
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
                      style: TextStyle(
                        color: VColors.brandPrimaryDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(event.dateTime),
                    style: TextStyle(
                      color: VColors.brandPrimary, // Highlight date
                      fontSize: 13,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              // Time and Court
              Text(
                '${event.startTime} - ${event.endTime} | ${event.courtArea}',
                style: TextStyle(
                  color: VColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              
              // Sport Badge and Info Icon Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: VColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.sports_tennis, size: 16, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text(
                          event.sportType,
                          style: TextStyle(color: VColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: VColors.brandPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event.level,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.info_outline, color: VColors.brandPrimary, size: 20),
                ],
              ),
              SizedBox(height: 16),
              Divider(color: VColors.borderDefault, height: 1),
              SizedBox(height: 16),
              // Bottom Row (Avatars, Slots, Price, Arrow)
              Row(
                children: [
                   Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$statusText · ${event.currentParticipants}/${event.maxParticipants}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Price Tag
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: VColors.brandPrimary, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(event.price / 1000).toStringAsFixed(0)}k/Vé',
                      style: TextStyle(
                        color: VColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isBookable) ...[
                SizedBox(height: 10),
                Text('screens.thisEventIsNoLongerAvaila'.tr(),
                  style: TextStyle(
                    color: VColors.textSecondary,
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
