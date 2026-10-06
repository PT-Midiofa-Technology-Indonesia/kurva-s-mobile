import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/logistic/presentation/pickup/pickup_detail_page.dart';

void main() {
  test('pickup detail maps the current response contract', () {
    final detail = LogisticPickupOrderDetail.fromJson({
      'pickupOrderId': '019f881a-2f49-7362-9243-c767146d051d',
      'code': 'PKO/PU/2026/0002',
      'type': 'pickup',
      'status': 'assigned',
      'statusLabel': 'Assigned',
      'warehouseName': 'Gudang Mobile Site B',
      'scheduledDate': '2026-07-23',
      'pic': {
        'id': '019f32b5-1cd4-7209-85b1-5db4419b773f',
        'name': 'Mobile Admin',
      },
      'pickupLocation': 'Ke sono jauh',
      'canSubmit': true,
      'canSubmitReport': true,
      'items': [
        {
          'pickupOrderItemId': 'item-1',
          'itemType': 'material',
          'name': 'Besi Beton 12mm',
          'code': 'LOG-ITEM-BESI',
          'uom': 'L011',
          'quantity': 20,
        },
      ],
      'report': null,
      'reports': const [],
    });

    expect(detail.pickupOrderId, '019f881a-2f49-7362-9243-c767146d051d');
    expect(detail.status, 'assigned');
    expect(detail.statusLabel, 'Assigned');
    expect(detail.canSubmit, isTrue);
    expect(detail.canSubmitReport, isTrue);
    expect(detail.pic?.name, 'Mobile Admin');
    expect(detail.items.single.quantity, 20);
    expect(detail.report, isNull);
  });

  testWidgets('pickup detail displays files from the latest report', (
    tester,
  ) async {
    final detail = LogisticPickupOrderDetail.fromJson({
      'pickupOrderId': 'pickup-1',
      'code': 'PKO-001',
      'type': 'pickup',
      'status': 'completed',
      'canSubmit': false,
      'canSubmitReport': false,
      'items': const [],
      'reports': [
        {
          'reportId': 'report-1',
          'notes': 'Pickup selesai',
          'submittedAt': '2026-08-27T07:49:15+00:00',
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

    expect(detail.report?.notes, 'Pickup selesai');
    expect(detail.report?.photos, hasLength(2));
    expect(detail.report?.photos.first.name, 'IMG_20260821_161011.jpg');
    expect(detail.report?.photos.first.url, 'https://example.test/first.jpg');

    await _pumpDetail(tester, detail);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Pickup selesai'), findsOneWidget);
    expect(find.text('IMG_20260821_161011.jpg'), findsOneWidget);
    expect(find.text('scaled_image.jpg'), findsOneWidget);
    expect(find.text('Simpan laporan'), findsNothing);
  });

  testWidgets('pickup with canSubmit exposes the report submit action', (
    tester,
  ) async {
    await _pumpDetail(tester, _detail(status: 'cancelled', canSubmit: true));

    expect(find.text('Simpan laporan'), findsOneWidget);
  });

  testWidgets('pickup without canSubmit is readonly', (tester) async {
    await _pumpDetail(tester, _detail(status: 'assigned', canSubmit: false));

    expect(find.text('Simpan laporan'), findsNothing);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  LogisticPickupOrderDetail detail,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pickupDetailProvider(
          detail.pickupOrderId,
        ).overrideWith((ref) => Stream.value(detail)),
      ],
      child: MaterialApp(
        home: PickupDetailPage(pickupOrderId: detail.pickupOrderId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LogisticPickupOrderDetail _detail({
  required String status,
  required bool canSubmit,
}) {
  return LogisticPickupOrderDetail(
    pickupOrderId: 'pickup-1',
    code: 'PKO-001',
    type: 'pickup',
    status: status,
    canSubmit: canSubmit,
    canSubmitReport: false,
    items: const [],
  );
}
