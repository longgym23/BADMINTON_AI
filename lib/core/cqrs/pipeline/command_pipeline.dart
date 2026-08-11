import 'package:flutter/foundation.dart';

import 'execution_context.dart';

/// Pipeline steps run before a command handler executes.
abstract class CommandPipeline {
  Future<void> process<T>({
    required ExecutionContext context,
    required T command,
  });
}

/// Lightweight pipeline: validate shape + audit log (no tenant ACL yet).
class DefaultCommandPipeline implements CommandPipeline {
  const DefaultCommandPipeline();

  @override
  Future<void> process<T>({
    required ExecutionContext context,
    required T command,
  }) async {
    // 1. Validation — handlers / command constructors own field rules for now.
    // 2. Audit logging
    debugPrint(
      '[CQRS] user=${context.userId} request=${context.requestId} '
      'command=${command.runtimeType}',
    );
    // 3. Access check — reserved for multi-tenant modules.
  }
}
