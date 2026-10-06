import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'models/cost_request.dart';

class ExpenseRepository {
  const ExpenseRepository({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<CostRequestListResult> fetchCostRequests({
    String? companyId,
    String? status,
    String? requestType,
    String? startDate,
    String? endDate,
    String? year,
    String? search,
    int? perPage,
    int? page,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/cost-requests',
        queryParameters: _queryParameters({
          'status': status,
          'requestType': requestType,
          'startDate': startDate,
          'endDate': endDate,
          'year': year,
          'search': search,
          'perPage': perPage,
          'page': page,
        }),
        options: _companyOptions(companyId),
      );

      return CostRequestListResult.fromJson(_responseData(response));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<CostRequest> fetchCostRequestDetail({
    required String costRequestId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/cost-requests/$costRequestId',
        options: _companyOptions(companyId),
      );
      final data = _responseData(response);

      return ApiResponse.fromJson<CostRequest>(
        data,
        (json) => CostRequest.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> createCostRequest({
    required ExpenseCostRequest request,
    String? companyId,
  }) async {
    final formData = await request.toFormData();

    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/cost-requests',
        data: formData,
        options: _companyOptions(companyId),
      );
      final data = _responseData(response);

      return data['message'] as String?;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> cancelCostRequest({
    required String costRequestId,
    String? companyId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/cost-requests/$costRequestId/cancel',
        options: _companyOptions(companyId),
      );
      final data = _responseData(response);

      return data['message'] as String?;
    } on DioException catch (error) {
      throw _mapDioException(error);
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

  Map<String, dynamic> _responseData(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const AppException('Format respons server tidak valid.');
  }

  Options? _companyOptions(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      return null;
    }

    return Options(headers: {'X-Company-Id': companyId});
  }

  AppException _mapDioException(DioException error) {
    return ErrorMapper.fromDio(error);
  }
}

class ExpenseCostRequest {
  const ExpenseCostRequest({
    required this.requestType,
    required this.reason,
    required this.dueDate,
    required this.paymentMethod,
    required this.projectId,
    required this.notes,
    required this.items,
  });

  final String requestType;
  final String reason;
  final String dueDate;
  final String paymentMethod;
  final String? projectId;
  final String notes;
  final List<ExpenseCostRequestItem> items;

  Future<FormData> toFormData() async {
    final formData = FormData();

    formData.fields
      ..add(MapEntry('requestType', requestType))
      ..add(MapEntry('reason', reason))
      ..add(MapEntry('dueDate', dueDate))
      ..add(MapEntry('paymentMethod', paymentMethod));

    if (projectId != null && projectId!.isNotEmpty) {
      formData.fields.add(MapEntry('projectId', projectId!));
    }

    formData.fields.add(MapEntry('notes', notes));

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      formData.fields
        ..add(MapEntry('items[$index][receiptNumber]', item.receiptNumber))
        ..add(MapEntry('items[$index][description]', item.description))
        ..add(MapEntry('items[$index][amount]', item.amount))
        ..add(MapEntry('items[$index][notes]', item.notes));

      for (final proof in item.proofs) {
        formData.files.add(
          MapEntry('items[$index][proofs][]', await proof.toMultipartFile()),
        );
      }
    }

    return formData;
  }
}

class ExpenseCostRequestItem {
  const ExpenseCostRequestItem({
    required this.receiptNumber,
    required this.description,
    required this.amount,
    required this.notes,
    required this.proofs,
  });

  final String receiptNumber;
  final String description;
  final String amount;
  final String notes;
  final List<ExpenseProofUpload> proofs;
}

class ExpenseProofUpload {
  const ExpenseProofUpload({required this.name, this.path, this.bytes});

  final String name;
  final String? path;
  final Uint8List? bytes;

  Future<MultipartFile> toMultipartFile() {
    final uploadPath = path;
    if (uploadPath != null && uploadPath.isNotEmpty) {
      return MultipartFile.fromFile(uploadPath, filename: name);
    }

    final uploadBytes = bytes;
    if (uploadBytes != null) {
      return Future.value(MultipartFile.fromBytes(uploadBytes, filename: name));
    }

    throw const AppException('File bukti tidak dapat dibaca.');
  }
}
