import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/create_booking_command.dart';
import 'package:badminton_ai/modules/booking/domain/entities/booking_entity.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class CreateBookingCommandHandler
    implements ICommandHandler<CreateBookingCommand, String> {
  final IBookingRepository _bookingRepository;

  CreateBookingCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<String> execute(CreateBookingCommand command) {
    return _bookingRepository.createBooking(
      BookingEntity(
        userId: command.userId,
        userName: command.userName,
        courtId: command.courtId,
        courtName: command.courtName,
        courtNumber: command.courtNumber,
        date: command.date,
        timeSlot: command.timeSlot,
        price: command.price,
        status: command.status,
        transactionId: command.transactionId,
      ),
    );
  }
}
