import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/deduct_balance_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class DeductBalanceCommandHandler
    implements ICommandHandler<DeductBalanceCommand, void> {
  final IBookingRepository _bookingRepository;

  DeductBalanceCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(DeductBalanceCommand command) {
    return _bookingRepository.deductBalance(command.userId, command.amount);
  }
}
