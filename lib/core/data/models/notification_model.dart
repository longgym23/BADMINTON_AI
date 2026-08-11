class NotificationModel {
  final String? id;
  final String userId;
  final String type; // 'booking_success', 'booking_cancelled', etc.
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  // Thông tin booking (nếu là thông báo về booking)
  final String? bookingId;
  final String? courtName;
  final String? courtAddress;
  final int? courtNumber;
  final DateTime? bookingDate;
  final int? timeSlot;
  final int? price;

  NotificationModel({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.bookingId,
    this.courtName,
    this.courtAddress,
    this.courtNumber,
    this.bookingDate,
    this.timeSlot,
    this.price,
  });

  factory NotificationModel.fromSupabase(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id']?.toString() ?? '',
      userId: data['user_id'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      isRead: data['is_read'] ?? false,
      // Các trường extra json chưa có trong bảng notifications cơ bản
      // Nếu muốn lưu thêm, cần cột `metadata` jsonb/json
      bookingId: null,
      courtName: null,
      courtAddress: null,
      courtNumber: null,
      bookingDate: null,
      timeSlot: null,
      price: null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? bookingId,
    String? courtName,
    String? courtAddress,
    int? courtNumber,
    DateTime? bookingDate,
    int? timeSlot,
    int? price,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId ?? this.bookingId,
      courtName: courtName ?? this.courtName,
      courtAddress: courtAddress ?? this.courtAddress,
      courtNumber: courtNumber ?? this.courtNumber,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      price: price ?? this.price,
    );
  }
}
