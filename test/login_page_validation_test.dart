import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/auth/auth_providers.dart';
import 'package:curva_mobile/modules/auth/data/auth_repository.dart';
import 'package:curva_mobile/modules/auth/presentation/login_page.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  testWidgets('shows API identity and password errors below their fields', (
    tester,
  ) async {
    final storage = _FakeSecureStorage();
    final repository = _ValidationErrorAuthRepository(
      dioClient: DioClient(secureStorage: storage),
      secureStorage: storage,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'invalid@example.com');
    await tester.enterText(fields.at(1), 'invalid-password');
    await tester.tap(find.text('Masuk').last);
    await tester.pumpAndSettle();

    expect(find.text('Email atau nomor telepon wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    expect(find.text('Periksa kembali data yang ditandai.'), findsNothing);
    expect(find.text('Data yang diberikan tidak valid.'), findsNothing);
  });
}

class _ValidationErrorAuthRepository extends AuthRepository {
  const _ValidationErrorAuthRepository({
    required super.dioClient,
    required super.secureStorage,
  });

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<Never> login({
    required String identity,
    required String password,
    required bool rememberMe,
  }) async {
    throw const AppException(
      'Data yang diberikan tidak valid.',
      code: 'VALIDATION_ERROR',
      details: [
        'identity: Email atau nomor telepon wajib diisi.',
        'password: Kata sandi wajib diisi.',
      ],
      hasErrors: true,
    );
  }
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;
}
