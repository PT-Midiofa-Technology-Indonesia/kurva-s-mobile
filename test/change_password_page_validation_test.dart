import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/auth/auth_providers.dart';
import 'package:curva_mobile/modules/auth/data/auth_repository.dart';
import 'package:curva_mobile/modules/profile/presentation/pages/change_password_page.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  testWidgets('shows API password errors below their respective fields', (
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
        child: const MaterialApp(home: ChangePasswordPage()),
      ),
    );

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'old-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'new-password');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi saat ini wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi baru wajib diisi.'), findsOneWidget);
    expect(find.text('Ulangi kata sandi baru wajib diisi.'), findsOneWidget);
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
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    throw const AppException(
      'Data yang diberikan tidak valid.',
      code: 'VALIDATION_ERROR',
      details: [
        'currentPassword: Kata sandi saat ini wajib diisi.',
        'newPassword: Kata sandi baru wajib diisi.',
        'newPasswordConfirmation: Ulangi kata sandi baru wajib diisi.',
      ],
      hasErrors: true,
    );
  }
}

class _FakeSecureStorage extends SecureStorageService {}
