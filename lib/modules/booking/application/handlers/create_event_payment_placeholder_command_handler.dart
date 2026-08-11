import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/create_event_payment_placeholder_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class CreateEventPaymentPlaceholderCommandHandler
    implements ICommandHandler<CreateEventPaymentPlaceholderCommand, void> {
  final IBookingRepository _bookingRepository;

  CreateEventPaymentPlaceholderCommandHandler({
    required IBookingRepository bookingRepository,
  }) : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(CreateEventPaymentPlaceholderCommand command) {
    return _bookingRepository.createEventPaymentPlaceholder(
      event: command.event,
      userId: command.userId,
      transactionId: command.transactionId,
      totalPrice: command.totalPrice,
      holdMinutes: command.holdMinutes,
    );
  }
}
