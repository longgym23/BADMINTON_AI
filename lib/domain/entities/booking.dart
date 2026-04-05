import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  final String id;
  final String userId;
  final String courtId;
  final String courtName;
  final int courtNumber;
  final DateTime date;
  final int timeSlot;
  final int price;
  final BookingStatus status;
  final String? transactionId;

  const Booking({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.courtName,
    required this.courtNumber,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.status,
    this.transactionId,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? courtId,
    String? courtName,
    int? courtNumber,
    DateTime? date,
    int? timeSlot,
    int? price,
    BookingStatus? status,
    String? transactionId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courtId: courtId ?? this.courtId,
      courtName: courtName ?? this.courtName,
      courtNumber: courtNumber ?? this.courtNumber,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      price: price ?? this.price,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        courtId,
        courtName,
        courtNumber,
        date,
        timeSlot,
        price,
        status,
        transactionId,
      ];
}

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

extension BookingStatusExtension on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'PENDING_PAYMENT';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
    }
  }

  static BookingStatus fromString(String value) {
    switch (value) {
      case 'PENDING_PAYMENT':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.confirmed;
    }
  }
}