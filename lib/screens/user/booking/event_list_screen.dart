import 'package:provider/provider.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/screens/user/booking/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventListScreen extends StatelessWidget {
  final CourtLocationModel court;

  const EventListScreen({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0e7a46);
    const cardColor = Color(0xFF129057); // Slightly lighter green for cards

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Đặt lịch sự kiện',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Hôm nay trở đi',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: context.read<SupabaseRepository>().getEventsStream(courtId: court.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải dữ liệu.', style: TextStyle(color: Colors.white)));
                }

                final events = snapshot.data ?? [];
                
                if (events.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(context, events[index], cardColor);
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
          Icon(Icons.event_busy, size: 80, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Chưa có sự kiện nào đang mở',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng quay lại sau',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, Color cardColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event, court: court),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
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
                        color: Color(0xFFFFD54F), // Yellow text
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
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Time and Court
              Text(
                '${event.startTime} - ${event.endTime} | ${event.courtArea}',
                style: const TextStyle(
                  color: Colors.white,
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.sports_tennis, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.sportType,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
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
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              
              // Bottom Row (Avatars, Slots, Price, Arrow)
              Row(
                children: [
                  // Avatars 
                  SizedBox(
                    width: 40,
                    height: 28, // height matches avatar size
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          left: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'),
                          ),
                        ),
                        if (event.currentParticipants > 1)
                          const Positioned(
                            left: 18,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bubble slots
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22B97A), // vibrant green
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${event.currentParticipants}/${event.maxParticipants}',
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
                      border: Border.all(color: const Color(0xFFFFD54F)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(event.price / 1000).toStringAsFixed(0)}k/Vé',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              // The next row: actually the arrow button is slightly below or floating at the bottom right.
              // We can see in the design it's below the price tag, or right aligned.
              // Let's place it here.
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
