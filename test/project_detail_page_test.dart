import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/project/presentation/pages/project/project_detail_page.dart';

void main() {
  testWidgets('project detail content fits the reference viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 870));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectDetailPage(detail: ProjectDetailData.fallback()),
      ),
    );

    expect(find.text('Proyek'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Klien'), findsOneWidget);
    expect(find.text('Periode'), findsOneWidget);
    expect(find.text('Deskripsi'), findsOneWidget);
    expect(find.text('Hari kerja'), findsOneWidget);
    expect(find.text('Jumlah tugas'), findsOneWidget);
    expect(find.text('203'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
