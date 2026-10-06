import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/outbox_service.dart';
import '../../../core/sync/sync_models.dart';
import 'local/logistic_local_data_source.dart';
import 'models/logistic_models.dart';
import 'models/logistic_operation_payload.dart';

class LogisticRepository {
  const LogisticRepository({
    required DioClient dioClient,
    LogisticLocalDataSource? localDataSource,
    OutboxService? outboxService,
    SyncScope? scope,
  }) : _dioClient = dioClient,
       _localDataSource = localDataSource,
       _outboxService = outboxService,
       _scope = scope;

  final DioClient _dioClient;
  final LogisticLocalDataSource? _localDataSource;
  final OutboxService? _outboxService;
  final SyncScope? _scope;

  Future<List<LogisticLoadingOrder>> fetchLoadingOrders({
    required String tab,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/logistic/loading-orders',
        queryParameters: {'tab': tab},
      );

      final orders = LogisticLoadingOrder.listFromPayload(
        _responseData(response)['data'],
      );
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putLoadingOrders(
          scope: scope,
          tab: tab,
          orders: orders,
        );
      }
      return orders;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<LogisticPickupOrder>> fetchPickupOrders({
    required String tab,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/logistic/pickup-orders',
        queryParameters: {'tab': tab},
      );

      final orders = LogisticPickupOrder.listFromPayload(
        _responseData(response)['data'],
      );
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putPickupOrders(
          scope: scope,
          tab: tab,
          orders: orders,
        );
      }
      return orders;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<LogisticPickupOrderDetail> fetchPickupDetail(
    String pickupOrderId,
  ) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/logistic/pickup-orders/$pickupOrderId',
      );
      final detail = ApiResponse.fromJson<LogisticPickupOrderDetail>(
        _responseData(response),
        (json) =>
            LogisticPickupOrderDetail.fromJson(json as Map<String, dynamic>),
      ).data;
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putPickupDetail(scope: scope, detail: detail);
      }
      return detail;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitPickupReport({
    required String pickupOrderId,
    String notes = '',
    List<String> photoPaths = const [],
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/logistic/pickup-orders/$pickupOrderId/report',
        data: await _issueFormData(notes: notes, photoPaths: photoPaths),
      );
      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<LogisticLoadingOrderDetail> fetchLoadingDetail(
    String loadingOrderId,
  ) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/logistic/loading-orders/$loadingOrderId',
      );
      final detail = ApiResponse.fromJson<LogisticLoadingOrderDetail>(
        _responseData(response),
        (json) =>
            LogisticLoadingOrderDetail.fromJson(json as Map<String, dynamic>),
      ).data;
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putLoadingDetail(scope: scope, detail: detail);
      }
      return detail;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitLoadingReport({
    required String loadingOrderId,
    String notes = '',
    List<String> photoPaths = const [],
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/logistic/loading-orders/$loadingOrderId/report',
        data: await _issueFormData(notes: notes, photoPaths: photoPaths),
      );
      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<LogisticDeliveryOrder>> fetchInboundOrders({
    required String tab,
    String search = '',
  }) {
    return _fetchOrders(
      path: '/v1/mobile/logistic/inbound',
      inbound: true,
      tab: tab,
      search: search,
    );
  }

  Future<LogisticDeliveryOrderDetail> fetchInboundDetail(
    String deliveryOrderId,
  ) {
    return _fetchDetail(
      '/v1/mobile/logistic/inbound/$deliveryOrderId',
      inbound: true,
    );
  }

  Future<String?> submitGoodsReceipt({
    required String deliveryOrderId,
    required List<LogisticReceiveItemInput> items,
    String notes = '',
    List<String> photoPaths = const [],
    String? clientEventId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/logistic/inbound/$deliveryOrderId/receive',
        data: await _receiveFormData(
          notes: notes,
          items: items,
          photoPaths: photoPaths,
          clientEventId: clientEventId ?? const Uuid().v4(),
        ),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<LogisticDeliveryOrder>> fetchOutboundOrders({
    required String tab,
    String search = '',
  }) {
    return _fetchOrders(
      path: '/v1/mobile/logistic/outbound',
      inbound: false,
      tab: tab,
      search: search,
    );
  }

  Future<LogisticDeliveryOrderDetail> fetchOutboundDetail(
    String deliveryOrderId,
  ) {
    return _fetchDetail(
      '/v1/mobile/logistic/outbound/$deliveryOrderId',
      inbound: false,
    );
  }

  Future<String?> submitGoodsIssue({
    required String deliveryOrderId,
    String notes = '',
    List<String> photoPaths = const [],
    String? clientEventId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/logistic/outbound/$deliveryOrderId/issue',
        data: await _issueFormData(
          notes: notes,
          photoPaths: photoPaths,
          clientEventId: clientEventId ?? const Uuid().v4(),
        ),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<LogisticDeliveryOrder>> _fetchOrders({
    required String path,
    required bool inbound,
    required String tab,
    required String search,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        path,
        queryParameters: _queryParameters({'tab': tab, 'search': search}),
      );

      final orders = LogisticDeliveryOrder.listFromPayload(
        _responseData(response)['data'],
      );
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putOrders(
          scope: scope,
          inbound: inbound,
          tab: tab,
          search: search,
          orders: orders,
        );
      }
      return orders;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<LogisticDeliveryOrderDetail> _fetchDetail(
    String path, {
    required bool inbound,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(path);

      final detail = ApiResponse.fromJson<LogisticDeliveryOrderDetail>(
        _responseData(response),
        (json) =>
            LogisticDeliveryOrderDetail.fromJson(json as Map<String, dynamic>),
      ).data;
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putDetail(
          scope: scope,
          inbound: inbound,
          detail: detail,
        );
      }
      return detail;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<FormData> _receiveFormData({
    required String notes,
    required List<LogisticReceiveItemInput> items,
    required List<String> photoPaths,
    required String clientEventId,
  }) async {
    final formData = FormData.fromMap({
      'notes': notes,
      'clientEventId': clientEventId,
    });
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      formData.fields.addAll([
        MapEntry(
          'items[$index][deliveryOrderItemId]',
          item.deliveryOrderItemId,
        ),
        MapEntry('items[$index][quantityReceived]', '${item.quantityReceived}'),
      ]);
    }
    await _addPhotos(formData, photoPaths);

    return formData;
  }

  Future<FormData> _issueFormData({
    required String notes,
    required List<String> photoPaths,
    String? clientEventId,
  }) async {
    final formData = FormData.fromMap({
      'notes': notes,
      if (clientEventId != null) 'clientEventId': clientEventId,
    });
    await _addPhotos(formData, photoPaths);

    return formData;
  }

  Future<void> _addPhotos(FormData formData, List<String> photoPaths) async {
    for (final path in photoPaths) {
      formData.files.add(
        MapEntry('photos[]', await MultipartFile.fromFile(path)),
      );
    }
  }

  Map<String, Object?> _queryParameters(Map<String, Object?> values) {
    return Map.fromEntries(
      values.entries.where((entry) {
        final value = entry.value;
        if (value == null) return false;
        if (value is String) return value.isNotEmpty;
        return true;
      }),
    );
  }

  String? _responseMessage(Response<Object?> response) {
    return _responseData(response)['message'] as String?;
  }

  Map<String, dynamic> _responseData(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;

    throw const AppException('Format respons server tidak valid.');
  }

  AppException _mapDioException(DioException error) {
    return ErrorMapper.fromDio(error);
  }

  Stream<LogisticCachedReference<List<LogisticDeliveryOrder>>?> watchOrders({
    required bool inbound,
    required String tab,
    String search = '',
  }) => _requireLocal().watchOrders(
    scope: _requireScope(),
    inbound: inbound,
    tab: tab,
    search: search,
  );

  Stream<LogisticCachedReference<LogisticDeliveryOrderDetail>?> watchDetail({
    required bool inbound,
    required String deliveryOrderId,
  }) => _requireLocal().watchDetail(
    scope: _requireScope(),
    inbound: inbound,
    deliveryOrderId: deliveryOrderId,
  );

  Stream<LogisticCachedReference<List<LogisticLoadingOrder>>?>
  watchLoadingOrders({required String tab}) =>
      _requireLocal().watchLoadingOrders(scope: _requireScope(), tab: tab);

  Stream<LogisticCachedReference<LogisticLoadingOrderDetail>?>
  watchLoadingDetail(String loadingOrderId) =>
      _requireLocal().watchLoadingDetail(
        scope: _requireScope(),
        loadingOrderId: loadingOrderId,
      );

  Stream<LogisticCachedReference<List<LogisticPickupOrder>>?>
  watchPickupOrders({required String tab}) =>
      _requireLocal().watchPickupOrders(scope: _requireScope(), tab: tab);

  Stream<LogisticCachedReference<LogisticPickupOrderDetail>?> watchPickupDetail(
    String pickupOrderId,
  ) => _requireLocal().watchPickupDetail(
    scope: _requireScope(),
    pickupOrderId: pickupOrderId,
  );

  Future<LogisticEnqueueResult> enqueueGoodsReceipt(
    LogisticReceiveCommand command,
  ) async {
    final invalid = _validateReceive(command);
    if (invalid != null) return LogisticOperationNotReadyOffline(invalid);
    return _enqueue(
      deliveryOrderId: command.deliveryOrderId,
      operationType: SyncOperationType.logisticInboundReceive,
      endpoint:
          '/v1/mobile/logistic/inbound/${command.deliveryOrderId}/receive',
      payload: LogisticOperationPayloadV1(
        type: SyncOperationType.logisticInboundReceive.storageName,
        deliveryOrderId: command.deliveryOrderId,
        expectedVersion: command.expectedVersion,
        clientOccurredAt: DateTime.now().toUtc(),
        notes: command.notes.trim(),
        items: command.items,
      ).toJson(),
      photoPaths: command.photoPaths,
    );
  }

  Future<LogisticEnqueueResult> enqueueGoodsIssue(
    LogisticIssueCommand command,
  ) {
    if (command.deliveryOrderId.isEmpty) {
      return Future.value(
        const LogisticOperationNotReadyOffline(
          'Detail delivery order belum tersimpan. Muat ulang saat online.',
        ),
      );
    }
    return _enqueue(
      deliveryOrderId: command.deliveryOrderId,
      operationType: SyncOperationType.logisticOutboundIssue,
      endpoint: '/v1/mobile/logistic/outbound/${command.deliveryOrderId}/issue',
      payload: LogisticOperationPayloadV1(
        type: SyncOperationType.logisticOutboundIssue.storageName,
        deliveryOrderId: command.deliveryOrderId,
        expectedVersion: command.expectedVersion,
        clientOccurredAt: DateTime.now().toUtc(),
        notes: command.notes.trim(),
      ).toJson(),
      photoPaths: command.photoPaths,
    );
  }

  Future<LogisticEnqueueResult> enqueueLoadingReport(
    LogisticReportCommand command,
  ) => _enqueueReport(
    command: command,
    operationType: SyncOperationType.logisticLoadingReport,
    resourceType: 'loading',
    endpoint: '/v1/mobile/logistic/loading-orders/${command.resourceId}/report',
  );

  Future<LogisticEnqueueResult> enqueuePickupReport(
    LogisticReportCommand command,
  ) => _enqueueReport(
    command: command,
    operationType: SyncOperationType.logisticPickupReport,
    resourceType: 'pickup',
    endpoint: '/v1/mobile/logistic/pickup-orders/${command.resourceId}/report',
  );

  Future<LogisticEnqueueResult> _enqueueReport({
    required LogisticReportCommand command,
    required SyncOperationType operationType,
    required String resourceType,
    required String endpoint,
  }) {
    if (command.resourceId.isEmpty) {
      return Future.value(
        const LogisticOperationNotReadyOffline('ID order tidak valid.'),
      );
    }
    return _enqueue(
      deliveryOrderId: command.resourceId,
      operationType: operationType,
      endpoint: endpoint,
      targetResourceKey: 'logistic:$resourceType:${command.resourceId}',
      payload: LogisticOperationPayloadV1(
        type: operationType.storageName,
        deliveryOrderId: command.resourceId,
        expectedVersion: 0,
        clientOccurredAt: DateTime.now().toUtc(),
        notes: command.notes.trim(),
      ).toJson(),
      photoPaths: command.photoPaths,
    );
  }

  Future<LogisticEnqueueResult> _enqueue({
    required String deliveryOrderId,
    required SyncOperationType operationType,
    required String endpoint,
    required Map<String, Object?> payload,
    required List<String> photoPaths,
    String? targetResourceKey,
  }) async {
    final scope = _requireScope();
    final outbox = _requireOutbox();
    final target =
        targetResourceKey ?? 'logistic:delivery-order:$deliveryOrderId';
    final existing = await outbox.activeOperationId(
      scope: scope,
      operationType: operationType,
      targetResourceKey: target,
    );
    if (existing != null) return LogisticOperationAlreadyPending(existing);
    try {
      final operationId = await outbox.enqueue(
        EnqueueOperationInput(
          scope: scope,
          operationType: operationType,
          targetResourceKey: target,
          endpoint: endpoint,
          payload: payload,
          attachments: photoPaths
              .map(
                (path) => AttachmentInput(
                  sourcePath: path,
                  fieldName: 'photos[]',
                  mimeType: _imageMimeType(path),
                ),
              )
              .toList(growable: false),
        ),
      );
      return LogisticOperationStored(operationId);
    } catch (error) {
      return LogisticOperationStoreFailed(_safeStoreMessage(error));
    }
  }

  String? _validateReceive(LogisticReceiveCommand command) {
    if (command.deliveryOrderId.isEmpty) {
      return 'Detail delivery order belum tersimpan. Muat ulang saat online.';
    }
    if (command.items.isEmpty) return 'Minimal satu item harus diterima.';
    final ids = <String>{};
    for (final item in command.items) {
      if (item.deliveryOrderItemId.isEmpty || item.quantityReceived <= 0) {
        return 'Item dan quantity penerimaan tidak valid.';
      }
      if (!ids.add(item.deliveryOrderItemId)) {
        return 'Item penerimaan tidak boleh dipilih lebih dari sekali.';
      }
    }
    return null;
  }

  LogisticLocalDataSource _requireLocal() =>
      _localDataSource ?? (throw StateError('Cache logistic belum tersedia.'));
  OutboxService _requireOutbox() =>
      _outboxService ?? (throw StateError('Outbox logistic belum tersedia.'));
  SyncScope _requireScope() =>
      _scope ?? (throw StateError('Session aktif tidak tersedia.'));

  String _safeStoreMessage(Object error) => error is AppException
      ? error.message
      : error.toString().replaceFirst('Bad state: ', '');

  String _imageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

sealed class LogisticEnqueueResult {
  const LogisticEnqueueResult();
}

class LogisticOperationStored extends LogisticEnqueueResult {
  const LogisticOperationStored(this.operationId);
  final String operationId;
}

class LogisticServerCompleted extends LogisticEnqueueResult {
  const LogisticServerCompleted(this.message);
  final String? message;
}

class LogisticOperationAlreadyPending extends LogisticEnqueueResult {
  const LogisticOperationAlreadyPending(this.operationId);
  final String operationId;
}

class LogisticOperationNotReadyOffline extends LogisticEnqueueResult {
  const LogisticOperationNotReadyOffline(this.message);
  final String message;
}

class LogisticOperationStoreFailed extends LogisticEnqueueResult {
  const LogisticOperationStoreFailed(this.message);
  final String message;
}
