import 'package:badminton_ai/core/cqrs/command.dart';

class MarkBookingsPaidCommand extends ICommand {
  final String transactionId;

  const MarkBookingsPaidCommand({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}
