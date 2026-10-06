import 'dart:async';

import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_report_page.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  for (final hasUnread in [true, false, null]) {
    testWidgets('manpower history dot follows hasUnread=$hasUnread', (
      tester,
    ) async {
      final status = Completer<bool>();
      var historyRequests = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectTaskHistoryProvider.overrideWith((ref, query) async {
              historyRequests++;
              return _history;
            }),
            projectManpowerHistoryHasUnreadProvider.overrideWith((ref, query) {
              expect(query.projectId, 'project-1');
              expect(query.manpowerTaskId, 'manpower-task-1');
              return status.future;
            }),
          ],
          child: const MaterialApp(
            home: ProjectManpowerReportPage(
              projectId: 'project-1',
              taskId: 'manpower-task-1',
              manpowerName: 'Test',
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
      await tester.tap(find.text('Laporan Harian'));
      await tester.pumpAndSettle();
      expect(historyRequests, 1);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(historyRequests, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('menampilkan form laporan dan validasi field wajib', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 870);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProjectManpowerReportPage(manpowerName: 'Agung Prasetyo'),
        ),
      ),
    );

    expect(find.text('Agung Prasetyo'), findsOneWidget);
    expect(
      find.textContaining('Tanggal Laporan', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Input Target', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('Catatan Kegiatan', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Update bukti', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Ajukan ke QC'));
    await tester.pump();

    expect(find.text('Masukkan target lebih dari 0'), findsOneWidget);
    expect(find.text('Catatan kegiatan wajib diisi'), findsOneWidget);
    await tester.ensureVisible(find.text('Bukti laporan wajib ditambahkan'));
    expect(find.text('Bukti laporan wajib ditambahkan'), findsOneWidget);
  });

  testWidgets(
    'tab History menampilkan timeline yang dapat dibuka dan ditutup',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectManpowerHistoryHasUnreadProvider.overrideWith(
              (ref, query) async => false,
            ),
            projectTaskHistoryProvider(
              const ProjectTaskQuery(
                projectId: 'project-1',
                taskId: 'manpower-task-1',
              ),
            ).overrideWith((ref) async => _history),
          ],
          child: const MaterialApp(
            home: ProjectManpowerReportPage(
              projectId: 'project-1',
              taskId: 'manpower-task-1',
              manpowerName: 'Agung Prasetyo',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '2,5');
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Laporan'), findsOneWidget);
      expect(find.text('Tugas diajukan ke QC'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration! as BoxDecoration).color == AppColors.error,
        ),
        findsOneWidget,
      );
      expect(find.text('Ajukan ke QC'), findsNothing);
      expect(find.text('Pekerjaan sesuai spesifikasi'), findsOneWidget);
      expect(find.text('2 M2 dari target 10 M2'), findsOneWidget);
      expect(find.text('qc_check.jpg'), findsOneWidget);
      await tester.tap(find.text('Tugas diajukan ke QC'));
      await tester.pump();
      expect(find.text('Pekerjaan sesuai spesifikasi'), findsNothing);
      await tester.tap(find.text('Tugas diajukan ke QC'));
      await tester.pump();
      expect(find.text('Pekerjaan sesuai spesifikasi'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Laporan diperbarui'), 300);
      await tester.pumpAndSettle();
      expect(find.text('Laporan diperbarui'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Laporan Harian'));
      await tester.pumpAndSettle();
      expect(find.text('2,5'), findsOneWidget);
      expect(find.text('Ajukan ke QC'), findsOneWidget);
    },
  );

  testWidgets('tab History menampilkan empty state saat data kosong', (
    tester,
  ) async {
    const query = ProjectTaskQuery(
      projectId: 'project-1',
      taskId: 'manpower-task-1',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectManpowerHistoryHasUnreadProvider.overrideWith(
            (ref, query) async => false,
          ),
          projectTaskHistoryProvider(
            query,
          ).overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: ProjectManpowerReportPage(
            projectId: 'project-1',
            taskId: 'manpower-task-1',
            manpowerName: 'Agung Prasetyo',
          ),
        ),
      ),
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Data'), findsOneWidget);
    expect(
      find.text('Belum ada aktivitas laporan untuk task ini.'),
      findsOneWidget,
    );
    expect(find.text('Riwayat Laporan'), findsNothing);
  });

  testWidgets('aksi submit disembunyikan saat respons tidak mengizinkan', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProjectManpowerReportPage(
            manpowerName: 'Andi Wijaya',
            canSubmit: false,
          ),
        ),
      ),
    );

    expect(find.text('Ajukan ke QC'), findsNothing);
    expect(find.text('Laporan Harian'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}

const _history = [
  ProjectTaskHistoryEntry(
    projectTaskId: 'qc-task-1',
    actor: ProjectReference(id: 'qc-1', name: 'QC Inspector'),
    note: 'Pekerjaan sesuai spesifikasi',
    completedVolume: 2,
    targetVolume: 10,
    uom: 'M2',
    documents: [
      ProjectTaskHistoryDocument(
        id: 'document-1',
        documentType: ProjectDocumentType(
          id: 'document-type-1',
          code: 'QC_EVIDENCE',
          name: 'Bukti QC',
        ),
        fileName: 'qc_check.jpg',
        filePath: 'tasks/qc_check.jpg',
        url: '',
        fileSize: 1024000,
        mimeType: 'image/jpeg',
        uploadedAt: '2026-09-22T11:00:00+07:00',
      ),
    ],
    recordedAt: '2026-09-22T11:00:00+07:00',
    event: 'submitted_to_qc',
    eventLabel: 'Tugas diajukan ke QC',
    decision: ProjectTaskHistoryDecision(value: 'rejected', label: 'Ditolak'),
  ),
  ProjectTaskHistoryEntry(
    projectTaskId: 'work-task-1',
    actor: ProjectReference(id: 'employee-1', name: 'Budi Santoso'),
    note: 'Sudah dikerjakan',
    completedVolume: 3.5,
    targetVolume: 10,
    uom: 'M2',
    documents: [],
    recordedAt: '2026-09-22T09:30:00+07:00',
    event: 'report_updated',
    eventLabel: 'Laporan diperbarui',
  ),
];
