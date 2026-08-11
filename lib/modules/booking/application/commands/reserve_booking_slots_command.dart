import 'package:badminton_ai/core/cqrs/command.dart';

class ReserveBookingSlotsCommand extends ICommand {
  final String courtId;
  final String courtName;
  final DateTime bookingDate;
  final String transactionId;
  final List<Map<String, dynamic>> slots;
  final int holdMinutes;

  const ReserveBookingSlotsCommand({
    required this.courtId,
    required this.courtName,
    required this.bookingDate,
    required this.transactionId,
    required this.slots,
    this.holdMinutes = 5,
  });

  @override
  List<Object?> get props => [
        courtId,
        courtName,
        bookingDate,
        transactionId,
        slots,
        holdMinutes,
      ];
}
