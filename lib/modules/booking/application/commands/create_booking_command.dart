import 'package:badminton_ai/core/cqrs/command.dart';

class CreateBookingCommand extends ICommand {
  final String userId;
  final String userName;
  final String courtId;
  final String courtName;
  final int courtNumber;
  final DateTime date;
  final int timeSlot;
  final int price;
  final String status;
  final String? transactionId;

  const CreateBookingCommand({
    required this.userId,
    required this.userName,
    required this.courtId,
    required this.courtName,
    required this.courtNumber,
    required this.date,
    required this.timeSlot,
    required this.price,
    this.status = 'confirmed',
    this.transactionId,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        courtId,
        courtName,
        courtNumber,
        date,
        timeSlot,
        price,
        status,
        transactionId,
      ];
}
