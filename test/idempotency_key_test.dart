import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/error_mapper.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/core/errors/sync_failure.dart';
import 'package:curva_mobile/modules/logistic/data/logistic_repository.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  test(
    'four idempotent writes send their supplied client event ID in the body',
    () async {
      final requests = <RequestOptions>[];
      final client = DioClient(secureStorage: _FakeSecureStorage());
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        requests.add(options);
        return _jsonResponse('{"message":"OK","data":{}}');
      });
      final project = ProjectRepository(dioClient: client);
      final logistic = LogisticRepository(dioClient: client);

      await project.submitTaskDone(
        projectId: 'project-1',
        taskId: 'task-1',
        clientEventId: 'event-task',
      );
      await project.submitQcDecision(
        projectId: 'project-1',
        qcTaskId: 'qc-1',
        decision: 'pass',
        clientEventId: 'event-qc',
      );
      await logistic.submitGoodsReceipt(
        deliveryOrderId: 'do-1',
        clientEventId: 'event-receive',
        items: const [
          LogisticReceiveItemInput(
            deliveryOrderItemId: 'item-1',
            quantityReceived: 1,
          ),
        ],
      );
      await logistic.submitGoodsIssue(
        deliveryOrderId: 'do-1',
        clientEventId: 'event-issue',
      );

      expect(
        _field(requests[0].data as FormData, 'clientEventId'),
        'event-task',
      );
      expect(_field(requests[1].data as FormData, 'clientEventId'), 'event-qc');
      expect(
        _field(requests[2].data as FormData, 'clientEventId'),
        'event-receive',
      );
      expect(
        _field(requests[3].data as FormData, 'clientEventId'),
        'event-issue',
      );
    },
  );

  test('manpower daily report uses manpower task endpoint', () async {
    final requests = <RequestOptions>[];
    final client = DioClient(secureStorage: _FakeSecureStorage());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      requests.add(options);
      return _jsonResponse('{"message":"OK","data":{}}');
    });
    final project = ProjectRepository(dioClient: client);

    await project.submitManpowerDailyReport(
      projectId: 'project-1',
      manpowerTaskId: 'manpower-task-1',
      completedVolume: 2.5,
      note: 'Pekerjaan selesai',
      files: const [],
      clientEventId: 'event-manpower-report',
    );

    expect(requests, hasLength(1));
    expect(
      requests.single.path,
      '/v1/mobile/projects/project-1/tasks/manpower-task-1/done',
    );
    final formData = requests.single.data as FormData;
    expect(_field(formData, 'completedVolume'), '2.5');
    expect(_field(formData, 'note'), 'Pekerjaan selesai');
    expect(_field(formData, 'clientEventId'), 'event-manpower-report');
  });

  test('idempotency in progress is retryable', () {
    final failure = ErrorMapper.toSyncFailure(
      DioException(
        requestOptions: RequestOptions(path: '/idempotent-write'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/idempotent-write'),
          statusCode: 409,
          data: const {
            'message': 'Request is still processing.',
            'errorCode': 'IDEMPOTENCY_IN_PROGRESS',
          },
        ),
      ),
    );

    expect(failure.kind, SyncFailureKind.retryable);
  });
}

String? _field(FormData data, String name) {
  for (final field in data.fields) {
    if (field.key == name) return field.value;
  }
  return null;
}

ResponseBody _jsonResponse(String body) => ResponseBody.fromString(
  body,
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this.callback);

  final Future<ResponseBody> Function(RequestOptions options) callback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => callback(options);

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'access-token';
}
