import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      bookingId: data['bookingId'],
      courtName: data['courtName'],
      courtAddress: data['courtAddress'],
      courtNumber: (data['courtNumber'] as num?)?.toInt(),
      bookingDate: (data['bookingDate'] as Timestamp?)?.toDate(),
      timeSlot: (data['timeSlot'] as num?)?.toInt(),
      price: (data['price'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (bookingId != null) 'bookingId': bookingId,
      if (courtName != null) 'courtName': courtName,
      if (courtAddress != null) 'courtAddress': courtAddress,
      if (courtNumber != null) 'courtNumber': courtNumber,
      if (bookingDate != null) 'bookingDate': Timestamp.fromDate(bookingDate!),
      if (timeSlot != null) 'timeSlot': timeSlot,
      if (price != null) 'price': price,
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

