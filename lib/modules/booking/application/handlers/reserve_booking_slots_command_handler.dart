import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/reserve_booking_slots_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class ReserveBookingSlotsCommandHandler
    implements ICommandHandler<ReserveBookingSlotsCommand, Map<String, dynamic>> {
  final IBookingRepository _bookingRepository;

  ReserveBookingSlotsCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<Map<String, dynamic>> execute(ReserveBookingSlotsCommand command) {
    return _bookingRepository.reserveBookingSlots(
      courtId: command.courtId,
      courtName: command.courtName,
      bookingDate: command.bookingDate,
      transactionId: command.transactionId,
      slots: command.slots,
      holdMinutes: command.holdMinutes,
    );
  }
}
