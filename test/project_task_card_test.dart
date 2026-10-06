import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/project/presentation/widgets/project_task_card.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_task_list_page.dart';

void main() {
  for (final retryCount in [0, 3]) {
    testWidgets('Quality Project shows retry $retryCount before note', (
      tester,
    ) async {
      final task = ProjectTask.fromJson({
        'id': 'qc-task',
        'title': 'QC Inspeksi',
        'retryCount': retryCount,
        'note': 'Catatan pekerjaan',
      });
      final cardData = ProjectTaskListItemData.fromTask(
        task,
        fallbackProjectId: 'project',
        isQc: true,
      ).toProjectMenuTaskData(type: 'Quality Project');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectTaskCard(task: cardData)),
        ),
      );
      expect(find.text('${retryCount}x'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('${retryCount}x')).dy,
        lessThan(tester.getTopLeft(find.text('Catatan pekerjaan')).dy),
      );
      expect(
        tester.getCenter(find.byIcon(Icons.sync)).dy,
        tester.getCenter(find.byKey(const Key('qc-target-icon'))).dy,
      );
      expect(
        tester.getTopLeft(find.byIcon(Icons.sync)).dx,
        greaterThan(
          tester.getTopLeft(find.byKey(const Key('qc-target-icon'))).dx,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows progress and last update when child count is zero', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(childCount: 0));

    expect(find.byIcon(Icons.account_tree_outlined), findsNothing);
    expect(find.byKey(const Key('task-progress-target-icon')), findsOneWidget);
    expect(find.text('0/10 m³'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.text('19 Sep 2026'), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsNothing);
  });

  testWidgets('shows child count when child count is positive', (tester) async {
    await tester.pumpWidget(_testApp(childCount: 3));

    expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byKey(const Key('task-progress-target-icon')), findsNothing);
    expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);
  });

  testWidgets('shows assignee name only when there is one assignee', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        childCount: 0,
        assigneeName: 'Siti Rahayu',
        assignees: const [
          ProjectMenuAssigneeData(initials: 'SR', color: Colors.blue),
        ],
      ),
    );

    expect(find.text('Siti Rahayu'), findsOneWidget);
    expect(find.text('1 Personil'), findsNothing);
  });

  testWidgets('shows personnel count when there are multiple assignees', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        childCount: 0,
        assigneeName: 'Siti Rahayu',
        assignees: const [
          ProjectMenuAssigneeData(initials: 'SR', color: Colors.blue),
          ProjectMenuAssigneeData(initials: 'AN', color: Colors.green),
          ProjectMenuAssigneeData(initials: 'BP', color: Colors.orange),
        ],
      ),
    );

    expect(find.text('3 Personil'), findsOneWidget);
    expect(find.text('Siti Rahayu'), findsNothing);
  });

  testWidgets('Quality Project shows status, manpower, target, and note', (
    tester,
  ) async {
    const longNote =
        'Catatan quality project yang sangat panjang dan harus dipotong dalam satu baris';
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _testApp(
        childCount: 0,
        type: 'Quality Project',
        status: 'Menunggu',
        manpowerName: 'Budi Santoso',
        target: '100 m²',
        note: longNote,
      ),
    );

    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.byKey(const Key('qc-target-icon')), findsOneWidget);
    expect(find.text('100 m²'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    final note = tester.widget<Text>(find.text(longNote));
    expect(note.maxLines, 1);
    expect(note.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);
    expect(
      tester.getCenter(find.text('Menunggu')).dy,
      tester.getCenter(find.text('Budi Santoso')).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('qc-target-icon'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('task-status-badge'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('qc-target-icon'))).dx,
      tester.getTopLeft(find.byKey(const Key('task-status-badge'))).dx,
    );
  });
}

Widget _testApp({
  required int childCount,
  List<ProjectMenuAssigneeData> assignees = const [],
  String assigneeName = '-',
  String type = 'Task Project',
  String status = 'Proses',
  String manpowerName = '-',
  String target = '-',
  String note = '-',
}) {
  return MaterialApp(
    home: Scaffold(
      body: ProjectTaskCard(
        task: ProjectMenuTaskData(
          code: 'A.1',
          title: 'Pekerjaan Civil',
          assignees: assignees,
          assigneeName: assigneeName,
          childCount: childCount,
          status: status,
          type: type,
          manpowerName: manpowerName,
          target: target,
          note: note,
        ),
      ),
    ),
  );
}
