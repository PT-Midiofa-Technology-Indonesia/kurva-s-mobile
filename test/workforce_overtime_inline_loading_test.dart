import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/workforce/data/models/location.dart';
import 'package:curva_mobile/modules/workforce/presentation/workforce_overtime_request_page.dart';
import 'package:curva_mobile/modules/workforce/presentation/workforce_request_form_controllers.dart';
import 'package:curva_mobile/modules/workforce/workforce_providers.dart';
import 'package:curva_mobile/shared/widgets/input_picker_field.dart';

void main() {
  testWidgets('loading locations does not block the rest of overtime form', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final locations = Completer<List<WorkforceLocation>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          overtimeRequestFormControllerProvider.overrideWith((ref) {
            return OvertimeRequestFormController(ref);
          }),
          locationListProvider.overrideWith((ref, type) => locations.future),
        ],
        child: const MaterialApp(home: WorkforceOvertimeRequestPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(WorkforceOvertimeRequestPage), findsOneWidget);
    final locationTypePicker = find.byWidgetPredicate(
      (widget) =>
          widget is InputPickerField && widget.label == 'Pilih tipe lokasi',
    );
    final locationPicker = find.byWidgetPredicate(
      (widget) => widget is InputPickerField && widget.label == 'Pilih lokasi',
    );
    await tester.tap(locationTypePicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Office').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(locationPicker, findsOneWidget);
    final modalBarriersBefore = find.byType(ModalBarrier).evaluate().length;

    expect(find.text('Memuat lokasi...'), findsOneWidget);
    expect(find.byType(ModalBarrier).evaluate().length, modalBarriersBefore);

    await tester.tap(find.text('Ajukan lembur'));
    await tester.pump();
    expect(find.text('Tanggal wajib dipilih.'), findsOneWidget);
    expect(find.text('Memuat lokasi...'), findsOneWidget);

    locations.complete(const []);
    await tester.pump();
    await tester.pump();

    expect(find.text('Lokasi tidak tersedia.'), findsOneWidget);
    expect(find.text('Memuat lokasi...'), findsNothing);
  });

  testWidgets('selecting a location type preloads and reuses its locations', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final locations = Completer<List<WorkforceLocation>>();
    var requestCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          overtimeRequestFormControllerProvider.overrideWith(
            OvertimeRequestFormController.new,
          ),
          locationListProvider.overrideWith((ref, type) {
            requestCount += 1;
            return locations.future;
          }),
        ],
        child: const MaterialApp(home: WorkforceOvertimeRequestPage()),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is InputPickerField && widget.label == 'Pilih tipe lokasi',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Office').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(requestCount, 1);
    expect(find.text('Memuat lokasi...'), findsOneWidget);

    locations.complete(const [
      WorkforceLocation(
        id: 'office-1',
        type: 'Office',
        code: 'HQ',
        name: 'Office Utama',
        latitude: '-6.2',
        longitude: '106.8',
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Memuat lokasi...'), findsNothing);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is InputPickerField && widget.label == 'Pilih lokasi',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Office Utama'), findsOneWidget);
    expect(requestCount, 1);
  });
}
