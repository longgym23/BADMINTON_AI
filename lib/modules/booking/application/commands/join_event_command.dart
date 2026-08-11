import 'package:badminton_ai/core/cqrs/command.dart';

class JoinEventCommand extends ICommand {
  final String eventId;
  final String userId;
  final double priceDeduction;
  final int quantity;
  final String? paymentTransactionId;

  const JoinEventCommand({
    required this.eventId,
    required this.userId,
    required this.priceDeduction,
    this.quantity = 1,
    this.paymentTransactionId,
  });

  @override
  List<Object?> get props => [
        eventId,
        userId,
        priceDeduction,
        quantity,
        paymentTransactionId,
      ];
}
