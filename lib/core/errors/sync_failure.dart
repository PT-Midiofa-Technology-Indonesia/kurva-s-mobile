enum SyncFailureKind { auth, retryable, permanent, conflict, rejected }

class SyncFailure implements Exception {
  const SyncFailure({
    required this.kind,
    required this.message,
    this.code,
    this.retryAfter,
  });

  final SyncFailureKind kind;
  final String message;
  final String? code;
  final Duration? retryAfter;

  @override
  String toString() => code == null ? message : '$code: $message';
}
