import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/core/data/models/event_model.dart';

class CreateEventPaymentPlaceholderCommand extends ICommand {
  final EventModel event;
  final String userId;
  final String transactionId;
  final int totalPrice;
  final int holdMinutes;

  const CreateEventPaymentPlaceholderCommand({
    required this.event,
    required this.userId,
    required this.transactionId,
    required this.totalPrice,
    this.holdMinutes = 5,
  });

  @override
  List<Object?> get props => [
        event,
        userId,
        transactionId,
        totalPrice,
        holdMinutes,
      ];
}
