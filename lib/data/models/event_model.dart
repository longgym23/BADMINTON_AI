

class EventModel {
  final String id;
  final String eventCode; // e.g. #5157
  final String title;
  final String description;
  final DateTime dateTime;
  final String startTime; // e.g. 14h00
  final String endTime;   // e.g. 18h00
  final String courtArea;  // e.g. Sân 4
  final String sportType; // e.g. Cầu lông
  final String level;     // e.g. 2.0 -> 3.0
  final double price;
  final int maxParticipants;
  final int currentParticipants;
  final String courtId;

  EventModel({
    required this.id,
    required this.eventCode,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.startTime,
    required this.endTime,
    required this.courtArea,
    required this.sportType,
    required this.level,
    required this.price,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.courtId,
  });

  factory EventModel.fromSupabase(Map<String, dynamic> data) {
    return EventModel(
      id: data['id'],
      eventCode: data['event_code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateTime: DateTime.tryParse(data['date_time'].toString()) ?? DateTime.now(),
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      courtArea: data['court_area'] ?? '',
      sportType: data['sport_type'] ?? '',
      level: data['level'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      maxParticipants: (data['max_participants'] as num?)?.toInt() ?? 0,
      currentParticipants: (data['current_participants'] as num?)?.toInt() ?? 0,
      courtId: data['court_id'] ?? '',
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (id.isNotEmpty) 'id': id,
      'event_code': eventCode,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'court_area': courtArea,
      'sport_type': sportType,
      'level': level,
      'price': price,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'court_id': courtId,
    };
  }
}

class MockEventData {
  static final List<EventModel> globalEvents = [
    EventModel(
      id: 'ev_1',
      eventCode: '#5157',
      title: '[Xé vé] - Xé Vé trình khá trên 6 tháng',
      description: 'Cùng nhau tập luyện và nâng cao sức khỏe sau giờ làm việc. Anh em nhớ mang theo vợt và giày đánh cầu lông chuyên dụng. Đã bao gồm nước suối trà đá.',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      startTime: '14h00',
      endTime: '18h00',
      courtArea: 'Sân 4',
      sportType: 'Cầu lông',
      level: '2.0 -> 3.0',
      price: 70000,
      maxParticipants: 8,
      currentParticipants: 2,
      courtId: 'court_1',
    ),
    EventModel(
      id: 'ev_2',
      eventCode: '#5182',
      title: '[Xé vé] - Xé Vé trình khá trên 6 tháng',
      description: 'Giải đấu giao lưu với sự tham gia của nhiều nhóm. Tham gia để cọ xát và học hỏi kinh nghiệm. Lệ phí đã bao gồm tiền cầu và trọng tài.',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      startTime: '17h00',
      endTime: '20h00',
      courtArea: 'Sân 2',
      sportType: 'Cầu lông',
      level: '2.0 -> 3.0',
      price: 90000,
      maxParticipants: 8,
      currentParticipants: 1,
      courtId: 'court_1',
    ),
    EventModel(
      id: 'ev_3',
      eventCode: '#5183',
      title: '[Xé vé] - Xé Vé trình khá trên 6 tháng',
      description: 'Lớp sửa lỗi kỹ thuật trực tiếp nhận đăng ký trên app.',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      startTime: '14h00',
      endTime: '18h00',
      courtArea: 'Sân 2',
      sportType: 'Cầu lông',
      level: '2.0 -> 3.0',
      price: 70000,
      maxParticipants: 8,
      currentParticipants: 0,
      courtId: 'court_1',
    ),
  ];

  static List<EventModel> getMockEventsForCourt(String courtId) {
    // For demo purposes, we will return all global events anyway to show data 
    // unless the app has actual court IDs, then we filter.
    return globalEvents;
  }
}
