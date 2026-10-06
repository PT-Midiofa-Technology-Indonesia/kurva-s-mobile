import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/meeting/data/meeting_repository.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  test(
    'meeting repository uses OpenAPI paths, query, and company header',
    () async {
      final requests = <RequestOptions>[];
      final client = DioClient(secureStorage: _FakeSecureStorage());
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        requests.add(options);
        final body = options.path.endsWith('assignee-candidates')
            ? '{"data":[{"id":"employee-1","name":"Agung"}]}'
            : options.path.contains('/tasks/') ||
                  options.path.endsWith('/tasks') ||
                  options.path.contains('/qc-tasks/')
            ? '{"data":{"id":"task-1","title":"Task"}}'
            : options.path == '/v1/mobile/meetings'
            ? '{"data":[],"meta":{"currentPage":1,"lastPage":1}}'
            : '{"data":{"id":"meeting-1","title":"Meeting"}}';
        return _jsonResponse(body);
      });
      final repository = MeetingRepository(dioClient: client);

      await repository.fetchMeetings(
        companyId: 'company-1',
        search: 'weekly',
        year: '2026',
        perPage: 10,
        page: 2,
      );
      await repository.fetchMeetingDetail(
        meetingId: 'meeting-1',
        companyId: 'company-1',
      );
      await repository.fetchTasks(
        meetingId: 'meeting-1',
        tab: 'history',
        companyId: 'company-1',
      );
      await repository.fetchTaskDetail(
        meetingId: 'meeting-1',
        taskId: 'task-1',
        companyId: 'company-1',
      );
      await repository.fetchAssigneeCandidates(
        meetingId: 'meeting-1',
        taskId: 'task-1',
        search: 'agung',
        companyId: 'company-1',
      );
      await repository.assignTask(
        meetingId: 'meeting-1',
        taskId: 'task-1',
        employeeId: 'employee-1',
        companyId: 'company-1',
      );
      await repository.fetchQcTasks(
        meetingId: 'meeting-1',
        tab: 'close',
        companyId: 'company-1',
      );
      await repository.fetchQcTaskDetail(
        meetingId: 'meeting-1',
        qcTaskId: 'qc-1',
        companyId: 'company-1',
      );

      expect(requests[0].path, '/v1/mobile/meetings');
      expect(requests[0].queryParameters, containsPair('search', 'weekly'));
      expect(requests[0].queryParameters, containsPair('year', '2026'));
      expect(requests[0].queryParameters, containsPair('perPage', 10));
      expect(requests[0].queryParameters, containsPair('page', 2));
      expect(
        requests.map((request) => request.headers['X-Company-Id']),
        everyElement('company-1'),
      );
      expect(requests[1].path, '/v1/mobile/meetings/meeting-1');
      expect(requests[2].path, '/v1/mobile/meetings/meeting-1/tasks');
      expect(requests[2].queryParameters['tab'], 'history');
      expect(requests[3].path, '/v1/mobile/meetings/meeting-1/tasks/task-1');
      expect(requests[4].path, endsWith('/assignee-candidates'));
      expect(requests[4].queryParameters['search'], 'agung');
      expect(requests[5].method, 'POST');
      expect(requests[5].data, {'employeeId': 'employee-1'});
      expect(
        requests[5].path,
        '/v1/mobile/meetings/meeting-1/tasks/task-1/assign',
      );
      expect(requests[6].path, '/v1/mobile/meetings/meeting-1/qc-tasks');
      expect(requests[6].queryParameters['tab'], 'close');
      expect(requests[7].path, '/v1/mobile/meetings/meeting-1/qc-tasks/qc-1');
    },
  );

  test(
    'meeting task and QC writes build the expected multipart payload',
    () async {
      final requests = <RequestOptions>[];
      final client = DioClient(secureStorage: _FakeSecureStorage());
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        requests.add(options);
        return _jsonResponse('{"message":"OK","data":{}}');
      });
      final repository = MeetingRepository(dioClient: client);
      final temporary = File(
        '${Directory.systemTemp.path}/meeting_repository_test.jpg',
      );
      await temporary.writeAsBytes([1, 2, 3]);
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete();
      });
      final files = [
        MeetingFileUpload(name: 'proof.jpg', path: temporary.path),
      ];

      await repository.submitTaskDone(
        meetingId: 'meeting-1',
        taskId: 'task-1',
        note: 'done',
        files: files,
        companyId: 'company-1',
      );
      await repository.submitQcDecision(
        meetingId: 'meeting-1',
        qcTaskId: 'qc-1',
        decision: 'pass',
        note: 'approved',
        files: files,
        companyId: 'company-1',
      );

      expect(
        requests[0].path,
        '/v1/mobile/meetings/meeting-1/tasks/task-1/done',
      );
      final doneForm = requests[0].data as FormData;
      expect(
        doneForm.fields,
        contains(
          isA<MapEntry<String, String>>()
              .having((entry) => entry.key, 'key', 'note')
              .having((entry) => entry.value, 'value', 'done'),
        ),
      );
      expect(doneForm.files.single.key, 'files[]');

      expect(
        requests[1].path,
        '/v1/mobile/meetings/meeting-1/qc-tasks/qc-1/decision',
      );
      final qcForm = requests[1].data as FormData;
      expect(
        qcForm.fields,
        contains(
          isA<MapEntry<String, String>>()
              .having((entry) => entry.key, 'key', 'decision')
              .having((entry) => entry.value, 'value', 'pass'),
        ),
      );
      expect(
        qcForm.fields,
        contains(
          isA<MapEntry<String, String>>()
              .having((entry) => entry.key, 'key', 'note')
              .having((entry) => entry.value, 'value', 'approved'),
        ),
      );
      expect(qcForm.files.single.key, 'files[]');
    },
  );
}

ResponseBody _jsonResponse(String body) {
  return ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this.callback);

  final Future<ResponseBody> Function(RequestOptions options) callback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return callback(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'access-token';
}
