import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/server_refresh_delay.dart';
import '../../../core/offline_first_providers.dart';
import '../../../core/sync/sync_models.dart';
import '../data/models/logistic_models.dart';
import '../data/models/logistic_operation_payload.dart';
import '../data/logistic_repository.dart';
import '../logistic_providers.dart';
import '../../../shared/widgets/upload_image_list.dart';
import 'inbound/inbound_detail_page.dart';

final inboundActionControllerProvider = ChangeNotifierProvider.autoDispose
    .family<InboundActionController, String>((ref, deliveryOrderId) {
      return InboundActionController(ref, deliveryOrderId);
    });

final outboundActionControllerProvider = ChangeNotifierProvider.autoDispose
    .family<OutboundActionController, String>((ref, deliveryOrderId) {
      return OutboundActionController(ref, deliveryOrderId);
    });

final loadingReportControllerProvider = ChangeNotifierProvider.autoDispose
    .family<LoadingReportController, String>((ref, loadingOrderId) {
      return LoadingReportController(ref, loadingOrderId);
    });

final pickupReportControllerProvider = ChangeNotifierProvider.autoDispose
    .family<PickupReportController, String>((ref, pickupOrderId) {
      return PickupReportController(ref, pickupOrderId);
    });

abstract class _LogisticActionController extends ChangeNotifier {
  _LogisticActionController(this.ref, this.deliveryOrderId);

  final Ref ref;
  final String deliveryOrderId;
  bool isSubmitting = false;

  Future<T?> run<T>(Future<T> Function() action) async {
    if (isSubmitting) return null;
    isSubmitting = true;
    notifyListeners();
    final keepAlive = ref.keepAlive();
    try {
      return await action();
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }
}

class InboundActionController extends _LogisticActionController {
  InboundActionController(super.ref, super.deliveryOrderId);
  final receiptEntries = <GoodReceiptEntry>[];
  final attachments = <UploadImageItem>[];
  bool _initialized = false;
  String? _clientEventId;

  void initialize(InboundDetailData detail) {
    if (_initialized) return;
    receiptEntries.addAll(
      detail.items
          .where((item) => item.deliveryOrderItemId.isNotEmpty)
          .map((item) => GoodReceiptEntry(item: item, quantity: item.quantity)),
    );
    if (receiptEntries.isEmpty) receiptEntries.add(GoodReceiptEntry());
    attachments.addAll(
      detail.evidences.map(
        (evidence) => UploadImageItem(
          name: evidence.fileName,
          path: evidence.url,
          size: 0,
        ),
      ),
    );
    _initialized = true;
  }

  void addReceiptEntry() {
    receiptEntries.add(GoodReceiptEntry());
    notifyListeners();
  }

  void removeReceiptEntry(int index) {
    if (receiptEntries.length == 1) {
      receiptEntries[index].item = null;
      receiptEntries[index].quantityController.clear();
    } else {
      receiptEntries.removeAt(index).dispose();
    }
    notifyListeners();
  }

  void selectReceiptItem(int index, InboundItemData item) {
    receiptEntries[index]
      ..item = item
      ..quantityController.text = item.quantity;
    notifyListeners();
  }

  void addAttachments(Iterable<UploadImageItem> files) {
    attachments.addAll(files);
    notifyListeners();
  }

  void removeAttachment(int index) {
    attachments.removeAt(index);
    notifyListeners();
  }

  Future<LogisticEnqueueResult?> submit({
    required List<LogisticReceiveItemInput> items,
    required int expectedVersion,
    required String notes,
    required List<String> photoPaths,
  }) {
    return run(() async {
      if (!ref
          .read(syncPolicyProvider)
          .canQueue(SyncOperationType.logisticInboundReceive)) {
        final message = await ref
            .read(logisticRepositoryProvider)
            .submitGoodsReceipt(
              deliveryOrderId: deliveryOrderId,
              items: items,
              notes: notes,
              photoPaths: photoPaths,
              clientEventId: _clientEventId ??= const Uuid().v4(),
            );
        _clientEventId = null;
        await waitForServerRefresh();
        ref
          ..invalidate(inboundDetailProvider(deliveryOrderId))
          ..invalidate(
            inboundOrdersProvider(const LogisticListQuery(tab: 'open')),
          )
          ..invalidate(
            inboundOrdersProvider(const LogisticListQuery(tab: 'close')),
          );
        return LogisticServerCompleted(message);
      }
      return ref
          .read(logisticRepositoryProvider)
          .enqueueGoodsReceipt(
            LogisticReceiveCommand(
              deliveryOrderId: deliveryOrderId,
              expectedVersion: expectedVersion,
              items: items,
              notes: notes,
              photoPaths: photoPaths,
            ),
          );
    });
  }

  @override
  void dispose() {
    for (final entry in receiptEntries) {
      entry.dispose();
    }
    super.dispose();
  }
}

class OutboundActionController extends _LogisticActionController {
  OutboundActionController(super.ref, super.deliveryOrderId);
  final attachments = <UploadImageItem>[];
  bool _initialized = false;
  String? _clientEventId;

  void initialize(LogisticDeliveryOrderDetail detail) {
    if (_initialized) return;
    attachments.addAll(
      detail.evidences.map(
        (evidence) => UploadImageItem(
          name: evidence.fileName,
          path: evidence.url,
          size: 0,
        ),
      ),
    );
    _initialized = true;
  }

