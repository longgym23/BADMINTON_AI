import 'package:badminton_ai/core/data/models/booking_model.dart';
import 'package:badminton_ai/modules/booking/domain/entities/booking_entity.dart';

/// Bridges domain [BookingEntity] ↔ legacy presentation/data [BookingModel]
/// so existing UI keeps working during the strangler migration.
class BookingEntityMapper {
  const BookingEntityMapper();

  BookingModel toModel(BookingEntity entity) {
    return BookingModel(
      id: entity.id,
      userId: entity.userId,
      userName: entity.userName,
      courtId: entity.courtId,
      courtName: entity.courtName,
      courtNumber: entity.courtNumber,
      date: entity.date,
      timeSlot: entity.timeSlot,
      price: entity.price,
      status: entity.status,
      transactionId: entity.transactionId,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
    );
  }

  BookingEntity toEntity(BookingModel model) {
    return BookingEntity(
      id: model.id,
      userId: model.userId,
      userName: model.userName,
      courtId: model.courtId,
      courtName: model.courtName,
      courtNumber: model.courtNumber,
      date: model.date,
      timeSlot: model.timeSlot,
      price: model.price,
      status: model.status,
      transactionId: model.transactionId,
      createdAt: model.createdAt,
      expiresAt: model.expiresAt,
    );
  }
}
