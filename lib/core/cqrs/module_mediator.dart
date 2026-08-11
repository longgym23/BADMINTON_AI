import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/core/cqrs/pipeline/execution_context.dart';
import 'package:badminton_ai/core/cqrs/query.dart';

/// Single public entry-point facade for a bounded-context module.
abstract class IModuleMediator {
  Future<R> executeCommand<C extends ICommand, R>(
    C command, {
    ExecutionContext? context,
  });

  Future<R> executeQuery<Q extends IQuery, R>(Q query);
}
