import 'package:badminton_ai/core/cqrs/command.dart';

class DeductBalanceCommand extends ICommand {
  final String userId;
  final int amount;

  const DeductBalanceCommand({required this.userId, required this.amount});

  @override
  List<Object?> get props => [userId, amount];
}
