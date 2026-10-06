enum AppExceptionKind { general, connection, offlineCacheMiss, forbidden }

class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.kind = AppExceptionKind.general,
    this.statusCode,
    this.details = const [],
    this.hasErrors = false,
  });

  final String message;
  final AppExceptionKind kind;
  final int? statusCode;

  final String? code;
  final List<String> details;
  final bool hasErrors;

  bool get isAccessDenied =>
      kind == AppExceptionKind.forbidden ||
      statusCode == 401 ||
      statusCode == 403;

  String get detailedMessage {
    if (details.isEmpty) return message;

    return '$message\n${details.join('\n')}';
  }

  @override
  String toString() {
    final value = code == null ? message : '$code: $message';
    if (details.isEmpty) return value;

    return '$value ${details.join(' ')}';
  }
}
