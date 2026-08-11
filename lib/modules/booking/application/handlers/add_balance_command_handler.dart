import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/add_balance_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class AddBalanceCommandHandler implements ICommandHandler<AddBalanceCommand, void> {
  final IBookingRepository _bookingRepository;

  AddBalanceCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(AddBalanceCommand command) {
    return _bookingRepository.addBalance(command.userId, command.amount);
  }
}
