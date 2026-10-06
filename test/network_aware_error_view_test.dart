import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/errors/error_mapper.dart';
import 'package:curva_mobile/core/sync/sync_policy.dart';
import 'package:dio/dio.dart';
import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildView({
    required ConnectivityState connectivity,
    String? message,
    Object? error,
    bool cacheEnabled = false,
  }) {
    return ProviderScope(
      overrides: [
        syncPolicyProvider.overrideWithValue(
          SyncPolicy(
            readCapabilities: {
              if (cacheEnabled) 'projectCacheRead': ReadCapability.cacheRead,
            },
          ),
        ),
        connectivityStateProvider.overrideWith(
          (ref) => Stream.value(connectivity),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: NetworkAwareErrorView(
            error: error,
            message: message,
            cacheFeatureKey: 'projectCacheRead',
            onRetry: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows offline copy when connectivity reports offline', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildView(
        connectivity: const ConnectivityState.offline(),
        message: 'Kesalahan lain.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fitur hanya tersedia online'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('uses connection error as fallback for connectivity race', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildView(
        connectivity: const ConnectivityState.online(),
        message: 'Tidak dapat terhubung ke server.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fitur hanya tersedia online'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('keeps non-network errors unchanged while online', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildView(
        connectivity: const ConnectivityState.online(),
        message: 'Data tidak ditemukan.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Terjadi kesalahan'), findsOneWidget);
    expect(find.text('Data tidak ditemukan.'), findsOneWidget);
  });
  for (final offline in [true, false]) {
    for (final payload in [
      null,
      '<html>Forbidden</html>',
      {'message': 'Forbidden', 'errorCode': 'DENIED'},
    ]) {
      testWidgets('403 stays forbidden offline=$offline payload=$payload', (
        tester,
      ) async {
        final options = RequestOptions(path: '/test');
        final error = ErrorMapper.fromDio(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 403,
              data: payload,
            ),
          ),
        );
        expect(error.statusCode, 403);
        await tester.pumpWidget(
          buildView(
            connectivity: offline
                ? const ConnectivityState.offline()
                : const ConnectivityState.online(),
            error: error,
            cacheEnabled: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Akses ditolak'), findsOneWidget);
        expect(
          find.text('Anda tidak mempunyai hak akses untuk fitur ini.'),
          findsOneWidget,
        );
        expect(find.byType(OutlinedButton), findsNothing);
      });
    }
  }

  for (final cacheEnabled in [true, false]) {
    testWidgets('connection error respects cache flag $cacheEnabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildView(
          connectivity: const ConnectivityState.online(),
          error: const AppException(
            'Tidak dapat terhubung ke server.',
            kind: AppExceptionKind.connection,
          ),
          cacheEnabled: cacheEnabled,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          cacheEnabled
              ? 'Tidak ada koneksi internet'
              : 'Fitur hanya tersedia online',
        ),
        findsOneWidget,
      );
      if (cacheEnabled) {
        expect(find.textContaining('Data belum tersimpan'), findsOneWidget);
      }
    });
  }

  testWidgets('HTTP server error stays visible while offline', (tester) async {
    await tester.pumpWidget(
      buildView(
        connectivity: const ConnectivityState.offline(),
        error: const AppException('Server sedang bermasalah.', statusCode: 500),
        cacheEnabled: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Server sedang bermasalah.'), findsOneWidget);
    expect(find.text('Terjadi kesalahan'), findsOneWidget);
  });

  testWidgets(
    'typed cache miss survives connectivity recovery and retry works',
    (tester) async {
      var retried = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStateProvider.overrideWith(
              (ref) => Stream.value(const ConnectivityState.online()),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareErrorView(
                error: const AppException(
                  'Belum ada cache.',
                  kind: AppExceptionKind.offlineCacheMiss,
                ),
                onRetry: () => retried = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada koneksi internet'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(retried, isTrue);
    },
  );
}
