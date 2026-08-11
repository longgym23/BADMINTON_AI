import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/domain/entities/booking_entity.dart';

class CancelBookingWithRefundCommand extends ICommand {
  final BookingEntity booking;

  const CancelBookingWithRefundCommand({required this.booking});

  @override
  List<Object?> get props => [booking];
}
