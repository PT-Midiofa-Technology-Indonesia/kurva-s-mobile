import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models/auth_session.dart';
import 'models/auth_user.dart';

class AuthRepository {
  const AuthRepository({
    required DioClient dioClient,
    required SecureStorageService secureStorage,
  }) : _dioClient = dioClient,
       _secureStorage = secureStorage;

  final DioClient _dioClient;
  final SecureStorageService _secureStorage;
  static const _logoutRequestTimeout = Duration(seconds: 5);

  Future<AuthSession> login({
    required String identity,
    required String password,
    required bool rememberMe,
  }) async {
    final response = await _post(
      '/v1/mobile/auth/login',
      data: {
        'identity': identity,
        'password': password,
        'rememberMe': rememberMe,
      },
      skipAuth: true,
    );
    final session = ApiResponse.fromJson<AuthSession>(
      response,
      (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    ).data;

    await _saveSession(session);
    return session;
  }

  Future<void> logout() async {
    try {
      final accessToken = await _secureStorage.readAccessToken();
      await _secureStorage.clearSession();
      if (accessToken != null && accessToken.isNotEmpty) {
        unawaited(_revokeSession(accessToken));
      }
    } catch (_) {
      // Clearing the local session is the logout contract. If reading the
      // token fails, still make a final attempt to clear all local auth data.
      await _secureStorage.clearSession();
    }
  }

  Future<void> _revokeSession(String accessToken) async {
    try {
      await _dioClient.dio.post<Object?>(
        '/v1/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          extra: {'skipAuth': true},
          connectTimeout: _logoutRequestTimeout,
          receiveTimeout: _logoutRequestTimeout,
          sendTimeout: _logoutRequestTimeout,
        ),
      );
    } catch (_) {
      // Server revocation is best-effort after the durable local session has
      // already been removed. Expiry on the server remains the fallback.
    }
  }

  Future<AuthSession> refreshToken() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AppException(
        'Sesi sudah berakhir. Silakan login kembali.',
        code: 'MISSING_REFRESH_TOKEN',
      );
    }

    final response = await _post(
      '/v1/mobile/auth/refresh',
      data: {'refreshToken': refreshToken},
      skipAuth: true,
    );
    final session = ApiResponse.fromJson<AuthSession>(
      response,
      (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    ).data;

    await _saveSession(session);
    return session;
  }

  Future<AuthUser> me() async {
    final response = await _get('/v1/mobile/auth/me');
    final user = ApiResponse.fromJson<AuthUser>(
      response,
      (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    ).data;
    await _secureStorage.saveAuthUser(jsonEncode(user.toJson()));
    return user;
  }

  Future<AuthUser?> cachedUser() async {
    final rawUser = await _secureStorage.readAuthUser();
    if (rawUser == null || rawUser.isEmpty) return null;

    try {
      final json = jsonDecode(rawUser);
      return json is Map<String, dynamic> ? AuthUser.fromJson(json) : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _post(
      '/v1/mobile/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'newPasswordConfirmation': newPasswordConfirmation,
      },
    );
  }

  Future<bool> hasSession() async {
    final accessToken = await _secureStorage.readAccessToken();
    final refreshToken = await _secureStorage.readRefreshToken();
    final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
    final hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;
    return hasAccessToken || hasRefreshToken;
  }

  Future<void> clearSession() {
    return _secureStorage.clearSession();
  }

  Future<void> _saveSession(AuthSession session) {
    return _secureStorage.saveSession(
      accessToken: session.accessToken,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
      refreshToken: session.refreshToken,
      refreshTokenExpiresAt: session.refreshTokenExpiresAt,
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dioClient.dio.get<Object?>(path);
      return _responseData(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? data,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        path,
        data: data,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      return _responseData(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Map<String, dynamic> _responseData(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const AppException('Format respons server tidak valid.');
  }

  AppException _mapDioException(DioException error) {
    return ErrorMapper.fromDio(error);
  }
}
