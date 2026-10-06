import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_overview_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_task_list_page.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';

void main() {
  for (final isQc in [false, true]) {
    testWidgets('history dot follows status and refresh for isQc=$isQc', (
      tester,
    ) async {
      var status = Completer<bool>();
      final requestedTabs = <String?>[];
      final container = ProviderContainer(
        overrides: [
          projectCacheReadEnabledProvider.overrideWithValue(false),
          projectDetailProvider.overrideWith(
            (ref, id) => Stream.value(_project),
          ),
          projectTasksProvider.overrideWith((ref, query) {
            requestedTabs.add(query.tab);
            return Stream.value(
              ProjectTasksResult.fromPayload({'data': <Object>[]}),
            );
          }),
          projectQcTasksProvider.overrideWith((ref, query) {
            requestedTabs.add(query.tab);
            return Stream.value([]);
          }),
          projectHistoryHasUnreadProvider.overrideWith((ref, query) {
            expect(query.projectId, 'project-1');
            expect(query.isQc, isQc);
            return status.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ProjectOverviewPage(
              detail: ProjectOverviewData(
                projectId: 'project-1',
                projectName: 'Project Test',
                title: isQc
                    ? ProjectTaskListPage.qualityProjectTitle
                    : ProjectTaskListPage.taskProjectTitle,
                taskProject: 0,
                qualityControl: 0,
                taskMeeting: 0,
                qualityMeeting: 0,
              ),
            ),
          ),
        ),
      );
      bool showsDot() => tester
          .widget<AppUnderlineTabs>(find.byType(AppUnderlineTabs))
          .items
          .singleWhere((item) => item.label == 'History')
          .showIndicatorDot;
      expect(showsDot(), isFalse);
      status.complete(true);
      await tester.pumpAndSettle();
      expect(showsDot(), isTrue);
      expect(requestedTabs, isNot(contains('history')));
      status = Completer<bool>();
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();
      status.complete(false);
      await tester.pumpAndSettle();
      expect(requestedTabs, isNot(contains('history')));
      expect(showsDot(), isFalse);
      status = Completer<bool>();
      container.invalidate(
        projectHistoryHasUnreadProvider((projectId: 'project-1', isQc: isQc)),
      );
      container.read(
        projectHistoryHasUnreadProvider((projectId: 'project-1', isQc: isQc)),
      );
      await tester.pump();
      status.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(showsDot(), isFalse);
      status = Completer<bool>();
      container.invalidate(
        projectHistoryHasUnreadProvider((projectId: 'project-1', isQc: isQc)),
      );
      container.read(
        projectHistoryHasUnreadProvider((projectId: 'project-1', isQc: isQc)),
      );
      await tester.tap(find.text('History'));
      await tester.pump();
      expect(requestedTabs, contains('history'));
      status.complete(true);
      await tester.pumpAndSettle();
      expect(showsDot(), isFalse);
      await tester.tap(find.text('Task (0)'));
      await tester.pumpAndSettle();
      expect(showsDot(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows task project API count and card fields', (tester) async {
    final result = ProjectTasksResult.fromPayload({
      'data': [
        {
          'id': 'task-1',
          'code': 'A.01',
          'title': 'Pekerjaan Pembersihan & Pengukuran Lahan',
          'status': 'in_progress',
          'statusLabel': 'Progress',
          'taskType': 'work',
          'uom': {'id': 'uom-1', 'code': 'M2', 'name': 'Meter Persegi'},
          'assignDate': '2026-09-23',
          'targetVolume': '250.0000',
          'completedVolume': '0.0000',
          'helpersCount': 2,
          'helpers': [
            {'id': 'helper-1', 'name': 'Budi Santoso'},
            {'id': 'helper-2', 'name': 'Andi Wijaya'},
          ],
          'assignee': {'id': 'assignee-1', 'name': 'Siti Rahayu'},
          'childCount': 0,
        },
      ],
      'counts': {'inProgress': 10, 'done': 2},
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectHistoryHasUnreadProvider.overrideWith(
            (ref, query) async => false,
          ),
          projectDetailProvider.overrideWith(
            (ref, projectId) => Stream.value(_project),
          ),
          projectTasksProvider.overrideWith(
            (ref, query) => Stream.value(result),
          ),
        ],
        child: const MaterialApp(
          home: ProjectOverviewPage(
            detail: ProjectOverviewData(
              projectId: 'project-1',
              projectName: 'Project Test',
              title: ProjectTaskListPage.taskProjectTitle,
              taskProject: 10,
              qualityControl: 0,
              taskMeeting: 0,
              qualityMeeting: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Task (10)'), findsOneWidget);
    expect(
      find.text('A.01  Pekerjaan Pembersihan & Pengukuran Lahan'),
      findsOneWidget,
    );
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('2 Personil'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
    expect(find.text('AW'), findsOneWidget);
    expect(find.text('0/250 M2'), findsOneWidget);
    expect(find.text('23 Sep 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _project = Project(
  id: 'project-1',
  code: 'P-001',
  name: 'Project Test',
  description: null,
  status: 'active',
  prospectStage: '',
  client: null,
  projectType: null,
  startDate: null,
  endDate: null,
  durationDays: 0,
  nodesCount: 10,
  summary: null,
  permissions: [],
  createdAt: null,
);
