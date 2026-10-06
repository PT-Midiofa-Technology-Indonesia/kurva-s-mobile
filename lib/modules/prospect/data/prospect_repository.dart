import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'models/prospect_models.dart';

class ProspectRepository {
  const ProspectRepository({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<List<ProspectStage>> fetchProspects({String? companyId}) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/prospects',
        options: _companyOptions(companyId),
      );
      final data = _responseData(response);

      return ApiResponse.fromJson<List<ProspectStage>>(
        data,
        (json) => _objectList(json, ProspectStage.fromJson),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<ProspectDetail> fetchProspectDetail({
    required String prospectId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/prospects/$prospectId',
        options: _companyOptions(companyId),
      );
      final data = _responseData(response);

      return ApiResponse.fromJson<ProspectDetail>(
        data,
        (json) => ProspectDetail.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProspectProjectType>> fetchProjectTypes() async {
    try {
      final response = await _dioClient.dio.get<Object?>('/v1/project-types');
      final data = _responseData(response);

      return ApiResponse.fromJson<List<ProspectProjectType>>(
        data,
        (json) => _objectList(json, ProspectProjectType.fromJson),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> createProspect({
    required ProspectCreateRequest request,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/prospects',
        data: request.toJson(),
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProspectStageHistory>> fetchStageHistory({
    required String prospectId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/prospects/$prospectId/stage-history',
        options: _companyOptions(companyId),
      );
      final data = _responseData(response);

      return ApiResponse.fromJson<List<ProspectStageHistory>>(data, (json) {
        if (json is Map<String, dynamic>) {
          return _objectList(
            json['stageHistory'] ?? json['histories'] ?? json['items'],
            ProspectStageHistory.fromJson,
          );
        }

        return _objectList(json, ProspectStageHistory.fromJson);
      }).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> updateStage({
    required String prospectId,
    required String stage,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.patch<Object?>(
        '/v1/mobile/prospects/$prospectId/stage',
        data: {'stage': stage},
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> cancelProspect({
    required String prospectId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/prospects/$prospectId/cancel',
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> uploadDocument({
    required String prospectId,
    required String documentTypeId,
    required List<ProspectFileUpload> files,
    String? companyId,
  }) async {
    if (files.isEmpty) {
      return null;
    }

    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/prospects/$prospectId/documents',
        data: await _documentFormData(
          documentTypeId: documentTypeId,
          files: files,
        ),
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> updateDocument({
    required String prospectId,
    required String documentId,
    required List<ProspectFileUpload> files,
    String? companyId,
  }) async {
    if (files.isEmpty) {
      return null;
    }

    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/prospects/$prospectId/documents/$documentId',
        data: await _documentsFormData(files: files),
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> deleteDocument({
    required String prospectId,
    required String documentId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.delete<Object?>(
        '/v1/mobile/prospects/$prospectId/documents/$documentId',
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> createActivity({
    required String prospectId,
    required String description,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/prospects/$prospectId/activities',
        data: _activityFormData(description: description),
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> uploadActivityDocuments({
    required String prospectId,
    required List<ProspectFileUpload> files,
    String? companyId,
  }) async {
    if (files.isEmpty) {
      return null;
    }

    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/prospects/$prospectId/activities/documents',
        data: await _activityDocumentsFormData(files: files),
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> deleteActivityDocument({
    required String prospectId,
    required String documentId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.delete<Object?>(
        '/v1/mobile/prospects/$prospectId/activities/documents/$documentId',
        options: _companyOptions(companyId),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<FormData> _documentFormData({
    required String documentTypeId,
    required List<ProspectFileUpload> files,
  }) async {
    final formData = await _documentsFormData(files: files);
    formData.fields.add(MapEntry('documentTypeId', documentTypeId));
    return formData;
  }

  FormData _activityFormData({required String description}) {
    final formData = FormData();
    formData.fields.add(MapEntry('description', description));
    return formData;
  }

  Future<FormData> _activityDocumentsFormData({
    required List<ProspectFileUpload> files,
  }) {
    return _documentsFormData(files: files);
  }

  Future<FormData> _documentsFormData({
    required List<ProspectFileUpload> files,
  }) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(MapEntry('files[]', await file.toMultipartFile()));
    }
    return formData;
  }

  Options? _companyOptions(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      return null;
    }

    return Options(headers: {'X-Company-Id': companyId});
  }

  Map<String, dynamic> _responseData(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const AppException('Format respons server tidak valid.');
  }

  String? _responseMessage(Response<Object?> response) {
    final data = _responseData(response);
    return data['message'] as String?;
  }

  AppException _mapDioException(DioException error) {
    return ErrorMapper.fromDio(error);
  }
}

class ProspectCreateRequest {
  const ProspectCreateRequest({
    required this.clientName,
    required this.title,
    required this.projectTypeId,
    required this.description,
    required this.estimatedValue,
    required this.projectStartDate,
    required this.projectEndDate,
    required this.tenderSubmissionDeadline,
  });

  final String clientName;
  final String title;
  final String projectTypeId;
  final String description;
  final int estimatedValue;
  final String projectStartDate;
  final String projectEndDate;
  final String tenderSubmissionDeadline;

  Map<String, Object?> toJson() {
    return {
      'clientName': clientName,
      'title': title,
      'projectTypeId': projectTypeId,
      'description': description,
      'estimatedValue': estimatedValue,
      'projectStartDate': projectStartDate,
      'projectEndDate': projectEndDate,
      'tenderSubmissionDeadline': tenderSubmissionDeadline,
    };
  }
}

class ProspectFileUpload {
  const ProspectFileUpload({required this.name, required this.path});

  final String name;
  final String? path;

  Future<MultipartFile> toMultipartFile() {
    final uploadPath = path;
    if (uploadPath != null && uploadPath.isNotEmpty) {
      return MultipartFile.fromFile(uploadPath, filename: name);
    }

    throw const AppException('File tidak dapat dibaca.');
  }
}

List<T> _objectList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(mapper)
      .toList(growable: false);
}
