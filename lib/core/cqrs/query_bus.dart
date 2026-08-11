import 'package:badminton_ai/core/cqrs/query.dart';

/// Central QueryBus for registering and dispatching CQRS Queries.
class QueryBus {
  final Map<Type, IQueryHandler<dynamic, dynamic>> _handlersMap = {};

  void registerHandler<Q extends IQuery, R>(IQueryHandler<Q, R> handler) {
    _handlersMap[Q] = handler;
  }

  Future<R> dispatch<Q extends IQuery, R>(Q query) async {
    final handler = _handlersMap[query.runtimeType] as IQueryHandler<Q, R>?;
    if (handler == null) {
      throw StateError(
        'No QueryHandler registered for query type: ${query.runtimeType}',
      );
    }
    return handler.execute(query);
  }
}
