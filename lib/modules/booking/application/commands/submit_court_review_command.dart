import 'package:badminton_ai/core/cqrs/command.dart';

class SubmitCourtReviewCommand extends ICommand {
  final String courtId;
  final String? userId;
  final int rating;
  final String? comment;

  const SubmitCourtReviewCommand({
    required this.courtId,
    this.userId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [courtId, userId, rating, comment];
}
