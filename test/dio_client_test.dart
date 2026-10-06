import 'dart:async';
import 'dart:typed_data';

import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  group('DioClient unauthorized handling', () {
    test('refreshes the token and retries the original request once', () async {
      final storage = _FakeSecureStorage(
        accessToken: 'expired-access-token',
        refreshToken: 'valid-refresh-token',
      );
      var refreshCalls = 0;
      var resourceCalls = 0;
      var sessionExpiredCalls = 0;
      final client = DioClient(
        secureStorage: storage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        if (options.path == '/v1/mobile/auth/refresh') {
          refreshCalls++;
          return _jsonResponse(_validRefreshResponse, 200);
        }

        resourceCalls++;
        if (options.headers['Authorization'] == 'Bearer fresh-access-token') {
          return _jsonResponse('{"data":{"ok":true}}', 200);
        }
        return _jsonResponse('{"message":"Unauthorized"}', 401);
      });

      final response = await client.dio.get<Object?>('/protected');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(resourceCalls, 2);
      expect(storage.accessToken, 'fresh-access-token');
      expect(storage.refreshToken, 'fresh-refresh-token');
      expect(sessionExpiredCalls, 0);
    });

    test('uses one refresh request for concurrent 401 responses', () async {
      final storage = _FakeSecureStorage(
        accessToken: 'expired-access-token',
        refreshToken: 'valid-refresh-token',
      );
      var refreshCalls = 0;
      final client = DioClient(secureStorage: storage);
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        if (options.path == '/v1/mobile/auth/refresh') {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _jsonResponse(_validRefreshResponse, 200);
        }

        if (options.headers['Authorization'] == 'Bearer fresh-access-token') {
          return _jsonResponse('{"data":{"ok":true}}', 200);
        }
        return _jsonResponse('{"message":"Unauthorized"}', 401);
      });

      final responses = await Future.wait([
        client.dio.get<Object?>('/first'),
        client.dio.get<Object?>('/second'),
      ]);

      expect(
        responses.map((response) => response.statusCode),
        everyElement(200),
      );
      expect(refreshCalls, 1);
    });

    test('clears the session when token refresh fails', () async {
      final storage = _FakeSecureStorage(
        accessToken: 'expired-access-token',
        refreshToken: 'expired-refresh-token',
      );
      var sessionExpiredCalls = 0;
      final client = DioClient(
        secureStorage: storage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        return _jsonResponse('{"message":"Unauthorized"}', 401);
      });

      await expectLater(
        client.dio.get<Object?>('/protected'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'status code',
            401,
          ),
        ),
      );

      expect(storage.clearSessionCalls, 1);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(sessionExpiredCalls, 1);
    });

    test('does not refresh or clear session for skipAuth requests', () async {
      final storage = _FakeSecureStorage(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );
      var sessionExpiredCalls = 0;
      final client = DioClient(
        secureStorage: storage,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        return _jsonResponse('{"message":"Invalid credentials"}', 401);
      });

      await expectLater(
        client.dio.post<Object?>(
          '/v1/mobile/auth/login',
          options: Options(extra: {'skipAuth': true}),
        ),
        throwsA(isA<DioException>()),
      );

      expect(storage.clearSessionCalls, 0);
      expect(sessionExpiredCalls, 0);
    });
  });
}

const _validRefreshResponse = '''
{
  "data": {
    "accessToken": "fresh-access-token",
    "accessTokenExpiresAt": "2099-01-01T00:00:00Z",
    "refreshToken": "fresh-refresh-token",
    "refreshTokenExpiresAt": "2099-02-01T00:00:00Z"
  }
}
''';

ResponseBody _jsonResponse(String body, int statusCode) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this.callback);

  final Future<ResponseBody> Function(RequestOptions options) callback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return callback(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage extends SecureStorageService {
  _FakeSecureStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  int clearSessionCalls = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String accessTokenExpiresAt,
    required String refreshToken,
    required String refreshTokenExpiresAt,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearSession() async {
    clearSessionCalls++;
    accessToken = null;
    refreshToken = null;
  }
}
