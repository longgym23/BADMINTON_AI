import 'package:badminton_ai/core/cqrs/command.dart';

class CancelBookingCommand extends ICommand {
  final String bookingId;

  const CancelBookingCommand({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}
