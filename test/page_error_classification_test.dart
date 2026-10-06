import 'dart:async';

import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/logistic/data/local/logistic_local_data_source.dart';
import 'package:curva_mobile/modules/logistic/data/logistic_repository.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/project/data/local/project_local_data_source.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/workforce/data/local/workforce_get_cache.dart';
import 'package:curva_mobile/modules/workforce/data/workforce_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => null;
}

void main() {
  const scope = SyncScope(accountId: 'account', companyId: 'company');
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=https://example.test'));

  for (final status in [null, 403, 500]) {
    test(
      'cache-enabled providers preserve error classification: $status',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final client = DioClient(secureStorage: _Storage());
        addTearDown(() => client.dio.close());
        client.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: status == null
                      ? DioExceptionType.connectionError
                      : DioExceptionType.badResponse,
                  response: status == null
                      ? null
                      : Response(
                          requestOptions: options,
                          statusCode: status,
                          data: {'message': 'Server error'},
                        ),
                ),
              );
            },
          ),
        );
        final container = ProviderContainer(
          overrides: [
            syncScopeProvider.overrideWithValue(scope),
            projectCacheReadEnabledProvider.overrideWithValue(true),
            logisticCacheReadEnabledProvider.overrideWithValue(true),
            projectRepositoryProvider.overrideWithValue(
              ProjectRepository(
                dioClient: client,
                scope: scope,
                cacheReadEnabled: true,
                localDataSource: ProjectLocalDataSource(database: database),
              ),
            ),
            logisticRepositoryProvider.overrideWithValue(
              LogisticRepository(
                dioClient: client,
                scope: scope,
                localDataSource: LogisticLocalDataSource(database: database),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        final expectedKind = status == null
            ? AppExceptionKind.offlineCacheMiss
            : status == 403
            ? AppExceptionKind.forbidden
            : AppExceptionKind.general;
        final matcher = throwsA(
          isA<AppException>().having((e) => e.kind, 'kind', expectedKind),
        );
        await expectLater(container.read(projectListProvider.future), matcher);
        await expectLater(
          container.read(projectDetailProvider('project').future),
          matcher,
        );
        await expectLater(
          container.read(
            pickupOrdersProvider(const LogisticListQuery(tab: 'open')).future,
          ),
          matcher,
        );
        await expectLater(
          container.read(pickupDetailProvider('pickup').future),
          matcher,
        );
      },
    );
  }

  test(
    'cached project becomes an access error when refresh returns 403',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = ProjectLocalDataSource(database: database);
      await local.putProjectDetail(
        scope: scope,
        project: Project.fromJson({'id': 'project'}),
      );
      final client = DioClient(secureStorage: _Storage());
      addTearDown(() => client.dio.close());
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: 403),
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          syncScopeProvider.overrideWithValue(scope),
          projectCacheReadEnabledProvider.overrideWithValue(true),
          projectRepositoryProvider.overrideWithValue(
            ProjectRepository(
              dioClient: client,
              scope: scope,
              cacheReadEnabled: true,
              localDataSource: local,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final failure = Completer<Object>();
      var sawCachedData = false;
      container.listen(projectDetailProvider('project'), (_, next) {
        if (next.hasValue) sawCachedData = true;
        if (next.hasError && !failure.isCompleted) failure.complete(next.error);
      }, fireImmediately: true);
      expect(
        await failure.future.timeout(const Duration(seconds: 5)),
        isA<AppException>().having(
          (e) => e.kind,
          'kind',
          AppExceptionKind.forbidden,
        ),
      );
      expect(sawCachedData, isTrue);
    },
  );

  test('workforce never falls back to cache after a 403 response', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final cache = WorkforceGetCache(database: database);
    await cache.put(
      scope: scope,
      endpointKey: 'workforce:attendance:today',
      response: {'data': <String, dynamic>{}},
    );
    final client = DioClient(secureStorage: _Storage());
    addTearDown(() => client.dio.close());
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: 403),
            ),
          );
        },
      ),
    );
    final repository = WorkforceRepository(
      dioClient: client,
      scope: scope,
      getCache: cache,
      cacheReadEnabled: true,
    );
    await expectLater(
      repository.fetchTodayAttendance(),
      throwsA(
        isA<AppException>().having(
          (e) => e.kind,
          'kind',
          AppExceptionKind.forbidden,
        ),
      ),
    );
  });
}
