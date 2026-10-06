import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/meeting/meeting_overview_page.dart';

void main() {
  testWidgets('shows task and history tabs without the old section title', (
    tester,
  ) async {
    final requestedTabs = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meetingOverviewTasksProvider.overrideWith((ref, query) async {
            requestedTabs.add(query.tab);
            final isHistory = query.tab == 'history';
            return MeetingTasksResult(
              tasks: [
                _task(
                  id: isHistory ? 'history-1' : 'task-1',
                  code: isHistory ? 'H.1' : 'T.1',
                  title: isHistory ? 'Tugas selesai' : 'Tugas berjalan',
                ),
              ],
              inProgressCount: 210,
              doneCount: 20,
            );
          }),
        ],
        child: const MaterialApp(
          home: MeetingOverviewPage(
            data: MeetingOverviewData(
              meetingId: 'meeting-1',
              title: 'Task Meeting',
              isQualityMeeting: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Task (1)'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Daftar tugas'), findsNothing);
    expect(find.text('T.1  Tugas berjalan'), findsOneWidget);
    expect(requestedTabs, ['open']);

    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump();

    expect(find.text('H.1  Tugas selesai'), findsOneWidget);
    expect(find.text('T.1  Tugas berjalan'), findsNothing);
    expect(requestedTabs, ['open', 'history']);
  });

  testWidgets('shows Assignee action when task canAssign is true', (
    tester,
  ) async {
    await tester.pumpWidget(_overviewWithTask(canAssign: true));
    await tester.pump();

    await tester.tap(find.text('T.1  Tugas berjalan'));
    await tester.pumpAndSettle();

    expect(find.text('Assignee'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
  });

  testWidgets('hides Assignee action when task canAssign is false', (
    tester,
  ) async {
    await tester.pumpWidget(_overviewWithTask(canAssign: false));
    await tester.pump();

    await tester.tap(find.text('T.1  Tugas berjalan'));
    await tester.pumpAndSettle();

    expect(find.text('Assignee'), findsNothing);
    expect(find.text('Detail'), findsOneWidget);
  });

  testWidgets('refreshes overview after assignee update succeeds', (
    tester,
  ) async {
    final requestedTabs = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MeetingOverviewPage(
            data: MeetingOverviewData(
              meetingId: 'meeting-1',
              title: 'Task Meeting',
              isQualityMeeting: false,
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.meetingAssignee,
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.pop(true),
                child: const Text('Simpan assignee'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meetingOverviewTasksProvider.overrideWith((ref, query) async {
            requestedTabs.add(query.tab);
            return MeetingTasksResult(
              tasks: [
                _task(
                  id: 'task-1',
                  code: 'T.1',
                  title: 'Tugas berjalan',
                  canAssign: true,
                ),
              ],
              inProgressCount: 1,
              doneCount: 0,
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('T.1  Tugas berjalan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assignee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan assignee'));
    await tester.pumpAndSettle();

    expect(requestedTabs.where((tab) => tab == 'open'), hasLength(2));
    expect(requestedTabs.where((tab) => tab == 'history'), hasLength(1));
  });

  for (final isQualityMeeting in [false, true]) {
    testWidgets(
      'refreshes ${isQualityMeeting ? 'quality' : 'task'} overview after detail submit succeeds',
      (tester) async {
        final requestedTabs = <String>[];
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => MeetingOverviewPage(
                data: MeetingOverviewData(
                  meetingId: 'meeting-1',
                  title: isQualityMeeting ? 'Quality Meeting' : 'Task Meeting',
                  isQualityMeeting: isQualityMeeting,
                ),
              ),
            ),
            GoRoute(
              path: RouteNames.meetingTaskAction,
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.pop(true),
                    child: const Text('Submit berhasil'),
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              meetingOverviewTasksProvider.overrideWith((ref, query) async {
                requestedTabs.add(query.tab);
                return MeetingTasksResult(
                  tasks: [
                    _task(id: 'task-1', code: 'T.1', title: 'Tugas berjalan'),
                  ],
                  inProgressCount: 1,
                  doneCount: 0,
                );
              }),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('T.1  Tugas berjalan'));
        await tester.pumpAndSettle();
        if (!isQualityMeeting) {
          await tester.tap(find.text('Detail'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Submit berhasil'));
        await tester.pumpAndSettle();

        expect(requestedTabs.where((tab) => tab == 'open'), hasLength(2));
        expect(requestedTabs.where((tab) => tab == 'history'), hasLength(1));
      },
    );
  }
}

Widget _overviewWithTask({required bool canAssign}) {
  return ProviderScope(
    overrides: [
      meetingOverviewTasksProvider.overrideWith((ref, query) async {
        return MeetingTasksResult(
          tasks: [
            _task(
              id: 'task-1',
              code: 'T.1',
              title: 'Tugas berjalan',
              canAssign: canAssign,
            ),
          ],
          inProgressCount: 1,
          doneCount: 0,
        );
      }),
    ],
    child: const MaterialApp(
      home: MeetingOverviewPage(
        data: MeetingOverviewData(
          meetingId: 'meeting-1',
          title: 'Task Meeting',
          isQualityMeeting: false,
        ),
      ),
    ),
  );
}

MeetingTask _task({
  required String id,
  required String code,
  required String title,
  bool canAssign = false,
}) {
  return MeetingTask(
    id: id,
    meetingId: 'meeting-1',
    code: code,
    title: title,
    projectName: 'Project A',
    status: 'progress',
    creator: null,
    assignee: null,
    assignees: const [],
    createdAt: null,
    updatedAt: null,
    previousEvidence: const [],
    canAssign: canAssign,
  );
}
