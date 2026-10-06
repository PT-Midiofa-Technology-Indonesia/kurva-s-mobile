import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';

void main() {
  test(
    'successful sync refreshes mounted lists, overview counts and history',
    () async {
      final statuses = StreamController<SyncStatus>();
      var listFetches = 0;
      var historyFetches = 0;
      final container = ProviderContainer(
        overrides: [
          syncStatusProvider.overrideWith((ref) => statuses.stream),
          projectTasksProvider.overrideWith((ref, query) {
            listFetches++;
            return Stream.value(
              ProjectTasksResult(
                tasks: const [],
                inProgressCount: 0,
                doneCount: listFetches,
              ),
            );
          }),
          projectTaskHistoryProvider.overrideWith((ref, query) async {
            historyFetches++;
            return [];
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await statuses.close();
      });
      container.read(projectSyncRefreshProvider);
      const listQuery = ProjectTasksQuery(projectId: 'project', tab: 'open');
      const taskQuery = ProjectTaskQuery(
        projectId: 'project',
        taskId: 'manpower',
      );
      final list = container.listen(projectTasksProvider(listQuery), (_, _) {});
      final history = container.listen(
        projectTaskHistoryProvider(taskQuery),
        (_, _) {},
      );
      addTearDown(list.close);
      addTearDown(history.close);
      await container.read(projectTasksProvider(listQuery).future);
      await container.read(projectTaskHistoryProvider(taskQuery).future);
      statuses.add(const SyncStatus(state: SyncRunState.syncing));
      await container.pump();
      statuses.add(
        const SyncStatus(state: SyncRunState.completed, completedCount: 1),
      );
      await container.pump();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await container.pump();
      final refreshed = await container.read(
        projectTasksProvider(listQuery).future,
      );
      await container.read(projectTaskHistoryProvider(taskQuery).future);
      expect(refreshed.doneCount, 2);
      expect(historyFetches, 2);
      statuses.add(
        const SyncStatus(
          state: SyncRunState.completed,
          completedCount: 1,
          pendingCount: 2,
        ),
      );
      await container.pump();
      expect(listFetches, 2);
      statuses.add(const SyncStatus(state: SyncRunState.syncing));
      await container.pump();
      statuses.add(
        const SyncStatus(state: SyncRunState.completed, pendingCount: 1),
      );
      await container.pump();
      expect(listFetches, 2);
    },
  );
}
