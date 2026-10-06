import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/presentation/controllers/meeting_action_controllers.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/detail/quality_meeting_review_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/detail/task_meeting_detail_page.dart';
import 'package:curva_mobile/shared/forms/form_submit_result.dart';

void main() {
  test('maps downstream QC result for a QC-passed work task', () {
    final task = MeetingTask.fromJson({
      'id': 'task-1',
      'status': 'qc_passed',
      'canSubmit': false,
      'downstreamQc': {
        'id': 'qc-1',
        'status': 'created',
        'qcNote': 'Perbaiki hasil pekerjaan',
        'evidence': [
          {
            'fileName': 'qc-result.jpg',
            'fileSizeBytes': 870329,
            'url': 'http://example.com/qc-result.jpg',
          },
        ],
      },
    });

    final data = MeetingTaskActionData.fromModel(
      task,
      meetingId: 'meeting-1',
      isQualityMeeting: false,
    );

    expect(data.showQcDetails, isTrue);
    expect(data.qcNote, 'Perbaiki hasil pekerjaan');
    expect(data.qcEvidence, hasLength(1));
    expect(data.qcEvidence.single.name, 'qc-result.jpg');
    expect(data.qcEvidence.single.path, 'http://example.com/qc-result.jpg');
    expect(data.qcEvidence.single.size, 870329);
  });

  test('shows downstream QC details for work task QC lifecycle statuses', () {
    MeetingTaskActionData dataFor(String status) =>
        MeetingTaskActionData.fromModel(
          MeetingTask.fromJson({'id': 'task-1', 'status': status}),
          meetingId: 'meeting-1',
          isQualityMeeting: false,
        );

    expect(dataFor('reopen').showQcDetails, isTrue);
    expect(dataFor('done').showQcDetails, isTrue);
    expect(dataFor('qc_passed').showQcDetails, isTrue);
    expect(dataFor('qc_failed').showQcDetails, isTrue);
    expect(dataFor('progress').showQcDetails, isFalse);
  });

  testWidgets('renders QC note and evidence section for a QC-passed task', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TaskMeetingDetailPage(
            data: MeetingTaskActionData(
              meetingId: '',
              taskId: '',
              isQualityMeeting: false,
              code: 'A',
              task: 'P A',
              project: 'Agung Project 1',
              creator: 'Agung Nugroho',
              createdDate: '27 Agu 2026',
              status: 'QC Passed',
              rawStatus: 'qc_passed',
              assignee: 'Agung Nugroho',
              updatedDate: '27 Agu 2026',
              previousEvidence: [],
              qcNote: 'Hasil QC task',
              canSubmit: false,
              qcEvidence: [],
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('Catatan QC', findRichText: true), findsOneWidget);
    expect(find.text('Hasil QC task'), findsOneWidget);
    expect(find.text('Bukti QC', findRichText: true), findsOneWidget);
    expect(find.text('Belum ada bukti QC'), findsNothing);
  });

  testWidgets('renders read-only quality review like project QC feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QualityMeetingReviewPage(
            data: MeetingTaskActionData(
              meetingId: '',
              taskId: '',
              isQualityMeeting: true,
              code: 'A',
              task: 'Quality task',
              project: 'Agung Project 1',
              creator: 'Agung Nugroho',
              createdDate: '28 Agu 2026',
              status: 'QC Passed',
              rawStatus: 'qc_passed',
              assignee: 'Agung Nugroho',
              updatedDate: '28 Agu 2026',
              previousEvidence: [],
              qcNote: 'Hasil quality review',
              canSubmit: false,
              qcEvidence: [],
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('Catatan QC', findRichText: true), findsOneWidget);
    expect(find.text('Hasil quality review'), findsOneWidget);
    expect(find.text('Bukti QC', findRichText: true), findsOneWidget);
    expect(find.text('Belum ada bukti QC'), findsNothing);
  });

  testWidgets('task meeting submit returns true to its caller', (tester) async {
    bool? didUpdate;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                didUpdate = await context.push<bool>('/detail');
              },
              child: const Text('Buka task'),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) =>
              TaskMeetingDetailPage(data: _submitData(isQualityMeeting: false)),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meetingTaskDoneControllerProvider.overrideWith(
            (ref, query) => _SuccessfulTaskDoneController(ref, query),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Buka task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajukan ke QC'));
    await tester.pumpAndSettle();

    expect(didUpdate, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('quality meeting submit returns true to its caller', (
    tester,
  ) async {
    bool? didUpdate;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                didUpdate = await context.push<bool>('/review');
              },
              child: const Text('Buka quality review'),
            ),
          ),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) => QualityMeetingReviewPage(
            data: _submitData(isQualityMeeting: true),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meetingQualityDecisionControllerProvider.overrideWith(
            (ref, query) => _SuccessfulQualityDecisionController(ref, query),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Buka quality review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setujui'));
    await tester.pumpAndSettle();

    expect(didUpdate, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}

class _SuccessfulTaskDoneController extends MeetingTaskDoneController {
  _SuccessfulTaskDoneController(super.ref, super.query);

  @override
  Future<FormSubmitResult> submit() async {
    return const FormSubmitSuccess('Task berhasil diajukan.');
  }
}

class _SuccessfulQualityDecisionController
    extends MeetingQualityDecisionController {
  _SuccessfulQualityDecisionController(super.ref, super.query);

  @override
  Future<FormSubmitResult> submit(String decision) async {
    return const FormSubmitSuccess('Keputusan QC berhasil dikirim.');
  }
}

MeetingTaskActionData _submitData({required bool isQualityMeeting}) {
  return MeetingTaskActionData(
    meetingId: '',
    taskId: '',
    isQualityMeeting: isQualityMeeting,
    code: 'A',
    task: 'Tugas meeting',
    project: 'Project A',
    creator: 'Admin',
    createdDate: '28 Agu 2026',
    status: 'In Progress',
    assignee: 'Staff',
    updatedDate: '28 Agu 2026',
    previousEvidence: const [],
  );
}
