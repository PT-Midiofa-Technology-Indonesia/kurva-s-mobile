import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/logistic/presentation/loading/loading_detail_page.dart';

void main() {
  testWidgets('loading detail displays the latest report and its files', (
    tester,
  ) async {
    final detail = LogisticLoadingOrderDetail.fromJson({
      'loadingOrderId': 'loading-1',
      'code': 'LO/WAD/2026/0002',
      'sourceType': 'manual',
      'status': 'loaded',
      'statusLabel': 'Loaded',
      'canSubmit': false,
      'canSubmitReport': false,
      'items': const [],
      'reports': [
        {
          'reportId': 'report-1',
          'notes': 'test catatan',
          'submittedAt': '2026-08-27T07:07:53+00:00',
          'submittedBy': 'Denis Choirul Ramadhani',
          'files': [
            {
              'id': 'file-1',
              'fileName': 'IMG_20260821_161011.jpg',
              'url': 'https://example.test/first.jpg',
            },
            {
              'id': 'file-2',
              'fileName': 'scaled_image.jpg',
              'url': 'https://example.test/second.jpg',
            },
          ],
        },
      ],
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loadingDetailProvider(
            detail.loadingOrderId,
          ).overrideWith((ref) => Stream.value(detail)),
        ],
        child: MaterialApp(
          home: LoadingDetailPage(loadingOrderId: detail.loadingOrderId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('test catatan'), findsOneWidget);
    expect(find.text('IMG_20260821_161011.jpg'), findsOneWidget);
    expect(find.text('scaled_image.jpg'), findsOneWidget);
    expect(find.text('Simpan laporan'), findsNothing);
  });
}
