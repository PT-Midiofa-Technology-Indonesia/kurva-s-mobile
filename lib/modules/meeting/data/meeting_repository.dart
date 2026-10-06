import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import 'models/meeting_models.dart';

class MeetingRepository {
  const MeetingRepository({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<MeetingListResult> fetchMeetings({
    String? companyId,
    String? search,
    String? year,
    int? perPage,
    int? page,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/meetings',
        queryParameters: _query({
          'search': search,
          'year': year,
          'perPage': perPage,
          'page': page,
        }),
        options: _companyOptions(companyId),
      );
      return MeetingListResult.fromJson(_responseData(response));
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<MeetingDetail> fetchMeetingDetail({
    required String meetingId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/meetings/$meetingId',
        options: _companyOptions(companyId),
      );
      return MeetingDetail.fromJson(_responseObject(response));
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<List<MeetingTask>> fetchTasks({
    required String meetingId,
    String tab = 'open',
    String? companyId,
  }) async {
    final result = await fetchTasksResult(
      meetingId: meetingId,
      tab: tab,
      companyId: companyId,
    );
    return result.tasks;
  }

  Future<MeetingTasksResult> fetchTasksResult({
    required String meetingId,
    String? tab,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/meetings/$meetingId/tasks',
        queryParameters: tab == null ? null : {'tab': tab},
        options: _companyOptions(companyId),
      );
      return MeetingTasksResult.fromJson(_responseData(response));
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<MeetingTask> fetchTaskDetail({
    required String meetingId,
    required String taskId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/meetings/$meetingId/tasks/$taskId',
        options: _companyOptions(companyId),
      );
      final payload = _responsePayload(response);
      if (payload is Map<String, dynamic>) {
        return MeetingTask.fromJson(payload);
      }
      return MeetingTask.fromJson(_responseObject(response));
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<String?> submitTaskDone({
    required String meetingId,
    required String taskId,
    required List<MeetingFileUpload> files,
    String note = '',
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/meetings/$meetingId/tasks/$taskId/done',
        data: await _decisionFormData(note: note, files: files),
        options: _companyOptions(companyId),
      );
      return _message(response);
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<List<MeetingReference>> fetchAssigneeCandidates({
    required String meetingId,
    required String taskId,
    String? search,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/meetings/$meetingId/tasks/$taskId/assignee-candidates',
        queryParameters: _query({'search': search}),
        options: _companyOptions(companyId),
      );
      final items = _responseList(
        response,
        keys: const [
          'candidates',
          'subordinates',
          'employees',
          'items',
          'data',
        ],
      );
      return items
          .whereType<Map<String, dynamic>>()
          .map(MeetingReference.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<String?> assignTask({
    required String meetingId,
    required String taskId,
    required String employeeId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/meetings/$meetingId/tasks/$taskId/assign',
        data: {'employeeId': employeeId},
        options: _companyOptions(companyId),
      );
      return _message(response);
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<List<MeetingTask>> fetchQcTasks({
    required String meetingId,
    String tab = 'open',
    String? companyId,
  }) async {
    final result = await fetchQcTasksResult(
      meetingId: meetingId,
      tab: tab,
      companyId: companyId,
    );
    return result.tasks;
  }

  Future<MeetingTasksResult> fetchQcTasksResult({
    required String meetingId,
    String? tab,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/meetings/$meetingId/qc-tasks',
        queryParameters: tab == null ? null : {'tab': tab},
        options: _companyOptions(companyId),
      );
      return MeetingTasksResult.fromJson(_responseData(response));
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<MeetingTask> fetchQcTaskDetail({
    required String meetingId,
    required String qcTaskId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/meetings/$meetingId/qc-tasks/$qcTaskId',
        options: _companyOptions(companyId),
      );
      return MeetingTask.fromJson(_responseObject(response));
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Future<String?> submitQcDecision({
    required String meetingId,
    required String qcTaskId,
    required String decision,
    required String note,
    required List<MeetingFileUpload> files,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/meetings/$meetingId/qc-tasks/$qcTaskId/decision',
        data: await _decisionFormData(
          decision: decision,
          note: note,
          files: files,
        ),
        options: _companyOptions(companyId),
      );
      return _message(response);
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }

  Map<String, Object?> _query(Map<String, Object?> values) {
    return Map.fromEntries(
      values.entries.where((entry) {
        final value = entry.value;
        return value != null && (value is! String || value.isNotEmpty);
      }),
    );
  }

  Options? _companyOptions(String? companyId) {
    if (companyId == null || companyId.isEmpty) return null;
    return Options(headers: {'X-Company-Id': companyId});
  }

  Map<String, dynamic> _responseData(Response<Object?> response) {
    if (response.data case final Map<String, dynamic> data) return data;
    throw const AppException('Format respons server tidak valid.');
  }

  Object? _responsePayload(Response<Object?> response) {
    final data = _responseData(response);
    return data['data'] ?? data;
  }

  Map<String, dynamic> _responseObject(Response<Object?> response) {
    final payload = _responsePayload(response);
    if (payload is Map<String, dynamic>) return payload;
    throw const AppException('Format respons server tidak valid.');
  }

  List<Object?> _responseList(
    Response<Object?> response, {
    required List<String> keys,
  }) {
    Object? current = _responsePayload(response);
    if (current is List) return current;
    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        final value = current[key];
        if (value is List) return value;
        if (value is Map<String, dynamic>) current = value;
      }
    }
    return const [];
  }

  String? _message(Response<Object?> response) =>
      _responseData(response)['message'] as String?;

  Future<FormData> _decisionFormData({
    String? decision,
    required String note,
    required List<MeetingFileUpload> files,
  }) async {
    final formData = FormData();
    if (decision != null) {
      formData.fields.add(MapEntry('decision', decision));
    }
    formData.fields.add(MapEntry('note', note));
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'files[]',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ),
      );
    }
    return formData;
  }
}

class MeetingFileUpload {
  const MeetingFileUpload({required this.name, required this.path});

  final String name;
  final String path;
}
