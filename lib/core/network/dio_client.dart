import 'dart:async';

import 'package:dio/dio.dart';
import 'package:network_inspector/common/utils/dio_interceptor.dart';
import 'package:network_inspector/network_inspector.dart';

import '../../app/app_config.dart';
import '../debug/network_inspector_toggle.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  DioClient({
    required SecureStorageService secureStorage,
    FutureOr<void> Function()? onSessionExpired,
  }) : _secureStorage = secureStorage,
       _onSessionExpired = onSessionExpired,
       dio = Dio(
         BaseOptions(
           baseUrl: AppConfig.baseUrl,
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 30),
           sendTimeout: const Duration(seconds: 30),
           headers: const {
             'Accept': 'application/json',
             'Content-Type': 'application/json',
           },
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] == true) {
            handler.next(options);
            return;
          }

          final token = await secureStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final requestOptions = error.requestOptions;
          final isUnauthorized = error.response?.statusCode == 401;
          final requiresAuth = requestOptions.extra['skipAuth'] != true;
          if (!isUnauthorized || !requiresAuth) {
            handler.next(error);
            return;
          }

          if (requestOptions.extra['retried'] == true) {
            await _expireSession();
            handler.next(error);
            return;
          }

          try {
            final accessToken = await _refreshAccessToken();
            if (accessToken == null) {
              handler.next(error);
              return;
            }

            final retryOptions = requestOptions.copyWith(
              headers: {
                ...requestOptions.headers,
                'Authorization': 'Bearer $accessToken',
              },
              extra: {...requestOptions.extra, 'retried': true},
            );
            final retryResponse = await dio.fetch<Object?>(retryOptions);
            handler.resolve(retryResponse);
          } on DioException {
            handler.next(error);
          }
        },
      ),
    );

    if (isNetworkInspectorEnabledAtStartup) {
      dio.interceptors.add(
        DioInterceptor(
          logIsAllowed: true,
          isConsoleLogAllowed: true,
          networkInspector: NetworkInspector(),
        ),
      );
    }
  }

  final SecureStorageService _secureStorage;
  final FutureOr<void> Function()? _onSessionExpired;
  final Dio dio;
  Future<String?>? _refreshFuture;

  Future<String?> _refreshAccessToken() async {
    final refreshInProgress = _refreshFuture;
    if (refreshInProgress != null) {
      return refreshInProgress;
    }

    final refreshFuture = _performTokenRefresh();
    _refreshFuture = refreshFuture;
    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<String?> _performTokenRefresh() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    try {
      final refreshResponse = await dio.post<Object?>(
        '/v1/mobile/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final payload = refreshResponse.data;
      final session = payload is Map<String, dynamic> ? payload['data'] : null;
      if (session is! Map<String, dynamic>) {
        await _expireSession();
        return null;
      }

      final accessToken = session['accessToken'] as String? ?? '';
      final nextRefreshToken = session['refreshToken'] as String? ?? '';
      if (accessToken.isEmpty || nextRefreshToken.isEmpty) {
        await _expireSession();
        return null;
      }

      await _secureStorage.saveSession(
        accessToken: accessToken,
        accessTokenExpiresAt: session['accessTokenExpiresAt'] as String? ?? '',
        refreshToken: nextRefreshToken,
        refreshTokenExpiresAt:
            session['refreshTokenExpiresAt'] as String? ?? '',
      );
      return accessToken;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        await _expireSession();
        return null;
      }
      // Timeout, offline, rate limiting, and server failures do not prove the
      // refresh token is invalid. Preserve both the session and durable outbox
      // so a later foreground sync can retry safely.
      rethrow;
    } catch (_) {
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _secureStorage.clearSession();
    await _onSessionExpired?.call();
  }
}