  void addAttachments(Iterable<UploadImageItem> files) {
    attachments.addAll(files);
    notifyListeners();
  }

  void removeAttachment(int index) {
    attachments.removeAt(index);
    notifyListeners();
  }

  Future<LogisticEnqueueResult?> submit({
    required int expectedVersion,
    required String notes,
    required List<String> photoPaths,
  }) {
    return run(() async {
      if (!ref
          .read(syncPolicyProvider)
          .canQueue(SyncOperationType.logisticOutboundIssue)) {
        final message = await ref
            .read(logisticRepositoryProvider)
            .submitGoodsIssue(
              deliveryOrderId: deliveryOrderId,
              notes: notes,
              photoPaths: photoPaths,
              clientEventId: _clientEventId ??= const Uuid().v4(),
            );
        _clientEventId = null;
        await waitForServerRefresh();
        ref
          ..invalidate(outboundDetailProvider(deliveryOrderId))
          ..invalidate(
            outboundOrdersProvider(const LogisticListQuery(tab: 'open')),
          )
          ..invalidate(
            outboundOrdersProvider(const LogisticListQuery(tab: 'close')),
          );
        return LogisticServerCompleted(message);
      }
      return ref
          .read(logisticRepositoryProvider)
          .enqueueGoodsIssue(
            LogisticIssueCommand(
              deliveryOrderId: deliveryOrderId,
              expectedVersion: expectedVersion,
              notes: notes,
              photoPaths: photoPaths,
            ),
          );
    });
  }
}

class LoadingReportController extends _LogisticActionController {
  LoadingReportController(super.ref, super.deliveryOrderId);

  final attachments = <UploadImageItem>[];
  bool _initialized = false;

  void initialize(LogisticLoadingOrderDetail detail) {
    if (_initialized) return;
    attachments.addAll(
      detail.latestReport?.files.map(
            (file) =>
                UploadImageItem(name: file.fileName, path: file.url, size: 0),
          ) ??
          const [],
    );
    _initialized = true;
  }

  void addAttachments(Iterable<UploadImageItem> files) {
    attachments.addAll(files);
    notifyListeners();
  }

  void removeAttachment(int index) {
    attachments.removeAt(index);
    notifyListeners();
  }

  Future<LogisticEnqueueResult?> submit({
    required String notes,
    required List<String> photoPaths,
  }) {
    return run(() async {
      if (ref
          .read(syncPolicyProvider)
          .canQueue(SyncOperationType.logisticLoadingReport)) {
        return ref
            .read(logisticRepositoryProvider)
            .enqueueLoadingReport(
              LogisticReportCommand(
                resourceId: deliveryOrderId,
                notes: notes,
                photoPaths: photoPaths,
              ),
            );
      }
      final message = await ref
          .read(logisticRepositoryProvider)
          .submitLoadingReport(
            loadingOrderId: deliveryOrderId,
            notes: notes,
            photoPaths: photoPaths,
          );
      await waitForServerRefresh();
      ref
        ..invalidate(loadingDetailProvider(deliveryOrderId))
        ..invalidate(
          loadingOrdersProvider(const LogisticListQuery(tab: 'open')),
        )
        ..invalidate(
          loadingOrdersProvider(const LogisticListQuery(tab: 'close')),
        );
      return LogisticServerCompleted(message);
    });
  }
}

class PickupReportController extends _LogisticActionController {
  PickupReportController(super.ref, super.deliveryOrderId);

  final attachments = <UploadImageItem>[];
  bool _initialized = false;

  void initialize(LogisticPickupOrderDetail detail) {
    if (_initialized) return;
    attachments.addAll(
      detail.report?.photos.map(
            (photo) => UploadImageItem(
              name: photo.name,
              path: photo.url,
              size: photo.size,
            ),
          ) ??
          const [],
    );
    _initialized = true;
  }

  void addAttachments(Iterable<UploadImageItem> files) {
    attachments.addAll(files);
    notifyListeners();
  }

  void removeAttachment(int index) {
    attachments.removeAt(index);
    notifyListeners();
  }

  Future<LogisticEnqueueResult?> submit({
    required String notes,
    required List<String> photoPaths,
  }) {
    return run(() async {
      if (ref
          .read(syncPolicyProvider)
          .canQueue(SyncOperationType.logisticPickupReport)) {
        return ref
            .read(logisticRepositoryProvider)
            .enqueuePickupReport(
              LogisticReportCommand(
                resourceId: deliveryOrderId,
                notes: notes,
                photoPaths: photoPaths,
              ),
            );
      }
      final message = await ref
          .read(logisticRepositoryProvider)
          .submitPickupReport(
            pickupOrderId: deliveryOrderId,
            notes: notes,
            photoPaths: photoPaths,
          );
      await waitForServerRefresh();
      ref
        ..invalidate(pickupDetailProvider(deliveryOrderId))
        ..invalidate(pickupOrdersProvider(const LogisticListQuery(tab: 'open')))
        ..invalidate(
          pickupOrdersProvider(const LogisticListQuery(tab: 'close')),
        );
      return LogisticServerCompleted(message);
    });
  }
}

class GoodReceiptEntry {
  GoodReceiptEntry({this.item, String quantity = ''})
    : quantityController = TextEditingController(text: quantity);
  InboundItemData? item;
  final TextEditingController quantityController;
  void dispose() => quantityController.dispose();
}
