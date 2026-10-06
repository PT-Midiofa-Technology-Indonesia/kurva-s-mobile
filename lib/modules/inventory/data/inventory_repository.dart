import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'models/inventory_models.dart';

class InventoryRepository {
  const InventoryRepository({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<List<InventoryMaterial>> fetchMaterials() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/inventory/materials',
      );

      return _responseList(response)
          .whereType<Map<String, dynamic>>()
          .map(InventoryMaterial.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<InventoryMaterialDetail> fetchMaterialDetail(
    String itemCatalogId,
  ) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/inventory/materials/$itemCatalogId',
      );

      return ApiResponse.fromJson<InventoryMaterialDetail>(
        _responseData(response),
        (json) =>
            InventoryMaterialDetail.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<InventoryEquipment>> fetchEquipment({String? status}) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/inventory/equipment',
        queryParameters: _queryParameters({'status': status}),
      );

      return _responseList(response)
          .whereType<Map<String, dynamic>>()
          .map(InventoryEquipment.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<InventoryEquipmentDetail> fetchEquipmentDetail(
    String resourceUnitId,
  ) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/inventory/equipment/$resourceUnitId',
      );

      return ApiResponse.fromJson<InventoryEquipmentDetail>(
        _responseData(response),
        (json) =>
            InventoryEquipmentDetail.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitStockAdjustment({
    required String itemCatalogId,
    required num adjustmentQty,
    String? reason,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/inventory/stock-adjustments',
        data: {
          'itemCatalogId': itemCatalogId,
          'adjustmentQty': adjustmentQty,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );

      return _responseData(response)['message'] as String?;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<InventoryStockAdjustment>> fetchStockAdjustments() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/inventory/stock-adjustments',
      );

      return InventoryStockAdjustment.listFromPayload(
        _responseData(response)['data'],
      );
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

  List<Object?> _responseList(Response<Object?> response) {
    final payload = _responseData(response)['data'];
    if (payload is List) return payload;

    throw const AppException('Format respons server tidak valid.');
  }

  Map<String, dynamic> _responseData(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;

    throw const AppException('Format respons server tidak valid.');
  }

  AppException _mapDioException(DioException error) {
    return ErrorMapper.fromDio(error);
  }
}
