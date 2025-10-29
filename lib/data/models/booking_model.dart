import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String status; // <-- THÊM DÒNG NÀY

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
  });

  // Chuyển từ Firestore Document sang Model
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id, // Lấy id từ document
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      courtId: data['courtId'] ?? '',
      courtName: data['courtName'] ?? '',
      courtNumber: (data['courtNumber'] as num?)?.toInt() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: (data['timeSlot'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'confirmed', // <-- THÊM DÒNG NÀY (với giá trị mặc định)
    );
  }

  // Chuyển từ Model sang Object để ghi lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'courtId': courtId,
      'courtName': courtName,
      'courtNumber': courtNumber,
      'date': Timestamp.fromDate(date), // Chuyển DateTime thành Timestamp
      'timeSlot': timeSlot,
      'price': price,
      'status': status, // <-- THÊM DÒNG NÀY
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
    );
  }
}

