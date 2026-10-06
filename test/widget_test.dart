import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/app/app.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/auth/auth_providers.dart';

void main() {
  testWidgets('Login renders after splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(
            _FakeSecureStorageService(),
          ),
        ],
        child: const CurvaApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsAtLeastNWidgets(2));
    expect(find.text('Masukkan email dan kata sandimu'), findsOneWidget);
    expect(find.text('Email'), findsNWidgets(2));
    expect(find.text('Nomor Telepon'), findsOneWidget);
    expect(find.text('Ingat Saya'), findsOneWidget);
    expect(find.text('CURVA-S'), findsOneWidget);

    await tester.tap(find.text('Nomor Telepon'));
    await tester.pumpAndSettle();

    expect(
      find.text('Masukkan nomor telepon dan kata sandimu'),
      findsOneWidget,
    );
    expect(find.text('+62'), findsOneWidget);
    expect(find.text('Nomor Telepon'), findsNWidgets(2));
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String accessTokenExpiresAt,
    required String refreshToken,
    required String refreshTokenExpiresAt,
  }) async {}

  @override
  Future<void> clearSession() async {}
}
