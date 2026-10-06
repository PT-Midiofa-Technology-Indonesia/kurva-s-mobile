import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_task_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Task Project card with one action opens it directly', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: ProjectTaskCardAction(
              task: ProjectTaskListItemData(
                canBreakdown: true,
                canAssign: true,
                code: 'A.01',
                title: 'Pekerjaan Pembersihan',
                assignees: const [],
                assigneeName: 'Siti Rahayu',
              ),
              type: ProjectTaskListPage.taskProjectTitle,
              onRefreshRequested: () async {},
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.projectSubTaskDetail,
          builder: (_, _) => const Scaffold(body: Text('Detail Task')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStateProvider.overrideWith(
            (ref) => Stream.value(const ConnectivityState.online()),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ProjectTaskCardAction));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Aksi Selanjutnya'), findsNothing);
    expect(find.text('Task breakdown'), findsNothing);
    expect(find.text('Detail Task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quality card with multiple actions shows action sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStateProvider.overrideWith(
            (ref) => Stream.value(const ConnectivityState.online()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProjectTaskCardAction(
              task: ProjectTaskListItemData(
                isQc: true,
                canClaim: true,
                canAssign: false,
                code: 'QC-01',
                title: 'Pengecoran',
                assignees: const [],
                assigneeName: '-',
              ),
              type: ProjectTaskListPage.qualityProjectTitle,
              onRefreshRequested: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ProjectTaskCardAction));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pilih Aksi Selanjutnya'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    expect(find.text('Assign Terpilih'), findsOneWidget);
    expect(find.text('Claim'), findsOneWidget);
    expect(find.text('Go to sub task'), findsNothing);

    expect(
      tester.getTopLeft(find.text('Assign Terpilih')).dy,
      lessThan(tester.getTopLeft(find.text('Claim')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Claim')).dy,
      lessThan(tester.getTopLeft(find.text('Detail')).dy),
    );
  });

  testWidgets('Quality card with one action opens it directly', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: ProjectTaskCardAction(
              task: ProjectTaskListItemData(
                isQc: true,
                canClaim: false,
                canAssign: false,
                code: 'QC-01',
                title: 'Pengecoran',
                assignees: const [],
                assigneeName: '-',
              ),
              type: ProjectTaskListPage.qualityProjectTitle,
              onRefreshRequested: () async {},
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.projectQualityControl,
          builder: (_, _) => const Scaffold(body: Text('Detail QC')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStateProvider.overrideWith(
            (ref) => Stream.value(const ConnectivityState.online()),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ProjectTaskCardAction));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Aksi Selanjutnya'), findsNothing);
    expect(find.text('Detail QC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
