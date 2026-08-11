import 'package:badminton_ai/core/cqrs/command.dart';

class ReleaseBookingTransactionCommand extends ICommand {
  final String transactionId;

  const ReleaseBookingTransactionCommand({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}
