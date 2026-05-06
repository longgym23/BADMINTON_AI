import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/domain/entities/booking.dart';

class BookingMapper {
  static Booking toEntity(BookingModel model) {
    return Booking(
      id: model.id ?? '',
      userId: model.userId,
      courtId: model.courtId,
      courtName: model.courtName,
      courtNumber: model.courtNumber,
      date: model.date,
      timeSlot: model.timeSlot,
      price: model.price,
      status: BookingStatusExtension.fromString(model.status),
      transactionId: model.transactionId,
    );
  }

  static BookingModel toModel(Booking entity) {
    return BookingModel(
      id: entity.id.isEmpty ? null : entity.id,
      userId: entity.userId,
      userName: '',
      courtId: entity.courtId,
      courtName: entity.courtName,
      courtNumber: entity.courtNumber,
      date: entity.date,
      timeSlot: entity.timeSlot,
      price: entity.price,
      status: entity.status.value,
      transactionId: entity.transactionId,
    );
  }
}
