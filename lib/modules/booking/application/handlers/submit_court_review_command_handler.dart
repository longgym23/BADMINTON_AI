import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/modules/booking/application/commands/submit_court_review_command.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';

class SubmitCourtReviewCommandHandler
    implements ICommandHandler<SubmitCourtReviewCommand, void> {
  final IBookingRepository _bookingRepository;

  SubmitCourtReviewCommandHandler({required IBookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  @override
  Future<void> execute(SubmitCourtReviewCommand command) {
    return _bookingRepository.submitReview(
      courtId: command.courtId,
      userId: command.userId,
      rating: command.rating,
      comment: command.comment,
    );
  }
}
