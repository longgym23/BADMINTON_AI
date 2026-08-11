import 'package:badminton_ai/core/cqrs/command.dart';
import 'package:badminton_ai/core/cqrs/command_bus.dart';
import 'package:badminton_ai/core/cqrs/module_mediator.dart';
import 'package:badminton_ai/core/cqrs/pipeline/execution_context.dart';
import 'package:badminton_ai/core/cqrs/query.dart';
import 'package:badminton_ai/core/cqrs/query_bus.dart';

/// Public facade for the Booking module — presentation must call through this.
abstract class IBookingModule extends IModuleMediator {}

class BookingModuleMediator implements IBookingModule {
  final CommandBus _commandBus;
  final QueryBus _queryBus;

  BookingModuleMediator({
    required CommandBus commandBus,
    required QueryBus queryBus,
  })  : _commandBus = commandBus,
        _queryBus = queryBus;

  @override
  Future<R> executeCommand<C extends ICommand, R>(
    C command, {
    ExecutionContext? context,
  }) {
    return _commandBus.dispatch<C, R>(command, context: context);
  }

  @override
  Future<R> executeQuery<Q extends IQuery, R>(Q query) {
    return _queryBus.dispatch<Q, R>(query);
  }
}
