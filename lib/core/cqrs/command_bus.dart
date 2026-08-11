import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/core/cqrs/pipeline/command_pipeline.dart';
import 'package:badminton_ai/core/cqrs/pipeline/execution_context.dart';

/// Central CommandBus for registering and dispatching CQRS Commands.
class CommandBus {
  CommandBus({CommandPipeline? pipeline})
      : _pipeline = pipeline ?? const DefaultCommandPipeline();

  final CommandPipeline _pipeline;
  final Map<Type, ICommandHandler<dynamic, dynamic>> _handlersMap = {};

  void registerHandler<C extends ICommand, R>(ICommandHandler<C, R> handler) {
    _handlersMap[C] = handler;
  }

  Future<R> dispatch<C extends ICommand, R>(
    C command, {
    ExecutionContext? context,
  }) async {
    final handler = _handlersMap[command.runtimeType] as ICommandHandler<C, R>?;
    if (handler == null) {
      throw StateError(
        'No CommandHandler registered for command type: ${command.runtimeType}',
      );
    }

    await _pipeline.process(
      context: context ?? ExecutionContext.anonymous(),
      command: command,
    );

    return handler.execute(command);
  }
}
