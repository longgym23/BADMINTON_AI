/// Execution metadata (user, tenant, permissions, correlation).
class ExecutionContext {
  final String userId;
  final String? tenantId;
  final List<String> permissions;
  final String requestId;
  final DateTime timestamp;

  ExecutionContext({
    required this.userId,
    this.tenantId,
    this.permissions = const [],
    required this.requestId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  static ExecutionContext anonymous() => ExecutionContext(
        userId: 'anonymous',
        requestId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

  static ExecutionContext forUser(String userId) => ExecutionContext(
        userId: userId,
        requestId: DateTime.now().millisecondsSinceEpoch.toString(),
      );
}
