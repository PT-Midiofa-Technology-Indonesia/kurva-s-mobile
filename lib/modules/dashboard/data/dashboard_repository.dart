import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'models/dashboard_summary.dart';

class DashboardRepository {
  const DashboardRepository({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<DashboardSummary> fetchDashboard() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/dashboard',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return ApiResponse.fromJson<DashboardSummary>(
        data,
        (json) => DashboardSummary.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    return ErrorMapper.fromDio(error);
  }
}
