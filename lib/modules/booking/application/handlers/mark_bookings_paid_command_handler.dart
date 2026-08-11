import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/mark_bookings_paid_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class MarkBookingsPaidCommandHandler
    implements ICommandHandler<MarkBookingsPaidCommand, void> {
  final IBookingRepository _bookingRepository;

  MarkBookingsPaidCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(MarkBookingsPaidCommand command) {
    return _bookingRepository.markBookingsAsPaid(command.transactionId);
  }
}
