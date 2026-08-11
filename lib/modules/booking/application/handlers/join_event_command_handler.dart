import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/join_event_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class JoinEventCommandHandler implements ICommandHandler<JoinEventCommand, void> {
  final IBookingRepository _bookingRepository;

  JoinEventCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(JoinEventCommand command) {
    return _bookingRepository.joinEvent(
      command.eventId,
      command.userId,
      command.priceDeduction,
      quantity: command.quantity,
      paymentTransactionId: command.paymentTransactionId,
    );
  }
}
