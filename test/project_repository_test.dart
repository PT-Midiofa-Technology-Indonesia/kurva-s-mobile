import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  test(
    'successful history GETs acknowledge only their own history scope',
    () async {
      final client = DioClient(secureStorage: _FakeSecureStorage());
      addTearDown(() => client.dio.close());
      var fail = false;
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        return ResponseBody.fromString(
          '{"success":true,"data":[]}',
          fail ? 500 : 200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final reads = <String>[];
      final repository = ProjectRepository(
        dioClient: client,
        onHistoryRead: reads.add,
      );
      await repository.fetchProjectTasks('p', tab: 'open');
      await repository.fetchQcTasks('p', tab: 'open');
      await repository.fetchTaskChildren(
        projectId: 'p',
        taskId: 'parent',
        tab: 'open',
      );
      expect(reads, isEmpty);
      await repository.fetchProjectTasks('p', tab: 'history');
      await repository.fetchQcTasks('p', tab: 'history');
      await repository.fetchTaskChildren(
        projectId: 'p',
        taskId: 'parent',
        tab: 'history',
      );
      await repository.fetchTaskHistory(projectId: 'p', manpowerTaskId: 'm');
      await repository.fetchQcTaskHistory(projectId: 'p', qcTaskId: 'q');
      expect(reads, [
        'p/tasks',
        'p/qc-tasks',
        'p/tasks/parent/children',
        'p/tasks/m/history',
        'p/qc-tasks/q/history',
      ]);
      reads.clear();
      fail = true;
      await expectLater(
        repository.fetchTaskHistory(projectId: 'p', manpowerTaskId: 'm'),
        throwsA(isA<Exception>()),
      );
      expect(reads, isEmpty);
    },
  );

  for (final hasUnread in [false, true]) {
    test('QC detail history status hasUnread=$hasUnread', () async {
      final client = DioClient(secureStorage: _FakeSecureStorage());
      addTearDown(() => client.dio.close());
      client.dio.options.baseUrl = 'https://api.example.test/api';
      RequestOptions? request;
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        request = options;
        return ResponseBody.fromString(
          '{"success":true,"data":{"hasUnread":$hasUnread,"unreadCount":3}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final result = await ProjectRepository(
        dioClient: client,
      ).fetchQcHistoryHasUnread(projectId: 'project-1', qcTaskId: 'qc-1');
      expect(result, hasUnread);
      expect(request?.method, 'GET');
      expect(
        request?.uri.path,
        '/api/v1/mobile/projects/project-1/qc-tasks/qc-1/history/history-status',
      );
    });
  }

  for (final hasUnread in [false, true]) {
    test('manpower history status hasUnread=$hasUnread', () async {
      final client = DioClient(secureStorage: _FakeSecureStorage());
      addTearDown(() => client.dio.close());
      client.dio.options.baseUrl = 'https://api.example.test/api';
      RequestOptions? request;
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        request = options;
        return ResponseBody.fromString(
          '{"success":true,"data":{"hasUnread":$hasUnread,"unreadCount":3}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final result = await ProjectRepository(dioClient: client)
          .fetchManpowerHistoryHasUnread(
            projectId: 'project-1',
            manpowerTaskId: 'manpower-1',
          );
      expect(result, hasUnread);
      expect(request?.method, 'GET');
      expect(
        request?.uri.path,
        '/api/v1/mobile/projects/project-1/tasks/manpower-1/history/history-status',
      );
    });
  }

  for (final hasUnread in [false, true]) {
    test('children history status hasUnread=$hasUnread', () async {
      final client = DioClient(secureStorage: _FakeSecureStorage());
      addTearDown(() => client.dio.close());
      client.dio.options.baseUrl = 'https://api.example.test/api';
      RequestOptions? request;
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        request = options;
        return ResponseBody.fromString(
          '{"success":true,"data":{"hasUnread":$hasUnread,"unreadCount":3}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final result = await ProjectRepository(dioClient: client)
          .fetchTaskChildrenHistoryHasUnread(
            projectId: 'project-1',
            parentTaskId: 'parent-1',
          );
      expect(result, hasUnread);
      expect(request?.method, 'GET');
      expect(
        request?.uri.path,
        '/api/v1/mobile/projects/project-1/tasks/parent-1/children/history-status',
      );
    });
  }

  for (final isQc in [false, true]) {
    for (final hasUnread in [false, true]) {
      test('history status isQc=$isQc hasUnread=$hasUnread', () async {
        final client = DioClient(secureStorage: _FakeSecureStorage());
        addTearDown(() => client.dio.close());
        client.dio.options.baseUrl = 'https://api.example.test/api';
        RequestOptions? request;
        client.dio.httpClientAdapter = _CallbackAdapter((options) async {
          request = options;
          return ResponseBody.fromString(
            '{"success":true,"data":{"hasUnread":$hasUnread,"unreadCount":3}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
        final result = await ProjectRepository(
          dioClient: client,
        ).fetchHistoryHasUnread('project-1', isQc: isQc);
        expect(result, hasUnread);
        expect(request?.method, 'GET');
        expect(
          request?.uri.path,
          '/api/v1/mobile/projects/project-1/${isQc ? 'qc-tasks' : 'tasks'}/history-status',
        );
      });
    }
  }

  test('fetchProjectHelpers memetakan helper dari endpoint project', () async {
    RequestOptions? request;
    final client = DioClient(secureStorage: _FakeSecureStorage());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      request = options;
      return ResponseBody.fromString(
        '''
        {
          "success": true,
          "message": "Data berhasil diambil.",
          "data": [
            {"id": "uuid-helper-1", "code": "EMP010", "name": "Sukriadi"}
          ]
        }
        ''',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final helpers = await ProjectRepository(
      dioClient: client,
    ).fetchProjectHelpers('project-1');

    expect(request?.method, 'GET');
    expect(request?.path, '/v1/mobile/projects/project-1/helpers');
    expect(helpers, hasLength(1));
    expect(helpers.single.id, 'uuid-helper-1');
    expect(helpers.single.code, 'EMP010');
    expect(helpers.single.name, 'Sukriadi');
  });

  test('fetchTaskHistory memetakan riwayat dan dokumen task', () async {
    RequestOptions? request;
    final client = DioClient(secureStorage: _FakeSecureStorage());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      request = options;
      return ResponseBody.fromString(
        '''
        {
          "success": true,
          "message": "Data berhasil diambil.",
          "data": [
            {
              "projectTaskId": "work-task-1",
              "actor": {"id": "employee-1", "name": "Budi Santoso"},
              "note": "Sudah dikerjakan",
              "completedVolume": 2,
              "targetVolume": 10,
              "uom": "M2",
              "documents": [
                {
                  "id": "document-1",
                  "documentType": {
                    "id": "type-1",
                    "code": "TASK_EVIDENCE",
                    "name": "Bukti Pekerjaan"
                  },
                  "fileName": "bukti.jpg",
                  "filePath": "tasks/bukti.jpg",
                  "url": "https://storage.example.com/bukti.jpg",
                  "fileSize": 2048000,
                  "mimeType": "image/jpeg",
                  "uploadedAt": "2026-09-22T09:00:00+07:00"
                }
              ],
              "recordedAt": "2026-09-22T09:30:00+07:00",
              "event": "submitted_to_qc",
              "eventLabel": "Tugas diajukan ke QC"
            }
          ]
        }
        ''',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final history = await ProjectRepository(dioClient: client).fetchTaskHistory(
      projectId: 'project-1',
      manpowerTaskId: 'manpower-task-1',
    );

    expect(request?.method, 'GET');
    expect(
      request?.path,
      '/v1/mobile/projects/project-1/tasks/manpower-task-1/history',
    );
    expect(history, hasLength(1));
    expect(history.single.projectTaskId, 'work-task-1');
    expect(history.single.actor.name, 'Budi Santoso');
    expect(history.single.completedVolume, 2);
    expect(history.single.targetVolume, 10);
    expect(history.single.uom, 'M2');
    expect(history.single.event, 'submitted_to_qc');
    expect(history.single.eventLabel, 'Tugas diajukan ke QC');
    expect(history.single.documents.single.fileName, 'bukti.jpg');
    expect(history.single.documents.single.fileSize, 2048000);
    expect(history.single.documents.single.documentType.code, 'TASK_EVIDENCE');
  });

  test('fetchQcTaskHistory memetakan riwayat keputusan QC', () async {
    RequestOptions? request;
    final client = DioClient(secureStorage: _FakeSecureStorage());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      request = options;
      return ResponseBody.fromString(
        '''
        {
          "success": true,
          "message": "Data berhasil diambil.",
          "data": [
            {
              "projectTaskId": "uuid-qc-task",
              "actor": {"id": "uuid-qc", "name": "QC Inspector"},
              "event": "qc_decision",
              "eventLabel": "QC menolak tugas",
              "decision": {"value": "rejected", "label": "Ditolak"},
              "note": "Pekerjaan belum rata",
              "documents": [
                {
                  "id": "uuid-doc",
                  "documentType": {
                    "id": "uuid-dt",
                    "code": "QC_EVIDENCE",
                    "name": "Bukti QC"
                  },
                  "fileName": "retak_permukaan.jpg",
                  "url": "https://storage.example.com/retak_permukaan.jpg",
                  "fileSize": 1024000,
                  "mimeType": "image/jpeg",
                  "uploadedAt": "2026-09-23T11:00:00+07:00"
                }
              ],
              "recordedAt": "2026-09-23T11:00:00+07:00"
            }
          ]
        }
        ''',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final history = await ProjectRepository(
      dioClient: client,
    ).fetchQcTaskHistory(projectId: 'project-1', qcTaskId: 'qc-task-1');

    expect(request?.method, 'GET');
    expect(
      request?.path,
      '/v1/mobile/projects/project-1/qc-tasks/qc-task-1/history',
    );
    expect(history, hasLength(1));
    expect(history.single.projectTaskId, 'uuid-qc-task');
    expect(history.single.actor.name, 'QC Inspector');
    expect(history.single.event, 'qc_decision');
    expect(history.single.eventLabel, 'QC menolak tugas');
    expect(history.single.decision?.value, 'rejected');
    expect(history.single.decision?.label, 'Ditolak');
    expect(history.single.documents.single.fileName, 'retak_permukaan.jpg');
    expect(history.single.documents.single.documentType.code, 'QC_EVIDENCE');
  });

  test('submitTaskManpower mengirim payload sesuai kontrak API', () async {
    RequestOptions? request;
    final client = DioClient(secureStorage: _FakeSecureStorage());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      request = options;
      return ResponseBody.fromString(
        '{"success":true,"message":"Manpower berhasil ditambahkan."}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final message = await ProjectRepository(dioClient: client)
        .submitTaskManpower(
          projectId: 'project-1',
          taskId: 'task-1',
          employeeId: 'employee-1',
          target: 5,
          helperEmployeeIds: const ['helper-1', 'helper-2'],
          note: 'Area timur',
        );

    expect(request?.method, 'POST');
    expect(
      request?.path,
      '/v1/mobile/projects/project-1/tasks/task-1/manpower',
    );
    expect(request?.data, {
      'employeeId': 'employee-1',
      'target': 5.0,
      'helperEmployeeIds': ['helper-1', 'helper-2'],
      'note': 'Area timur',
    });
    expect(message, 'Manpower berhasil ditambahkan.');
  });

  test('updateTaskManpower mengirim PUT dengan payload manpower', () async {
    RequestOptions? request;
    final client = DioClient(secureStorage: _FakeSecureStorage());
    addTearDown(() => client.dio.close());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      request = options;
      return ResponseBody.fromString(
        '{"success":true,"message":"Manpower diperbarui."}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final message = await ProjectRepository(dioClient: client)
        .updateTaskManpower(
          projectId: 'project-1',
          taskId: 'task-1',
          manpowerTaskId: 'manpower-1',
          employeeId: 'employee-1',
          target: 7.5,
          helperEmployeeIds: ['helper-1'],
          note: 'Catatan baru',
        );
    expect(request?.method, 'PUT');
    expect(
      request?.path,
      '/v1/mobile/projects/project-1/tasks/task-1/manpower/manpower-1',
    );
    expect(request?.data, {
      'employeeId': 'employee-1',
      'target': 7.5,
      'helperEmployeeIds': ['helper-1'],
      'note': 'Catatan baru',
    });
    expect(message, 'Manpower diperbarui.');
  });

  test('deleteTaskManpower memanggil endpoint manpower yang tepat', () async {
    RequestOptions? request;
    final client = DioClient(secureStorage: _FakeSecureStorage());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      request = options;
      return ResponseBody.fromString(
        '{"success":true,"message":"Manpower berhasil dihapus."}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final message = await ProjectRepository(dioClient: client)
        .deleteTaskManpower(
          projectId: 'project-1',
          taskId: 'task-1',
          manpowerTaskId: 'manpower-1',
        );

    expect(request?.method, 'DELETE');
    expect(
      request?.path,
      '/v1/mobile/projects/project-1/tasks/task-1/manpower/manpower-1',
    );
    expect(message, 'Manpower berhasil dihapus.');
  });

  test('delegateFinalTask memanggil endpoint tanpa request body', () async {
    RequestOptions? request;
    final client = DioClient(secureStorage: _FakeSecureStorage());
    client.dio.httpClientAdapter = _CallbackAdapter((options) async {
      request = options;
      return ResponseBody.fromString(
        '{"success":true,"message":"Manpower berhasil di-assign."}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final message = await ProjectRepository(
      dioClient: client,
    ).delegateFinalTask(projectId: 'project-1', taskId: 'task-1');

    expect(request?.method, 'POST');
    expect(
      request?.path,
      '/v1/mobile/projects/project-1/tasks/task-1/delegate-final',
    );
    expect(request?.data, isNull);
    expect(message, 'Manpower berhasil di-assign.');
  });

  test(
    'bulkAssignQcTasks mengirim task dan assignee sesuai kontrak API',
    () async {
      RequestOptions? request;
      final client = DioClient(secureStorage: _FakeSecureStorage());
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        request = options;
        return ResponseBody.fromString(
          '{"success":true,"message":"QC task berhasil di-assign."}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final message = await ProjectRepository(dioClient: client)
          .bulkAssignQcTasks(
            projectId: 'project-1',
            taskIds: const ['qc-task-1', 'qc-task-2'],
            employeeId: 'employee-1',
          );

      expect(request?.method, 'POST');
      expect(
        request?.path,
        '/v1/mobile/projects/project-1/qc-tasks/bulk-assign',
      );
      expect(request?.data, {
        'taskIds': ['qc-task-1', 'qc-task-2'],
        'employeeId': 'employee-1',
      });
      expect(message, 'QC task berhasil di-assign.');
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
