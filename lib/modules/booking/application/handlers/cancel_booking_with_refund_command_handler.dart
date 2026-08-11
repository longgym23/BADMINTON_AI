import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/cancel_booking_with_refund_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class CancelBookingWithRefundCommandHandler
    implements ICommandHandler<CancelBookingWithRefundCommand, void> {
  final IBookingRepository _bookingRepository;

  CancelBookingWithRefundCommandHandler({
    required IBookingRepository bookingRepository,
  }) : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(CancelBookingWithRefundCommand command) {
    return _bookingRepository.cancelBookingWithRefund(command.booking);
  }
}
