import 'package:badminton_ai/core/cqrs/command.dart';

class AddBalanceCommand extends ICommand {
  final String userId;
  final int amount;

  const AddBalanceCommand({required this.userId, required this.amount});

  @override
  List<Object?> get props => [userId, amount];
}
