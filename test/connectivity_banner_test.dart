import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/core/sync/sync_policy.dart';
import 'package:curva_mobile/shared/widgets/connectivity_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline indicator remains visible when status UI is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncPolicyProvider.overrideWithValue(const SyncPolicy()),
          connectivityStateProvider.overrideWith(
            (ref) => Stream.value(const ConnectivityState.offline()),
          ),
          syncStatusProvider.overrideWith(
            (ref) => Stream.value(const SyncStatus()),
          ),
          pendingOperationCountProvider.overrideWith((ref) => Stream.value(0)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Column(children: [ConnectivityBanner()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.textContaining('Mode offline'), findsOneWidget);
  });
}
