import 'package:curva_mobile/app/app_theme.dart';
import 'package:curva_mobile/modules/profile/presentation/pages/term_condition_page.dart';
import 'package:curva_mobile/shared/widgets/searchable_selection_bottom_sheet.dart';
import 'package:curva_mobile/shared/widgets/selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('page scroll viewport stays above three-button navigation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 48);
    tester.view.padding = tester.view.viewPadding;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const TermConditionPage()),
    );
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(ListView));
    expect(viewport.top, greaterThanOrEqualTo(32));
    expect(viewport.bottom, 752);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection sheet avoids landscape cutout and navigation bar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 400);
    tester.view.viewPadding = const FakeViewPadding(
      top: 24,
      left: 44,
      right: 24,
      bottom: 24,
    );
    tester.view.padding = tester.view.viewPadding;
    addTearDown(tester.view.reset);

    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  selected = await SelectionBottomSheet.show<String>(
                    context,
                    title: 'Pilih item',
                    options: const ['Pilihan'],
                    selectedOption: null,
                    labelBuilder: (option) => option,
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.byType(SelectionBottomSheet<String>));
    expect(sheet.left, greaterThanOrEqualTo(44));
    expect(sheet.right, lessThanOrEqualTo(776));
    expect(sheet.top, greaterThanOrEqualTo(24));
    expect(tester.getRect(find.text('Pilihan')).bottom, lessThanOrEqualTo(376));
    await tester.tap(find.text('Pilihan'));
    await tester.pumpAndSettle();
    expect(selected, 'Pilihan');
    expect(tester.takeException(), isNull);
  });

  testWidgets('search sheet keeps filtered options above the keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
    tester.view.padding = tester.view.viewPadding;
    addTearDown(tester.view.reset);

    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  selected = await SearchableSelectionBottomSheet.show<String>(
                    context,
                    title: 'Cari item',
                    options: const ['Alpha', 'Beta'],
                    selectedOption: null,
                    labelBuilder: (option) => option,
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Beta');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 32);
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsNothing);
    expect(
      tester.getRect(find.text('Beta').last).bottom,
      lessThanOrEqualTo(500),
    );
    expect(
      tester.getRect(find.byType(TextField)).top,
      greaterThanOrEqualTo(32),
    );
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();
    expect(selected, 'Beta');
    expect(tester.takeException(), isNull);
  });
}
