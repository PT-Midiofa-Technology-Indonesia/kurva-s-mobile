import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/project/data/models/effective_project_task.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_report_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';

void main() {
  final overlay = ProjectTaskSyncOverlay(
    operationId: 'report',
    operationType: SyncOperationType.projectTaskDone.storageName,
    state: OutboxState.pending,
    attemptCount: 0,
    createdAt: DateTime.utc(2026),
  );
  testWidgets('pending manpower report disables a replacement submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectTargetOperationProvider.overrideWith((ref, query) {
            expect(query.targetResourceKey, 'project:project:task:manpower');
            return Stream.value(overlay);
          }),
          projectTaskHistoryProvider.overrideWith((ref, query) async => []),
          projectManpowerHistoryHasUnreadProvider.overrideWith(
            (ref, query) async => false,
          ),
        ],
        child: const MaterialApp(
          home: ProjectManpowerReportPage(
            projectId: 'project',
            taskId: 'manpower',
            manpowerName: 'Worker',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Laporan menunggu sinkronisasi.'), findsOneWidget);
    expect(find.text('Ajukan ke QC'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manpower card shows pending status and disables deletion', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'id': 'parent',
      'projectId': 'project',
      'status': 'created',
      'isFinalLevel': true,
      'manpower': [
        {
          'id': 'manpower',
          'employee': {'id': 'worker', 'name': 'Worker'},
          'status': 'created',
          'canDelete': true,
          'canSubmit': true,
        },
      ],
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectTaskDetailProvider.overrideWith(
            (ref, query) => Stream.value(task),
          ),
          projectTargetOperationProvider.overrideWith(
            (ref, query) => Stream.value(overlay),
          ),
        ],
        child: MaterialApp(
          home: ProjectTaskDetailPage(
            detail: ProjectTaskDetailData.fromTask(task),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Menunggu sinkronisasi'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton &&
                  widget.tooltip == 'Hapus manpower Worker',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
