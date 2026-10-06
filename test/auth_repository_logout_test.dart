import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/auth/data/auth_repository.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  test(
    'logout clears local session without waiting for server revocation',
    () async {
      final storage = _FakeSecureStorage('access-token');
      final response = Completer<ResponseBody>();
      final requestStarted = Completer<RequestOptions>();
      final client = DioClient(secureStorage: storage);
      client.dio.httpClientAdapter = _CallbackAdapter((options) {
        requestStarted.complete(options);
        return response.future;
      });
      final repository = AuthRepository(
        dioClient: client,
        secureStorage: storage,
      );

      await repository.logout();

      expect(storage.accessToken, isNull);
      expect(storage.clearCalls, 1);
      final request = await requestStarted.future.timeout(
        const Duration(seconds: 1),
      );
      expect(request.path, '/v1/auth/logout');
      expect(request.headers['Authorization'], 'Bearer access-token');

      response.complete(ResponseBody.fromString('{}', 200));
      await Future<void>.delayed(Duration.zero);
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
  ) => callback(options);

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage extends SecureStorageService {
  _FakeSecureStorage(this.accessToken);

  String? accessToken;
  int clearCalls = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<void> clearSession() async {
    clearCalls += 1;
    accessToken = null;
  }
}
