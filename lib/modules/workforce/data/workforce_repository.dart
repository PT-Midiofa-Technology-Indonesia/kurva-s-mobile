import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_models.dart';
import 'local/attendance_local_data_source.dart';
import 'local/workforce_get_cache.dart';
import 'models/attendance_list.dart';
import 'models/leave.dart';
import 'models/location.dart';
import 'models/overtime.dart';
import 'models/today_attendance.dart';

class WorkforceRepository {
  const WorkforceRepository({
    required DioClient dioClient,
    WorkforceGetCache? getCache,
    AttendanceLocalDataSource? attendanceLocalDataSource,
    SyncScope? scope,
    bool cacheReadEnabled = false,
  }) : _dioClient = dioClient,
       _getCache = getCache,
       _attendanceLocalDataSource = attendanceLocalDataSource,
       _scope = scope,
       _cacheReadEnabled = cacheReadEnabled;

  final DioClient _dioClient;
  final WorkforceGetCache? _getCache;
  final AttendanceLocalDataSource? _attendanceLocalDataSource;
  final SyncScope? _scope;
  final bool _cacheReadEnabled;

  Future<TodayAttendance> fetchTodayAttendance() async {
    const endpointKey = 'workforce:attendance:today';
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/attendance/today',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }
      await _putGetCache(endpointKey: endpointKey, response: data);

      return ApiResponse.fromJson<TodayAttendance>(
        data,
        (json) => TodayAttendance.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw _mapDioException(error);
      }
      final cached = await _readGetCache(endpointKey: endpointKey);
      if (cached != null) {
        return ApiResponse.fromJson<TodayAttendance>(
          cached,
          (json) => TodayAttendance.fromJson(json as Map<String, dynamic>),
        ).data;
      }
      throw _mapDioException(error);
    }
  }

  Future<AttendanceListResult> fetchAttendanceList({
    required AttendanceListFilter filter,
    int page = 1,
  }) async {
    final query = filter.toQueryParameters(page: page);
    const endpointKey = 'workforce:attendance:list';
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/attendance',
        queryParameters: query,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }
      await _putGetCache(
        endpointKey: endpointKey,
        query: query,
        response: data,
      );

      final result = AttendanceListResult.fromJson(data);
      await _cacheTodayAttendanceFromList(result.records);
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw _mapDioException(error);
      }
      final cached = await _readGetCache(
        endpointKey: endpointKey,
        query: query,
      );
      if (cached != null) {
        final result = AttendanceListResult.fromJson(cached);
        await _cacheTodayAttendanceFromList(result.records);
        return result;
      }
      throw _mapDioException(error);
    }
  }

  Future<AttendanceRecord> fetchAttendanceDetail(String attendanceId) async {
    final endpointKey = 'workforce:attendance:detail:$attendanceId';
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/attendance/$attendanceId',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }
      await _putGetCache(endpointKey: endpointKey, response: data);

      return ApiResponse.fromJson<AttendanceRecord>(
        data,
        (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw _mapDioException(error);
      }
      final cached = await _readGetCache(endpointKey: endpointKey);
      if (cached != null) {
        return ApiResponse.fromJson<AttendanceRecord>(
          cached,
          (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
        ).data;
      }
      throw _mapDioException(error);
    }
  }

  Future<List<WorkforceLocation>> fetchLocations({required String type}) async {
    final query = <String, Object?>{'type': type};
    const endpointKey = 'workforce:attendance:locations';
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/locations',
        queryParameters: query,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }
      await _putGetCache(
        endpointKey: endpointKey,
        query: query,
        response: data,
      );

      return ApiResponse.fromJson<List<WorkforceLocation>>(data, (json) {
        if (json is! List) {
          return const <WorkforceLocation>[];
        }

        return json
            .whereType<Map<String, dynamic>>()
            .map(WorkforceLocation.fromJson)
            .toList(growable: false);
      }).data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw _mapDioException(error);
      }
      final cached = await _readGetCache(
        endpointKey: endpointKey,
        query: query,
      );
      if (cached != null) {
        return ApiResponse.fromJson<List<WorkforceLocation>>(cached, (json) {
          if (json is! List) return const <WorkforceLocation>[];
          return json
              .whereType<Map<String, dynamic>>()
              .map(WorkforceLocation.fromJson)
              .toList(growable: false);
        }).data;
      }
      throw _mapDioException(error);
    }
  }

  Future<OvertimeListResult> fetchOvertimeList({
    required OvertimeListFilter filter,
    int page = 1,
  }) async {
    final query = filter.toQueryParameters(page: page);
    const endpointKey = 'workforce:overtime:list';
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/overtime',
        queryParameters: query,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }
      await _putGetCache(
        endpointKey: endpointKey,
        query: query,
        response: data,
      );
      final result = OvertimeListResult.fromJson(data);
      await _cacheOvertimeReferences(result.records, filter);
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw _mapDioException(error);
      }
      final cached = await _readGetCache(
        endpointKey: endpointKey,
        query: query,
      );
      if (cached != null) {
        final result = OvertimeListResult.fromJson(cached);
        await _cacheOvertimeReferences(result.records, filter);
        return result;
      }
      throw _mapDioException(error);
    }
  }

  Future<OvertimeRecord> fetchOvertimeDetail(String overtimeId) async {
    final endpointKey = 'workforce:overtime:detail:$overtimeId';
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/overtime/$overtimeId',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }
      await _putGetCache(endpointKey: endpointKey, response: data);

      final record = ApiResponse.fromJson<OvertimeRecord>(
        data,
        (json) => OvertimeRecord.fromJson(json as Map<String, dynamic>),
      ).data;
      await _cacheOvertimeReferences([record], const OvertimeListFilter());
      return record;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw _mapDioException(error);
      }
      final cached = await _readGetCache(endpointKey: endpointKey);
      if (cached != null) {
        final record = ApiResponse.fromJson<OvertimeRecord>(
          cached,
          (json) => OvertimeRecord.fromJson(json as Map<String, dynamic>),
        ).data;
        await _cacheOvertimeReferences([record], const OvertimeListFilter());
        return record;
      }
      throw _mapDioException(error);
    }
  }

  Future<List<OvertimeRecord>> fetchAllApprovedOvertimeReferences({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = <OvertimeRecord>[];
    var page = 1;
    while (true) {
      final result = await fetchOvertimeList(
        filter: OvertimeListFilter(
          status: 'approved',
          startDate: startDate,
          endDate: endDate,
          perPage: 100,
        ),
        page: page,
      );
      records.addAll(result.records);
      if (result.meta.currentPage >= result.meta.lastPage) break;
      page += 1;
    }
    return records;
  }

  Future<String?> submitOvertime(OvertimeRequestInput input) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/overtime',
        data: input.toJson(),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return data['message'] as String?;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> cancelOvertime(String overtimeId) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/overtime/$overtimeId/cancel',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return data['message'] as String?;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<LeaveType>> fetchLeaveTypes() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/leave-types',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return ApiResponse.fromJson<List<LeaveType>>(data, (json) {
        if (json is! List) {
          return const <LeaveType>[];
        }

        return json
            .whereType<Map<String, dynamic>>()
            .map(LeaveType.fromJson)
            .toList(growable: false);
      }).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<LeaveListResult> fetchLeaveList({
    required LeaveListFilter filter,
    int page = 1,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/leaves',
        queryParameters: filter.toQueryParameters(page: page),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return LeaveListResult.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<LeaveRecord> fetchLeaveDetail(String leaveId) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/leaves/$leaveId',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return ApiResponse.fromJson<LeaveRecord>(
        data,
        (json) => LeaveRecord.fromJson(json as Map<String, dynamic>),
      ).data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitLeave(LeaveRequestInput input) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/leaves',
        data: input.toJson(),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return data['message'] as String?;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> cancelLeave(String leaveId) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/leaves/$leaveId/cancel',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format respons server tidak valid.');
      }

      return data['message'] as String?;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    return ErrorMapper.fromDio(error);
  }

  Future<void> _putGetCache({
    required String endpointKey,
    required Map<String, dynamic> response,
    Map<String, Object?> query = const {},
  }) async {
    final scope = _scope;
    final cache = _getCache;
    if (scope == null || cache == null) return;
    await cache.put(
      scope: scope,
      endpointKey: endpointKey,
      query: query,
      response: response,
    );
  }

  Future<void> _cacheTodayAttendanceFromList(
    List<AttendanceRecord> records,
  ) async {
    final scope = _scope;
    final local = _attendanceLocalDataSource;
    if (scope == null || local == null) return;
    await local.putTodaySnapshotFromList(scope: scope, records: records);
  }

  Future<Map<String, dynamic>?> _readGetCache({
    required String endpointKey,
    Map<String, Object?> query = const {},
  }) {
    if (!_cacheReadEnabled) return Future.value(null);
    final scope = _scope;
    final cache = _getCache;
    if (scope == null || cache == null) return Future.value(null);
    return cache.get(scope: scope, endpointKey: endpointKey, query: query);
  }

  Future<void> _cacheOvertimeReferences(
    List<OvertimeRecord> records,
    OvertimeListFilter filter,
  ) async {
    final scope = _scope;
    final local = _attendanceLocalDataSource;
    if (scope == null || local == null || records.isEmpty) return;
    await local.upsertOvertimeReferences(
      scope: scope,
      records: records,
      rangeStart: filter.startDate,
      rangeEnd: filter.endDate,
    );
  }
}
