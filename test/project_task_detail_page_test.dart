import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_report_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_assignee_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/widgets/project_manpower_form_bottom_sheet.dart';
import 'package:curva_mobile/modules/project/presentation/widgets/project_target_icon.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  testWidgets('picker manpower memuat subordinate sesuai project', (
    tester,
  ) async {
    String? requestedProjectId;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSubordinatesProvider.overrideWith((ref, projectId) {
            requestedProjectId = projectId;
            return Stream.value(const [
              ProjectReference(id: 'employee-1', name: 'Siti Aminah'),
              ProjectReference(id: 'employee-2', name: 'Budi Santoso'),
            ]);
          }),
        ],
        child: const MaterialApp(
          home: ProjectManpowerAssigneePickerPage(projectId: 'project-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedProjectId, 'project-1');
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Siti');
    await tester.pump();
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsNothing);
  });

  testWidgets('task dengan child menampilkan detail parent', (tester) async {
    await _pumpPage(
      tester,
      ProjectTaskDetailData.sample(
        code: 'A',
        task: 'Pekerjaan struktur',
        childCount: 2,
      ),
    );

    expect(find.text('Job/Item'), findsOneWidget);
    expect(find.text('Assign'), findsOneWidget);
    expect(find.text('Progres'), findsOneWidget);
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Manpower', findRichText: true), findsNothing);
    expect(find.text('Add Manpower'), findsNothing);
  });

  testWidgets('task tanpa child menampilkan detail leaf dan manpower', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      ProjectTaskDetailData.sample(code: 'A.1.1', task: 'Pekerjaan pondasi'),
    );

    expect(find.text('Durasi'), findsOneWidget);
    expect(find.text('5 hari'), findsOneWidget);
    expect(find.text('Volume BOQ'), findsOneWidget);
    expect(find.text('10 m³'), findsOneWidget);
    expect(find.text('Progress saat ini'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Manpower', findRichText: true), findsOneWidget);
    expect(find.text('Agung Prasetyo'), findsOneWidget);
    expect(find.text('Arish Noah'), findsOneWidget);
    expect(find.text('Dimas Masdim'), findsOneWidget);
    expect(find.text('Belum Dilaporkan'), findsNWidgets(3));
    expect(find.text('Budi, 2+'), findsOneWidget);
    expect(find.text('Yugi'), findsOneWidget);
    expect(find.text('Yugo'), findsOneWidget);
    expect(find.text('5 m³'), findsOneWidget);
    expect(find.text('3 m³'), findsOneWidget);
    expect(find.text('2 m³'), findsOneWidget);
    expect(find.text('Sebelah Kanan'), findsOneWidget);
    expect(find.text('Sebelah Kiri'), findsOneWidget);
    expect(find.text('Bagian Depan'), findsOneWidget);
    expect(find.text('Add Manpower'), findsOneWidget);
  });

  testWidgets('detail API menampilkan nilai aktual dan empty state manpower', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'code': 'C.01',
      'title': 'Pasangan Dinding Bata Ringan Lt 1',
      'status': 'created',
      'statusLabel': 'Created',
      'canAssign': true,
      'canAssignDraft': true,
      'isDraft': true,
      'isFinalLevel': true,
      'volumeBoq': 150,
      'currentProgress': 0,
      'maxTargetVolume': 150,
      'uom': {'code': 'M2', 'name': 'Meter Persegi'},
      'durationDays': 11,
      'manpower': <Object?>[],
      'createdAt': '2026-09-24T01:48:19+00:00',
    });

    await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));

    expect(
      find.text('C.01 · Pasangan Dinding Bata Ringan Lt 1'),
      findsOneWidget,
    );
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('11 hari'), findsOneWidget);
    expect(find.text('150 M2'), findsOneWidget);
    expect(find.text('0/150 M2'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.group_outlined), findsOneWidget);
    expect(
      find.text(
        'Anda belum menambahkan\n'
        'manpower,silahkan tambah manpower\n'
        'untuk assignee tugas',
      ),
      findsOneWidget,
    );
    expect(find.text('Agung Prasetyo'), findsNothing);
    expect(find.text('Add Manpower'), findsOneWidget);
  });

  testWidgets('non-draft tanpa manpower dapat membuka form tambah', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'isDraft': false,
      'isFinalLevel': true,
      'canAssignDraft': true,
      'volumeBoq': 10,
      'maxTargetVolume': 10,
      'manpower': <Object?>[],
    });
    await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));
    expect(find.text('Add Manpower'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Assignee'), findsNothing);

    await tester.tap(find.text('Add Manpower'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectManpowerAssigneePickerPage), findsOneWidget);
    await tester.tap(find.text('Agung Prasetyo'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectManpowerFormBottomSheet), findsOneWidget);
  });

  testWidgets('aksi manpower mengikuti canAssignDraft, bukan canAssign', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'code': 'C.01',
      'title': 'Pekerjaan tanpa izin draft',
      'status': 'created',
      'statusLabel': 'Created',
      'canAssign': true,
      'canAssignDraft': false,
      'isDraft': true,
      'isFinalLevel': true,
      'volumeBoq': 10,
      'maxTargetVolume': 10,
      'manpower': [
        {
          'id': 'manpower-1',
          'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
          'targetVolume': 5,
          'canDelete': true,
        },
      ],
    });

    await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));

    expect(task.canAssign, isTrue);
    expect(task.canAssignDraft, isFalse);
    expect(find.text('Add Manpower'), findsNothing);
    expect(find.text('Assignee'), findsNothing);
  });

  testWidgets('detail API menampilkan kartu manpower dari respons', (
    tester,
  ) async {
    const longNote =
        'Catatan manpower yang sangat panjang dan harus dipotong dalam satu baris';
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'code': 'C.01',
      'title': 'Pasangan Dinding Bata Ringan Lt 1',
      'status': 'created',
      'statusLabel': 'Created',
      'canAssign': true,
      'canAssignDraft': true,
      'isDraft': true,
      'isFinalLevel': true,
      'volumeBoq': 150,
      'currentProgress': 0,
      'maxTargetVolume': 140,
      'uom': {'code': 'M2', 'name': 'Meter Persegi'},
      'durationDays': 11,
      'retryCount': 9,
      'manpower': [
        {
          'id': 'manpower-1',
          'employee': {
            'id': 'employee-1',
            'name': 'Andi Wijaya',
            'code': 'EMP-MOBILE-04',
          },
          'helpers': [
            {'id': 'helper-1', 'name': 'Budi Santoso', 'code': 'EMP-MOBILE-03'},
          ],
          'targetVolume': 10,
          'completedVolume': 0,
          'status': 'created',
          'statusLabel': 'Created',
          'isRevision': false,
          'retryCount': 3,
          'canDelete': true,
          'note': longNote,
          'assignDate': '2026-09-24',
        },
      ],
    });

    await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.group_outlined), findsNothing);
    expect(find.text('Andi Wijaya'), findsOneWidget);
    expect(find.text('AW'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('10 M2'), findsOneWidget);
    expect(find.text('3x'), findsOneWidget);
    expect(find.text('9x'), findsNothing);
    expect(task.manpower.single.toJson()['retryCount'], 3);
    expect(find.byType(ProjectTargetIcon), findsOneWidget);
    final note = tester.widget<Text>(find.text(longNote));
    expect(note.maxLines, 1);
    expect(note.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
    expect(find.text('Created'), findsNWidgets(2));
    expect(find.byIcon(CupertinoIcons.delete), findsOneWidget);
    expect(find.byTooltip('Hapus manpower Andi Wijaya'), findsOneWidget);
  });

  testWidgets(
    'Add Manpower disembunyikan saat seluruh volume BOQ sudah dialokasikan',
    (tester) async {
      final task = ProjectTask.fromJson({
        'id': 'task-1',
        'code': 'C.01',
        'title': 'Pasangan Dinding Bata Ringan Lt 1',
        'status': 'created',
        'statusLabel': 'Created',
        'canAssign': true,
        'canAssignDraft': true,
        'isDraft': true,
        'isFinalLevel': true,
        'volumeBoq': 10,
        // The latest response can still return a positive max target even
        // though all BOQ volume has already been allocated.
        'maxTargetVolume': 10,
        'uom': {'code': 'M2'},
        'manpower': [
          {
            'id': 'manpower-1',
            'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
            'helpers': <Object?>[],
            'targetVolume': 10,
            'completedVolume': 0,
            'status': 'created',
            'statusLabel': 'Created',
            'isRevision': false,
            'canDelete': true,
          },
        ],
      });

      await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));

      expect(find.text('Add Manpower'), findsNothing);
      expect(find.text('Assignee'), findsOneWidget);
      expect(ProjectTaskDetailData.fromTask(task).availableTargetVolume, 0);
    },
  );

  testWidgets('detail mengikuti daftar manpower pada respons terbaru', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'code': 'C.01',
      'title': 'Pasangan Dinding Bata Ringan Lt 1',
      'status': 'created',
      'statusLabel': 'Created',
      'canSubmit': true,
      'canAssign': true,
      'canAssignDraft': true,
      'isDraft': true,
      'taskType': 'work',
      'isFinalLevel': true,
      'volumeBoq': 150,
      'currentProgress': 0,
      'maxTargetVolume': 10,
      'uom': {'code': 'M2', 'name': 'Meter Persegi'},
      'durationDays': 11,
      'manpower': [
        {
          'id': 'manpower-1',
          'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
          'helpers': [
            {'id': 'helper-1', 'name': 'Budi Santoso'},
            {'id': 'helper-2', 'name': 'Siti Rahayu'},
          ],
          'targetVolume': 10,
          'completedVolume': 2,
          'status': 'qc_waiting',
          'statusLabel': 'Menunggu QC',
          'canDelete': false,
          'canSubmit': false,
          'note': 'tes',
        },
        {
          'id': 'manpower-2',
          'employee': {'id': 'employee-2', 'name': 'Budi Santoso'},
          'helpers': <Object?>[],
          'targetVolume': 100,
          'completedVolume': 0,
          'status': 'in_progress',
          'statusLabel': 'Progress',
          'canDelete': false,
          'canSubmit': true,
          'note': 'tes2',
        },
        {
          'id': 'manpower-3',
          'employee': {'id': 'employee-3', 'name': 'QC Inspector'},
          'helpers': [
            {'id': 'helper-2', 'name': 'Siti Rahayu'},
            {'id': 'helper-1', 'name': 'Budi Santoso'},
          ],
          'targetVolume': 40,
          'completedVolume': 0,
          'status': 'in_progress',
          'statusLabel': 'Progress',
          'canDelete': false,
          'canSubmit': true,
          'note': 'tes 3',
        },
      ],
      'assignee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
      'childCount': 0,
      'createdBy': 'Mobile Staff',
      'createdAt': '2026-09-24T01:48:19+00:00',
    });

    await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));

    expect(find.text('0/150 M2'), findsOneWidget);
    expect(find.text('Add Manpower'), findsNothing);
    await tester.scrollUntilVisible(find.text('QC Inspector'), 300);
    expect(find.text('Andi Wijaya'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('QC Inspector'), findsOneWidget);
    expect(find.text('Menunggu QC'), findsOneWidget);
    expect(find.text('Progress'), findsNWidgets(2));
    expect(find.text('10 M2'), findsOneWidget);
    expect(find.text('100 M2'), findsOneWidget);
    expect(find.text('40 M2'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.delete), findsNothing);
  });

  testWidgets('hapus manpower meminta konfirmasi lalu memuat ulang detail', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'projectId': 'project-1',
      'code': 'C.01',
      'title': 'Pasangan Dinding Bata Ringan Lt 1',
      'status': 'created',
      'statusLabel': 'Created',
      'canAssign': true,
      'canAssignDraft': true,
      'isDraft': true,
      'isFinalLevel': true,
      'volumeBoq': 150,
      'maxTargetVolume': 140,
      'uom': {'code': 'M2'},
      'manpower': [
        {
          'id': 'manpower-1',
          'employee': {
            'id': 'employee-1',
            'name': 'Andi Wijaya',
            'code': 'EMP-MOBILE-04',
          },
          'helpers': <Object?>[],
          'targetVolume': 10,
          'completedVolume': 0,
          'status': 'created',
          'statusLabel': 'Created',
          'isRevision': false,
          'canDelete': true,
          'note': 'tes',
          'assignDate': '2026-09-24',
        },
      ],
    });
    final repository = _FakeProjectRepository(detailTask: task);

    await _pumpPage(
      tester,
      ProjectTaskDetailData.fromTask(task),
      repository: repository,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Hapus manpower Andi Wijaya'));

    await tester.tap(find.byTooltip('Hapus manpower Andi Wijaya'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus manpower Andi Wijaya?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(repository.deletedManpowerTaskId, isNull);

    await tester.tap(find.byTooltip('Hapus manpower Andi Wijaya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, hapus'));
    await tester.pump();
    expect(repository.deletedProjectId, 'project-1');
    expect(repository.deletedTaskId, 'task-1');
    expect(repository.deletedManpowerTaskId, 'manpower-1');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repository.fetchDetailCount, greaterThanOrEqualTo(2));
    expect(find.byTooltip('Hapus manpower Andi Wijaya'), findsNothing);
    expect(find.byIcon(Icons.group_outlined), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'draft manpower menampilkan aksi assignee dan refresh setelah berhasil',
    (tester) async {
      final task = ProjectTask.fromJson({
        'id': 'task-1',
        'projectId': 'project-1',
        'code': 'C.01',
        'title': 'Pasangan Dinding Bata Ringan Lt 1',
        'status': 'created',
        'statusLabel': 'Created',
        'canAssign': true,
        'canAssignDraft': true,
        'isDraft': true,
        'isFinalLevel': true,
        'volumeBoq': 150,
        'maxTargetVolume': 140,
        'uom': {'code': 'M2'},
        'manpower': [
          {
            'id': 'manpower-1',
            'employee': {
              'id': 'employee-1',
              'name': 'Andi Wijaya',
              'code': 'EMP-MOBILE-04',
            },
            'helpers': <Object?>[],
            'targetVolume': 10,
            'completedVolume': 0,
            'status': 'created',
            'statusLabel': 'Created',
            'isRevision': false,
            'canDelete': true,
            'note': 'tes',
            'assignDate': '2026-09-24',
          },
        ],
      });
      final repository = _FakeProjectRepository(detailTask: task);

      await _pumpPage(
        tester,
        ProjectTaskDetailData.fromTask(task),
        repository: repository,
      );
      await tester.pumpAndSettle();

      final addButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Add Manpower'),
      );
      expect(addButton.variant, AppButtonVariant.outlined);
      expect(find.text('Assignee'), findsOneWidget);

      await tester.tap(find.text('Assignee'));
      await tester.pumpAndSettle();
      expect(find.text('Assign manpower ke task ini?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(repository.delegatedTaskId, isNull);

      await tester.tap(find.text('Assignee'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, assign'));
      await tester.pump();
      expect(repository.delegatedProjectId, 'project-1');
      expect(repository.delegatedTaskId, 'task-1');

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(repository.fetchDetailCount, greaterThanOrEqualTo(2));
      expect(find.text('Assignee'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('respons error assignee tetap menutup mode edit', (tester) async {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'projectId': 'project-1',
      'isDraft': true,
      'isFinalLevel': true,
      'canAssignDraft': true,
      'volumeBoq': 10,
      'maxTargetVolume': 5,
      'manpower': [
        {
          'id': 'manpower-1',
          'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
          'targetVolume': 5,
          'canDelete': true,
        },
      ],
    });
    final repository = _FakeProjectRepository(detailTask: task)
      ..delegateManpowerError = StateError('Gagal assign');

    await _pumpPage(
      tester,
      ProjectTaskDetailData.fromTask(task),
      repository: repository,
    );
    await tester.pumpAndSettle();
    expect(find.text('Assignee'), findsOneWidget);

    await tester.tap(find.text('Assignee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, assign'));
    await tester.pumpAndSettle();

    expect(repository.delegatedTaskId, 'task-1');
    expect(find.text('Assignee'), findsNothing);
    expect(find.text('Add Manpower'), findsNothing);
    expect(find.byTooltip('Hapus manpower Andi Wijaya'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  for (final isDraft in [false, true]) {
    testWidgets('mode edit dari API isDraft=$isDraft dan edit manpower', (
      tester,
    ) async {
      final task = ProjectTask.fromJson({
        'id': 'task-1',
        'projectId': 'project-1',
        'title': 'Pondasi',
        'isFinalLevel': true,
        'canAssignDraft': true,
        'isDraft': isDraft,
        'volumeBoq': 10,
        'maxTargetVolume': 0,
        'manpower': [
          {
            'id': 'manpower-1',
            'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
            'targetVolume': 10,
            'canDelete': true,
            'note': 'Catatan lama',
            'helpers': [
              {'id': 'helper-1', 'name': 'Budi', 'code': 'EMP010'},
            ],
          },
        ],
      });
      final repository = _FakeProjectRepository(detailTask: task);
      // The API response must also initialize mode when navigation has no draft flag.
      final initial = ProjectTask.fromJson(task.toJson()..['isDraft'] = false);
      await _pumpPage(
        tester,
        ProjectTaskDetailData.fromTask(initial),
        repository: repository,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Andi Wijaya'));
      if (!isDraft) {
        expect(find.text('Add Manpower'), findsNothing);
        expect(find.text('Assignee'), findsNothing);
        expect(find.byTooltip('Hapus manpower Andi Wijaya'), findsNothing);
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Add Manpower'), findsNothing);
      expect(find.text('Assignee'), findsOneWidget);
      expect(find.byTooltip('Hapus manpower Andi Wijaya'), findsOneWidget);
      await tester.tap(find.text('Andi Wijaya'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectManpowerAssigneePickerPage), findsOneWidget);
      expect(find.byType(ProjectManpowerFormBottomSheet), findsNothing);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectManpowerFormBottomSheet), findsNothing);
      expect(repository.updatedManpowerTaskId, isNull);

      await tester.tap(find.text('Andi Wijaya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arish Noah'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectManpowerFormBottomSheet), findsOneWidget);
      expect(
        tester
            .widget<ProjectManpowerFormBottomSheet>(
              find.byType(ProjectManpowerFormBottomSheet),
            )
            .assignee
            .id,
        'employee-2',
      );
      expect(find.text('10'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(ProjectManpowerFormBottomSheet),
          matching: find.text('Catatan lama'),
        ),
        findsOneWidget,
      );
      expect(find.text('Budi'), findsWidgets);
      await tester.enterText(find.byType(TextFormField), '11');
      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Target maksimal 10 m³'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '8');
      await tester.enterText(
        find.widgetWithText(TextField, 'Catatan lama'),
        'Catatan baru',
      );
      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(repository.updatedManpowerTaskId, 'manpower-1');
      expect(repository.employeeId, 'employee-2');
      expect(repository.target, 8);
      expect(repository.helperEmployeeIds, ['helper-1']);
      expect(repository.note, 'Catatan baru');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(repository.fetchDetailCount, greaterThanOrEqualTo(2));
      // A refresh must preserve edit mode when isDraft is still false.
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Assignee'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('tanpa draft yang bisa dihapus tidak tersedia tombol Edit', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'isDraft': false,
      'isFinalLevel': true,
      'canAssignDraft': true,
      'manpower': [
        {
          'id': 'manpower-1',
          'canDelete': false,
          'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
        },
      ],
    });
    await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Add Manpower'), findsNothing);
    expect(find.text('Assignee'), findsNothing);
    expect(find.byIcon(CupertinoIcons.delete), findsNothing);
  });

  testWidgets(
    'mode edit menonaktifkan dan mengabukan card yang tidak dapat dihapus',
    (tester) async {
      final task = ProjectTask.fromJson({
        'isDraft': true,
        'isFinalLevel': true,
        'canAssignDraft': true,
        'manpower': [
          {
            'id': 'manpower-1',
            'canDelete': false,
            'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
          },
        ],
      });

      await _pumpPage(tester, ProjectTaskDetailData.fromTask(task));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Material && widget.color == const Color(0xFFF3F4F6),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Hapus manpower Andi Wijaya'), findsNothing);

      await tester.tap(find.text('Andi Wijaya'));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectManpowerFormBottomSheet), findsNothing);
      expect(find.byType(ProjectManpowerReportPage), findsNothing);
    },
  );

  testWidgets('kartu manpower membuka halaman laporan sesuai nama', (
    tester,
  ) async {
    final detail = ProjectTaskDetailData.sample(
      code: 'A.1.1',
      task: 'Pekerjaan pondasi',
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ProjectTaskDetailPage(detail: detail),
        ),
        GoRoute(
          path: RouteNames.projectManpowerReport,
          builder: (context, state) =>
              ProjectManpowerReportPage(manpowerName: state.extra! as String),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Agung Prasetyo'));
    await tester.tap(find.text('Agung Prasetyo'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectManpowerReportPage), findsOneWidget);
    expect(find.text('Agung Prasetyo'), findsOneWidget);
    expect(find.text('Laporan Harian'), findsOneWidget);
    expect(find.text('Ajukan ke QC'), findsOneWidget);
  });

  testWidgets('submit laporan manpower me-refresh detail setelah 1 detik', (
    tester,
  ) async {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'projectId': 'project-1',
      'code': 'C.01',
      'title': 'Pasangan Dinding',
      'status': 'created',
      'statusLabel': 'Created',
      'isFinalLevel': true,
      'volumeBoq': 10,
      'maxTargetVolume': 5,
      'manpower': [
        {
          'id': 'manpower-1',
          'employee': {'id': 'employee-1', 'name': 'Andi Wijaya'},
          'targetVolume': 5,
          'status': 'created',
          'statusLabel': 'Created',
          'canSubmit': true,
        },
      ],
    });
    final repository = _FakeProjectRepository(detailTask: task);
    final detail = ProjectTaskDetailData.fromTask(
      task,
      fallbackProjectId: 'project-1',
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ProjectTaskDetailPage(detail: detail),
        ),
        GoRoute(
          path: RouteNames.projectManpowerReport,
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Submit berhasil'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.fetchDetailCount, 1);

    await tester.ensureVisible(find.text('Andi Wijaya'));
    await tester.tap(find.text('Andi Wijaya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit berhasil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 999));
    expect(repository.fetchDetailCount, 1);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(repository.fetchDetailCount, greaterThanOrEqualTo(2));
  });

  testWidgets('memilih manpower melalui halaman pencarian sebelum form', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      ProjectTaskDetailData.sample(code: 'A.1', task: 'Pondasi'),
    );

    await tester.tap(find.text('Add Manpower'));
    await tester.pumpAndSettle();
    expect(find.text('Add Manpower'), findsOneWidget);
    expect(find.text('Agung Prasetyo'), findsOneWidget);
    expect(find.text('Arish Noah'), findsOneWidget);
    expect(find.text('Dimas Masdim'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Arish');
    await tester.pump();
    expect(find.text('Agung Prasetyo'), findsNothing);
    expect(find.text('Arish Noah'), findsOneWidget);
    expect(find.text('Dimas Masdim'), findsNothing);

    await tester.tap(find.text('Arish Noah'));
    await tester.pumpAndSettle();
    expect(find.text('Lengkapi Data'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProjectManpowerFormBottomSheet),
        matching: find.text('Arish Noah'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('manpower memvalidasi target dan mengirim data ke repository', (
    tester,
  ) async {
    final repository = _FakeProjectRepository();
    await _pumpPage(
      tester,
      ProjectTaskDetailData.sample(code: 'A.1', task: 'Pondasi'),
      repository: repository,
    );
    await tester.tap(find.text('Add Manpower'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectManpowerAssigneePickerPage), findsOneWidget);
    await tester.tap(find.text('Agung Prasetyo'));
    await tester.pumpAndSettle();
    expect(find.text('Lengkapi Data'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProjectManpowerFormBottomSheet),
        matching: find.text('Agung Prasetyo'),
      ),
      findsOneWidget,
    );
    expect(find.byType(InputChip), findsNothing);
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan target lebih dari 0'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '11');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Target maksimal 10 m³'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '2,5');
    await tester.tap(find.text('Pilih Helper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus Budi'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);
    await tester.tap(find.text('Pilih Helper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Type your message here.'),
      'Catatan dummy',
    );
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectManpowerFormBottomSheet), findsNothing);
    expect(repository.employeeId, 'employee-1');
    expect(repository.target, 2.5);
    expect(repository.helperEmployeeIds, ['helper-1']);
    expect(repository.note, 'Catatan dummy');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('manpower menampilkan error API pada field terkait', (
    tester,
  ) async {
    final repository = _FakeProjectRepository()
      ..submitManpowerError = const AppException(
        'Data manpower tidak valid.',
        details: ['target: Target melebihi volume yang tersedia.'],
        hasErrors: true,
      );
    await _pumpPage(
      tester,
      ProjectTaskDetailData.sample(code: 'A.1', task: 'Pondasi'),
      repository: repository,
    );

    await tester.tap(find.text('Add Manpower'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agung Prasetyo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Target melebihi volume yang tersedia.'), findsOneWidget);
    expect(find.byType(ProjectManpowerFormBottomSheet), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('form manpower dapat digulir pada layar kecil dengan keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await _pumpPage(
      tester,
      ProjectTaskDetailData.sample(code: 'A.1', task: 'Pondasi'),
    );
    await tester.tap(find.text('Add Manpower'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agung Prasetyo'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '3');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectManpowerFormBottomSheet), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  ProjectTaskDetailData detail, {
  ProjectRepository? repository,
}) async {
  final resolvedRepository = repository ?? _FakeProjectRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectRepositoryProvider.overrideWithValue(resolvedRepository),
        projectSubordinatesProvider.overrideWith(
          (ref, projectId) => Stream.value(const [
            ProjectReference(id: 'employee-1', name: 'Agung Prasetyo'),
            ProjectReference(id: 'employee-2', name: 'Arish Noah'),
            ProjectReference(id: 'employee-3', name: 'Dimas Masdim'),
          ]),
        ),
        projectHelpersProvider.overrideWith((ref, projectId) async {
          return const [
            ProjectHelper(id: 'helper-1', code: 'EMP010', name: 'Budi'),
            ProjectHelper(id: 'helper-2', code: 'EMP011', name: 'Budo'),
            ProjectHelper(id: 'helper-3', code: 'EMP012', name: 'Dudi'),
          ];
        }),
      ],
      child: MaterialApp(home: ProjectTaskDetailPage(detail: detail)),
    ),
  );
  await tester.pump();
}

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository({ProjectTask? detailTask})
    : _detailTask = detailTask,
      super(dioClient: DioClient(secureStorage: _FakeSecureStorage()));

  final ProjectTask? _detailTask;
  String? employeeId;
  double? target;
  List<String>? helperEmployeeIds;
  String? note;
  String? deletedProjectId;
  String? deletedTaskId;
  String? deletedManpowerTaskId;
  String? delegatedProjectId;
  String? delegatedTaskId;
  String? updatedManpowerTaskId;
  int fetchDetailCount = 0;
  Object? submitManpowerError;
  Object? delegateManpowerError;

  @override
  Future<ProjectTask> fetchTaskDetail({
    required String projectId,
    required String taskId,
  }) async {
    fetchDetailCount++;
    final task = _detailTask;
    if (task == null) throw StateError('Detail task tidak disiapkan.');
    if (deletedManpowerTaskId == null && delegatedTaskId == null) return task;

    final json = task.toJson();
    if (deletedManpowerTaskId != null) {
      json['manpower'] = <Object?>[];
    } else {
      json['isDraft'] = false;
      json['manpower'] = [
        for (final manpower in task.manpower)
          manpower.toJson()..['canDelete'] = false,
      ];
    }
    return ProjectTask.fromJson(json);
  }

  @override
  Future<String?> submitTaskManpower({
    required String projectId,
    required String taskId,
    required String employeeId,
    required double target,
    required List<String> helperEmployeeIds,
    required String note,
  }) async {
    final error = submitManpowerError;
    if (error != null) throw error;
    this.employeeId = employeeId;
    this.target = target;
    this.helperEmployeeIds = helperEmployeeIds;
    this.note = note;
    return 'Manpower berhasil ditambahkan.';
  }

  @override
  Future<String?> updateTaskManpower({
    required String projectId,
    required String taskId,
    required String manpowerTaskId,
    required String employeeId,
    required double target,
    required List<String> helperEmployeeIds,
    required String note,
  }) async {
    updatedManpowerTaskId = manpowerTaskId;
    this.employeeId = employeeId;
    this.target = target;
    this.helperEmployeeIds = helperEmployeeIds;
    this.note = note;
    return 'Manpower berhasil diperbarui.';
  }

  @override
  Future<String?> deleteTaskManpower({
    required String projectId,
    required String taskId,
    required String manpowerTaskId,
  }) async {
    deletedProjectId = projectId;
    deletedTaskId = taskId;
    deletedManpowerTaskId = manpowerTaskId;
    return 'Manpower berhasil dihapus.';
  }

  @override
  Future<String?> delegateFinalTask({
    required String projectId,
    required String taskId,
  }) async {
    delegatedProjectId = projectId;
    delegatedTaskId = taskId;
    final error = delegateManpowerError;
    if (error != null) throw error;
    return 'Manpower berhasil di-assign.';
  }
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'access-token';
}
