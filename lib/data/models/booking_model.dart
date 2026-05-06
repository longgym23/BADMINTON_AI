import 'package:easy_localization/easy_localization.dart';

class BookingModel {
  final String? id; // id có thể null khi tạo, Firestore sẽ gán
  final String userId;
  final String userName;
  final String courtId;
  final String courtName;
  final int courtNumber;
  final DateTime date;
  final int timeSlot;
  final int price;
  final String status;
  final String? transactionId; // <-- THÊM DÒNG NÀY ĐỂ GỘP HOÁ ĐƠN
  final DateTime? createdAt; // dùng để timeout PENDING_PAYMENT ở client
  final DateTime? expiresAt; // optional: nếu DB có field này

  BookingModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.courtId,
    required this.courtName,
    required this.courtNumber,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.status, // <-- THÊM DÒNG NÀY
    this.transactionId,
    this.createdAt,
    this.expiresAt,
  });


  // Chuyển từ Supabase (Map snake_case) sang Model
  factory BookingModel.fromSupabase(Map<String, dynamic> data) {
    return BookingModel(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      userName:
          '', // Supabase thường join bảng profiles để lấy name, hoặc lưu cache. Tạm để trống hoặc xử lý sau.
      courtId: data['court_id'] ?? '',
      courtName: data['court_name'] ?? '',
      courtNumber: (data['court_number'] as num?)?.toInt() ?? 0,
      // Date trong Supabase trả về String (yyyy-MM-dd)
      date: data['booking_date'] != null
          ? DateTime.parse(data['booking_date'])
          : DateTime.now(),
      timeSlot: (data['time_slot'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'confirmed',
      transactionId: data['transaction_id'],
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
      expiresAt: data['expires_at'] != null ? DateTime.parse(data['expires_at']) : null,
    );
  }

  // Chuyển sang Map để insert vào Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'court_id': courtId,
      'court_name': courtName,
      'court_number': courtNumber,
      'booking_date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'time_slot': timeSlot,
      'price': price,
      'status': status,
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }



  // (Thêm) Hàm copyWith để dễ dàng cập nhật
  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? courtId,
    String? courtName,
    int? courtNumber,
    DateTime? date,
    int? timeSlot,
    int? price,
    String? status,
    String? transactionId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      courtId: courtId ?? this.courtId,
      courtName: courtName ?? this.courtName,
      courtNumber: courtNumber ?? this.courtNumber,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      price: price ?? this.price,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
