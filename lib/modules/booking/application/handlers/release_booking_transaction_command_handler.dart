import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/release_booking_transaction_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class ReleaseBookingTransactionCommandHandler
    implements ICommandHandler<ReleaseBookingTransactionCommand, int> {
  final IBookingRepository _bookingRepository;

  ReleaseBookingTransactionCommandHandler({
    required IBookingRepository bookingRepository,
  }) : _bookingRepository = bookingRepository;

  @override
  Future<int> execute(ReleaseBookingTransactionCommand command) {
    return _bookingRepository.releaseBookingTransaction(command.transactionId);
  }
}
