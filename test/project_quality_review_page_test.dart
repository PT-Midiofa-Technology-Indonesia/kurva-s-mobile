import 'dart:async';

import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_task_action_controllers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_quality_review_history_tab.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_quality_review_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QC report fields survive serialization and handle missing notes', () {
    final task = ProjectTask.fromJson({
      'note': 'Arahan atasan',
      'workTask': {'note': 'Laporan manpower'},
      'createdAt': '2026-09-30T09:35:57+00:00',
      'completedVolume': 10,
      'uom': 'Meter Kubik',
    });
    final restored = ProjectTask.fromJson(task.toJson());
    final detail = ProjectTaskDetailData.fromTask(restored, isQc: true);
    expect(detail.supervisorNote, 'Arahan atasan');
    expect(detail.manpowerNote, 'Laporan manpower');
    expect(detail.reportedDate, '30 Sep 2026');
    expect(detail.completedVolume, '10 Meter Kubik');

    final empty = ProjectTaskDetailData.fromTask(
      ProjectTask.fromJson({
        'note': ' ',
        'workTask': {'note': null},
      }),
      isQc: true,
    );
    expect(empty.supervisorNote, '-');
    expect(empty.manpowerNote, '-');
    expect(empty.reportedDate, '-');
  });

  for (final hasUnread in [true, false, null]) {
    testWidgets('QC history dot follows hasUnread=$hasUnread', (tester) async {
      final status = Completer<bool>();
      var historyRequests = 0;
      final task = ProjectTask.fromJson({'id': 'qc-1', 'canSubmit': false});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAccountNameProvider.overrideWithValue('QC'),
            connectivityStateProvider.overrideWith(
              (ref) => const Stream<ConnectivityState>.empty(),
            ),
            projectQcTaskDetailProvider.overrideWith(
              (ref, query) => Stream.value(task),
            ),
            projectQcTaskHistoryProvider.overrideWith((ref, query) async {
              historyRequests++;
              return [];
            }),
            projectQcHistoryHasUnreadProvider.overrideWith((ref, query) {
              expect(query.projectId, 'project-1');
              expect(query.qcTaskId, 'qc-1');
              return status.future;
            }),
          ],
          child: MaterialApp(
            home: ProjectQualityReviewPage(
              detail: ProjectTaskDetailData.fromTask(
                task,
                isQc: true,
                fallbackProjectId: 'project-1',
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
      if (hasUnread == null) {
        status.completeError(Exception('offline'));
      } else {
        status.complete(hasUnread);
      }
      await tester.pumpAndSettle();
      expect(showsDot(), hasUnread == true);
      expect(historyRequests, 0);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(historyRequests, 1);
      expect(showsDot(), isFalse);
      await tester.tap(find.text('QC Review'));
      await tester.pumpAndSettle();
      expect(historyRequests, 1);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(historyRequests, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('QC Review menampilkan manpower, target, dan catatan tugas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final task = ProjectTask.fromJson({
      'code': 'C.01',
      'title': 'Pasangan Dinding Bata Ringan Lt 1',
      'status': 'waiting',
      'statusLabel': 'Menunggu',
      'canSubmit': false,
      'manpowerName': 'Budi Santoso',
      'targetVolume': 100,
      'completedVolume': 10,
      'uom': 'Meter Persegi',
      'note': 'hgjgjgj',
      'helpers': [
        {'id': 'helper-1', 'name': 'Budi'},
        {'id': 'helper-2', 'name': 'Andi'},
        {'id': 'helper-3', 'name': 'Siti'},
      ],
      'createdBy': 'Mobile Staff',
      'createdAt': '2026-09-24T12:53:35+00:00',
      'workTask': {
        'assignee': 'Budi Santoso',
        'createdBy': 'Mobile Staff',
        'note': 'Capaian pekerjaan manpower',
      },
    }, useWorkTaskPeople: true);
    final detail = ProjectTaskDetailData.fromTask(task, isQc: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccountNameProvider.overrideWithValue('Petugas QC'),
          connectivityStateProvider.overrideWith(
            (ref) => const Stream<ConnectivityState>.empty(),
          ),
        ],
        child: MaterialApp(home: ProjectQualityReviewPage(detail: detail)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Helper'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsNWidgets(2));
    expect(find.text('Budi +2'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('100 Meter Persegi'), findsOneWidget);
    expect(find.text('Catatan Atasan'), findsOneWidget);
    expect(find.text('hgjgjgj'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Catatan Manpower'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dilaporkan'), findsOneWidget);
    expect(find.text('Capaian'), findsOneWidget);
    expect(find.text('10 Meter Persegi'), findsOneWidget);
    expect(find.text('Capaian pekerjaan manpower'), findsOneWidget);
    expect(detail.reportedDate, detail.createdDate);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab History menyimpan input dan lampiran QC saat berpindah', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const detail = ProjectTaskDetailData(
      code: 'QC-01',
      task: 'Pengecoran',
      creator: 'Pelaksana',
      createdDate: '23 Sep 2026',
      status: 'Menunggu QC',
      assignee: 'Agung Prasetyo',
      updatedDate: '23 Sep 2026',
      previousEvidence: [],
      updatedEvidence: [],
      qcApproval: '-',
      qcUpdateDate: '-',
      qcStatus: '-',
      qcNote: '-',
      qcEvidence: [],
      canSubmitFromApi: true,
    );
    final container = ProviderContainer(
      overrides: [
        currentAccountNameProvider.overrideWithValue('Petugas QC'),
        connectivityStateProvider.overrideWith(
          (ref) => const Stream<ConnectivityState>.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProjectQualityReviewPage(detail: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('QC Review'), findsOneWidget);
    expect(find.text('Agung Prasetyo'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.byType(TextField),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Catatan pemeriksaan');
    container.read(projectQualityActionControllerProvider(detail)).addEvidence([
      const ProjectFileUpload(name: 'bukti.pdf', path: '/tmp/bukti.pdf'),
    ]);
    await tester.pump();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Belum Tersedia'), findsOneWidget);
    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);
    await tester.tap(find.text('QC Review'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan pemeriksaan'), findsOneWidget);
    expect(find.text('Setujui'), findsOneWidget);
    expect(
      container
          .read(projectQualityActionControllerProvider(detail))
          .selectedEvidence
          .single
          .name,
      'bukti.pdf',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('History QC menampilkan keputusan dan dokumen dari provider', (
    tester,
  ) async {
    const query = ProjectTaskQuery(projectId: 'project-1', taskId: 'qc-task-1');
    const history = ProjectTaskHistoryEntry(
      projectTaskId: 'qc-task-1',
      actor: ProjectReference(id: 'qc-1', name: 'QC Inspector'),
      note: 'Pekerjaan belum rata',
      completedVolume: null,
      targetVolume: null,
      uom: '',
      documents: [
        ProjectTaskHistoryDocument(
          id: 'document-1',
          documentType: ProjectDocumentType(
            id: 'type-1',
            code: 'QC_EVIDENCE',
            name: 'Bukti QC',
          ),
          fileName: 'retak_permukaan.jpg',
          filePath: '',
          url: '',
          fileSize: 1024000,
          mimeType: 'image/jpeg',
          uploadedAt: '2026-09-23T11:00:00+07:00',
        ),
      ],
      recordedAt: '2026-09-23T11:00:00+07:00',
      event: 'qc_decision',
      eventLabel: 'QC menolak tugas',
      decision: ProjectTaskHistoryDecision(value: 'rejected', label: 'Ditolak'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectQcTaskHistoryProvider(
            query,
          ).overrideWith((ref) async => const [history]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProjectQualityReviewHistoryTab(
              manpowerName: 'Pelaksana',
              projectId: 'project-1',
              qcTaskId: 'qc-task-1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Riwayat Laporan'), findsOneWidget);
    expect(find.text('QC menolak tugas'), findsOneWidget);
    expect(find.text('QC Inspector'), findsOneWidget);
    expect(find.text('Keputusan QC'), findsOneWidget);
    expect(find.text('Ditolak'), findsOneWidget);
    expect(find.text('Pekerjaan belum rata'), findsOneWidget);
    expect(find.text('retak_permukaan.jpg'), findsOneWidget);

    await tester.tap(find.text('QC menolak tugas'));
    await tester.pump();
    expect(find.text('Ditolak'), findsNothing);
  });
}
