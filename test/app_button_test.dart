import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/shared/widgets/app_button.dart';

void main() {
  Widget buildButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppButton(
            label: isLoading ? 'Menyimpan...' : 'Simpan',
            isLoading: isLoading,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  testWidgets('loading state shows progress and disables the callback', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      buildButton(isLoading: true, onPressed: () => presses += 1),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(presses, 0);
  });

  testWidgets('idle state remains actionable', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      buildButton(isLoading: false, onPressed: () => presses += 1),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(presses, 1);
  });
}
