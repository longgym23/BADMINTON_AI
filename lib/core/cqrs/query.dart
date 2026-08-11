import 'package:equatable/equatable.dart';

/// Base interface for all Queries in CQRS Architecture.
abstract class IQuery extends Equatable {
  const IQuery();
}

/// Handler contract for executing a specific Query [Q] returning Result [R].
abstract class IQueryHandler<Q extends IQuery, R> {
  Future<R> execute(Q query);
}
