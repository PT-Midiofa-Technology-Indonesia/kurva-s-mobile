import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _accessTokenExpiresAtKey = 'access_token_expires_at';
  static const _refreshTokenKey = 'refresh_token';
  static const _refreshTokenExpiresAtKey = 'refresh_token_expires_at';
  static const _authUserKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<String?> readAuthUser() {
    return _storage.read(key: _authUserKey);
  }

  Future<void> saveAuthUser(String userJson) {
    return _storage.write(key: _authUserKey, value: userJson);
  }

  Future<void> saveSession({
    required String accessToken,
    required String accessTokenExpiresAt,
    required String refreshToken,
    required String refreshTokenExpiresAt,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(
        key: _accessTokenExpiresAtKey,
        value: accessTokenExpiresAt,
      ),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(
        key: _refreshTokenExpiresAtKey,
        value: refreshTokenExpiresAt,
      ),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiresAtKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _refreshTokenExpiresAtKey),
      _storage.delete(key: _authUserKey),
    ]);
  }
}
