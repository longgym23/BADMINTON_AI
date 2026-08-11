/// Pure-Dart booking aggregate for the Booking bounded context.
/// Field names mirror `BookingModel` so the strangler mapper stays trivial.
class BookingEntity {
  final String? id;
  final String userId;
  final String userName;
  final String courtId;
  final String courtName;
  final int courtNumber;
  final DateTime date;
  final int timeSlot;
  final int price;
  final String status;
  final String? transactionId;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const BookingEntity({
    this.id,
    required this.userId,
    required this.userName,
    required this.courtId,
    required this.courtName,
    required this.courtNumber,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.status,
    this.transactionId,
    this.createdAt,
    this.expiresAt,
  });

  BookingEntity copyWith({
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
    return BookingEntity(
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
