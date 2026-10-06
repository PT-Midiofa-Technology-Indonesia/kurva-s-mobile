import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'sync_failure.dart';

abstract final class ErrorMapper {
  static AppException fromDio(DioException error) {
    final payload = _payload(error);
    if (error.response?.statusCode == 403) {
      return AppException(
        'Anda tidak mempunyai hak akses untuk fitur ini.',
        kind: AppExceptionKind.forbidden,
        statusCode: 403,
        code: payload?['errorCode'] as String?,
      );
    }
    if (payload != null) {
      return AppException(
        payload['message'] as String? ?? 'Terjadi kesalahan pada server.',
        code: payload['errorCode'] as String?,
        statusCode: error.response?.statusCode,
        details: _details(payload['errors']),
        hasErrors: payload['errors'] is Map,
      );
    }

    if (_isConnectionFailure(error)) {
      return const AppException(
        'Tidak dapat terhubung ke server.',
        kind: AppExceptionKind.connection,
      );
    }

    return AppException(
      error.message ?? 'Terjadi kesalahan jaringan.',
      statusCode: error.response?.statusCode,
    );
  }

  static SyncFailure toSyncFailure(DioException error) {
    final status = error.response?.statusCode;
    final payload = _payload(error);
    final message =
        payload?['message'] as String? ??
        error.message ??
        'Sinkronisasi gagal.';
    final code = payload?['errorCode'] as String?;

    if (status == 401) {
      return SyncFailure(
        kind: SyncFailureKind.auth,
        message: message,
        code: code,
      );
    }
    if (status == 409 && code?.toUpperCase() == 'IDEMPOTENCY_IN_PROGRESS') {
      return SyncFailure(
        kind: SyncFailureKind.retryable,
        message: message,
        code: code,
        retryAfter: _retryAfter(error.response?.headers.value('retry-after')),
      );
    }
    if (status == 409) {
      return SyncFailure(
        kind: SyncFailureKind.conflict,
        message: message,
        code: code,
      );
    }
    if (status == 422 && _isOccurredAtRejection(code, message)) {
      return SyncFailure(
        kind: SyncFailureKind.rejected,
        message: message,
        code: code,
      );
    }
    if (_isConnectionFailure(error) ||
        status == 408 ||
        status == 429 ||
        (status != null && status >= 500)) {
      return SyncFailure(
        kind: SyncFailureKind.retryable,
        message: message,
        code: code,
        retryAfter: _retryAfter(error.response?.headers.value('retry-after')),
      );
    }

    return SyncFailure(
      kind: SyncFailureKind.permanent,
      message: message,
      code: code,
    );
  }

  static bool _isOccurredAtRejection(String? code, String message) {
    const knownCodes = {
      'ATTENDANCE_OCCURRED_AT_EXPIRED',
      'ATTENDANCE_OCCURRED_AT_TOO_OLD',
      'ATTENDANCE_OCCURRED_AT_IN_FUTURE',
      'OCCURRED_AT_EXPIRED',
      'OCCURRED_AT_FUTURE',
      'CLOCK_SKEW',
    };
    if (code != null && knownCodes.contains(code.toUpperCase())) return true;

    // Message matching is deliberately narrow: an unrelated 422 must remain
    // a permanent failure instead of being guessed as a clock rejection.
    final normalized = message.toLowerCase();
    final mentionsField =
        normalized.contains('occurredat') || normalized.contains('occurred_at');
    final mentionsBoundary =
        normalized.contains('7 day') ||
        normalized.contains('7 hari') ||
        normalized.contains('five minute') ||
        normalized.contains('5 minute') ||
        normalized.contains('5 menit') ||
        normalized.contains('too old') ||
        normalized.contains('masa depan') ||
        normalized.contains('future');
    return mentionsField && mentionsBoundary;
  }

  static Map<String, dynamic>? _payload(DioException error) {
    final data = error.response?.data;
    return data is Map<String, dynamic> ? data : null;
  }

  static bool _isConnectionFailure(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    // Several platforms/adapters surface offline TLS/DNS/socket failures as
    // `unknown` without a typed SocketException. Without an HTTP response from
    // the server, sync must keep the operation retryable.
    return error.response == null && error.type == DioExceptionType.unknown;
  }

  static List<String> _details(Object? errors) {
    if (errors is List) {
      return errors.map((item) => item.toString()).toList(growable: false);
    }
    if (errors is! Map<String, dynamic>) return const [];

    return errors.entries
        .expand((entry) {
          final value = entry.value;
          if (value is List) {
            return value.map((item) => '${entry.key}: $item');
          }
          return ['${entry.key}: $value'];
        })
        .toList(growable: false);
  }

  static Duration? _retryAfter(String? value) {
    if (value == null) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) return Duration(seconds: seconds);

    final date = DateTime.tryParse(value)?.toUtc();
    if (date == null) return null;
    final duration = date.difference(DateTime.now().toUtc());
    return duration.isNegative ? Duration.zero : duration;
  }
}
