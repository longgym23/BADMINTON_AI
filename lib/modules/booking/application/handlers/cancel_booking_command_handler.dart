import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/cancel_booking_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class CancelBookingCommandHandler
    implements ICommandHandler<CancelBookingCommand, void> {
  final IBookingRepository _bookingRepository;

  CancelBookingCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(CancelBookingCommand command) {
    return _bookingRepository.cancelBooking(command.bookingId);
  }
}
