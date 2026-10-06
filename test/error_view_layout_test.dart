import 'package:curva_mobile/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final height in [220.0, 700.0]) {
    testWidgets('error content remains reachable at height $height', (
      tester,
    ) async {
      tester.view.physicalSize = Size(360, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      const message =
          'INTERNAL_SERVER_ERROR: Terjadi kesalahan. Silakan coba lagi. '
          'Pesan panjang harus tetap dapat dibaca seluruhnya.';
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ErrorView(message: message, onRetry: () => retries++),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(message));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      final button = tester.getRect(find.byType(FilledButton));
      expect(button.top, greaterThanOrEqualTo(0));
      expect(button.bottom, lessThanOrEqualTo(height));
      await tester.tap(find.byType(FilledButton));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
