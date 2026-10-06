import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/logistic/data/local/logistic_local_data_source.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_operation_payload.dart';

void main() {
  const scope = SyncScope(accountId: 'account-1', companyId: 'company-1');

  test('logistic operation types use stable persisted names', () {
    expect(
      SyncOperationType.logisticInboundReceive.storageName,
      'logistic.inbound.receive.v1',
    );
    expect(
      SyncOperationType.logisticOutboundIssue.storageName,
      'logistic.outbound.issue.v1',
    );
    expect(
      SyncOperationType.logisticLoadingReport.storageName,
      'logistic.loading.report.v1',
    );
    expect(
      SyncOperationType.logisticPickupReport.storageName,
      'logistic.pickup.report.v1',
    );
  });

  test('receive payload round-trips UTC time and item quantities', () {
    final payload = LogisticOperationPayloadV1(
      type: SyncOperationType.logisticInboundReceive.storageName,
      deliveryOrderId: 'do-1',
      expectedVersion: 7,
      clientOccurredAt: DateTime.parse('2026-07-22T10:15:00+07:00'),
      notes: 'Kemasan baik',
      items: const [
        LogisticReceiveItemInput(
          deliveryOrderItemId: 'item-1',
          quantityReceived: 8,
        ),
      ],
    );

    final json = payload.toJson();
    final restored = LogisticOperationPayloadV1.fromJson(json);

    expect(json['clientOccurredAt'], '2026-07-22T03:15:00.000Z');
    expect(restored.expectedVersion, 7);
    expect(restored.items.single.quantityReceived, 8);
    expect(restored.clientOccurredAt.isUtc, isTrue);
  });

  test('logistic payload omits unavailable delivery order version', () {
    final payload = LogisticOperationPayloadV1(
      type: SyncOperationType.logisticInboundReceive.storageName,
      deliveryOrderId: 'do-1',
      expectedVersion: 0,
      clientOccurredAt: DateTime.utc(2026, 7, 22),
      items: const [
        LogisticReceiveItemInput(
          deliveryOrderItemId: 'item-1',
          quantityReceived: 8,
        ),
      ],
    );

    expect(payload.toJson(), isNot(contains('expectedVersion')));
  });

  test(
    'logistic list and detail cache survive recreation and are scoped',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = LogisticLocalDataSource(database: database);
      final detail = LogisticDeliveryOrderDetail.fromJson({
        'deliveryOrderId': 'do-1',
        'code': 'DO-001',
        'sourceType': 'purchase_order',
        'status': 'open',
        'submittedNotes': 'Catatan outbound',
        'evidences': [
          {
            'id': 'evidence-1',
            'fileName': 'bukti.jpg',
            'url': 'https://example.com/bukti.jpg',
          },
        ],
        'version': 7,
        'updatedAt': '2026-07-22T03:00:00.000Z',
        'allowedActions': ['receive'],
        'items': [
          {
            'deliveryOrderItemId': 'item-1',
            'name': 'Router',
            'plannedQuantity': 10,
            'receivedQuantity': 2,
            'remainingQuantity': 8,
            'uom': 'pcs',
          },
        ],
      });
      final order = LogisticDeliveryOrder.fromJson(detail.toJson());

      expect(detail.submittedNotes, 'Catatan outbound');
      expect(detail.evidences.single.fileName, 'bukti.jpg');
      expect(detail.toJson()['submittedNotes'], 'Catatan outbound');
      expect(detail.toJson()['evidences'], [
        {
          'id': 'evidence-1',
          'fileName': 'bukti.jpg',
          'url': 'https://example.com/bukti.jpg',
        },
      ]);

      await local.putOrders(
        scope: scope,
        inbound: true,
        tab: 'open',
        search: '',
        orders: [order],
      );
      await local.putDetail(scope: scope, inbound: true, detail: detail);

      final recreated = LogisticLocalDataSource(database: database);
      final cachedList = await recreated
          .watchOrders(scope: scope, inbound: true, tab: 'open')
          .first;
      final cachedDetail = await recreated
          .watchDetail(scope: scope, inbound: true, deliveryOrderId: 'do-1')
          .first;
      final otherScope = await recreated
          .watchDetail(
            scope: const SyncScope(
              accountId: 'account-2',
              companyId: 'company-1',
            ),
            inbound: true,
            deliveryOrderId: 'do-1',
          )
          .first;

      expect(cachedList?.value.single.version, 7);
      expect(cachedDetail?.value.items.single.remainingQuantity, 8);
      expect(cachedDetail?.value.allows('receive'), isTrue);
      expect(otherScope, isNull);
    },
  );

  test('search query has an independent logistic cache key', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = LogisticLocalDataSource(database: database);
    final order = LogisticDeliveryOrder.fromJson({
      'deliveryOrderId': 'do-1',
      'code': 'DO-001',
      'sourceType': 'purchase_order',
      'status': 'open',
    });

    await local.putOrders(
      scope: scope,
      inbound: false,
      tab: 'open',
      search: 'DO-001',
      orders: [order],
    );

    final searched = await local
        .watchOrders(
          scope: scope,
          inbound: false,
          tab: 'open',
          search: 'DO-001',
        )
        .first;
    final unfiltered = await local
        .watchOrders(scope: scope, inbound: false, tab: 'open')
        .first;

    expect(searched?.value.single.deliveryOrderId, 'do-1');
    expect(unfiltered, isNull);
  });

  test('loading and pickup list/detail caches survive recreation', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = LogisticLocalDataSource(database: database);
    final loadingDetail = LogisticLoadingOrderDetail.fromJson({
      'loadingOrderId': 'loading-1',
      'code': 'LOAD-001',
      'sourceType': 'transfer',
      'status': 'prepared',
      'statusLabel': 'Prepared',
      'canSubmit': true,
      'canSubmitReport': true,
      'items': const [],
      'reports': [
        {
          'reportId': 'report-1',
          'notes': 'Loading selesai',
          'submittedAt': '2026-08-27T07:07:53+00:00',
          'submittedBy': 'Operator',
          'files': [
            {
              'id': 'file-1',
              'fileName': 'proof.jpg',
              'url': 'https://example.test/proof.jpg',
            },
          ],
        },
      ],
    });
    final pickupDetail = LogisticPickupOrderDetail.fromJson({
      'pickupOrderId': 'pickup-1',
      'code': 'PICK-001',
      'type': 'pickup',
      'status': 'assigned',
      'statusLabel': 'Assigned pickup',
      'canSubmit': true,
      'canSubmitReport': true,
      'items': const [],
    });

    await local.putLoadingOrders(
      scope: scope,
      tab: 'open',
      orders: [LogisticLoadingOrder.fromJson(loadingDetail.toJson())],
    );
    await local.putLoadingDetail(scope: scope, detail: loadingDetail);
    await local.putPickupOrders(
      scope: scope,
      tab: 'open',
      orders: [LogisticPickupOrder.fromJson(pickupDetail.toJson())],
    );
    await local.putPickupDetail(scope: scope, detail: pickupDetail);

    final recreated = LogisticLocalDataSource(database: database);
    final loadingList = await recreated
        .watchLoadingOrders(scope: scope, tab: 'open')
        .first;
    final cachedLoadingDetail = await recreated
        .watchLoadingDetail(scope: scope, loadingOrderId: 'loading-1')
        .first;
    expect(cachedLoadingDetail?.value.latestReport?.notes, 'Loading selesai');
    expect(
      cachedLoadingDetail?.value.latestReport?.files.single.fileName,
      'proof.jpg',
    );
    final pickupList = await recreated
        .watchPickupOrders(scope: scope, tab: 'open')
        .first;
    final cachedPickupDetail = await recreated
        .watchPickupDetail(scope: scope, pickupOrderId: 'pickup-1')
        .first;

    expect(loadingList?.value.single.loadingOrderId, 'loading-1');
    expect(cachedLoadingDetail?.value.canSubmitReport, isTrue);
    expect(cachedLoadingDetail?.value.canSubmit, isTrue);
    expect(pickupList?.value.single.pickupOrderId, 'pickup-1');
    expect(cachedPickupDetail?.value.statusLabel, 'Assigned pickup');
    expect(cachedPickupDetail?.value.canSubmit, isTrue);
    expect(cachedPickupDetail?.value.canSubmitReport, isTrue);
  });

  test('delivery order retains the API status label', () {
    final order = LogisticDeliveryOrder.fromJson({
      'deliveryOrderId': 'do-1',
      'code': 'DO-001',
      'sourceType': 'transfer_warehouse',
      'status': 'received',
      'statusLabel': 'Received',
    });

    expect(order.statusLabel, 'Received');
    expect(order.toJson()['statusLabel'], 'Received');
  });
}
