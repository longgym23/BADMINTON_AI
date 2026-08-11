import 'package:equatable/equatable.dart';

/// Base interface for all Commands in CQRS Architecture.
abstract class ICommand extends Equatable {
  const ICommand();
}

/// Handler contract for executing a specific Command [C] returning Result [R].
abstract class ICommandHandler<C extends ICommand, R> {
  Future<R> execute(C command);
}
