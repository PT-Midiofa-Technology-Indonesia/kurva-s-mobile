import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_task_action_controllers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_assignee_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_qc_assignment_picker_page.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  test('QC assignment uses the bulk QC endpoint branch', () async {
    final repository = _FakeProjectRepository();
    final container = ProviderContainer(
      overrides: [projectRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    const args = ProjectAssigneePickerArgs(
      projectId: 'project-1',
      qcTaskIds: ['qc-1', 'qc-2'],
    );
    final assignment = container
        .read(projectAssigneeActionControllerProvider(args))
        .assign('employee-1');
    await Future<void>.delayed(Duration.zero);

    expect(repository.projectId, 'project-1');
    expect(repository.taskIds, ['qc-1', 'qc-2']);
    expect(repository.employeeId, 'employee-1');
    await assignment;
  });

  for (final scenario in ['empty', 'error', 'offline']) {
    testWidgets('handles $scenario without allowing assignment', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStateProvider.overrideWith(
              (ref) => Stream.value(
                scenario == 'offline'
                    ? const ConnectivityState.offline()
                    : const ConnectivityState.online(),
              ),
            ),
            projectQcTasksProvider.overrideWith(
              (ref, query) => scenario == 'error'
                  ? Stream.error(const AppException('Gagal memuat task'))
                  : Stream.value(
                      scenario == 'empty' ? [] : [_task('qc-1', 'Pondasi')],
                    ),
            ),
          ],
          child: const MaterialApp(
            home: ProjectQcAssignmentPickerPage(
              args: ProjectQcAssignmentPickerArgs(
                projectId: 'project-1',
                initialTaskId: 'qc-1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      if (scenario == 'empty') {
        expect(
          find.text('Belum ada task yang dapat di-assign.'),
          findsOneWidget,
        );
      }
      if (scenario == 'error') {
        expect(find.text('Gagal memuat task'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'multiple selection survives search and Assignee back navigation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ProjectAssigneePickerArgs? received;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const ProjectQcAssignmentPickerPage(
              args: ProjectQcAssignmentPickerArgs(
                projectId: 'project-1',
                initialTaskId: 'qc-1',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.projectAssignee,
            builder: (context, state) {
              received = state.extra as ProjectAssigneePickerArgs;
              return Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Kembali dari Assignee'),
                ),
              );
            },
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
            projectQcTasksProvider.overrideWith((ref, query) {
              expect(query.projectId, 'project-1');
              expect(query.tab, 'open');
              return Stream.value([
                _task('qc-1', 'Pondasi'),
                _task('qc-2', 'Dinding'),
                _task('qc-3', 'Selesai', canClaim: false),
              ]);
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Assign (1)'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.text('Agung Prasetyo'), findsNothing);
      expect(find.text('Budi Santoso'), findsNWidgets(2));
      expect(find.text('100 m²'), findsNWidgets(2));
      expect(find.text('Sebelah Kanan'), findsNWidgets(2));
      expect(find.byKey(const Key('qc-target-icon')), findsNWidgets(2));
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();
      expect(find.text('Assign (2)'), findsOneWidget);
      await tester.tap(find.byTooltip('Cari task'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Dinding');
      await tester.pump();
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Assign (2)'), findsOneWidget);
      await tester.tap(find.text('Assign (2)'));
      await tester.pumpAndSettle();
      expect(received?.qcTaskIds, ['qc-1', 'qc-2']);
      expect(received?.projectId, 'project-1');
      expect(received?.taskId, isEmpty);
      await tester.tap(find.text('Kembali dari Assignee'));
      await tester.pumpAndSettle();
      expect(find.text('Assign (2)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();
      expect(find.text('Assign (0)'), findsOneWidget);
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

ProjectTask _task(String id, String title, {bool canClaim = true}) =>
    ProjectTask.fromJson({
      'id': id,
      'projectId': 'project-1',
      'title': title,
      'code': 'A.1',
      'canClaim': canClaim,
      'statusLabel': 'Menunggu Diperiksa',
      'assignee': {'id': 'employee-1', 'name': 'Agung Prasetyo'},
      'manpowerName': 'Budi Santoso',
      'targetVolume': 100,
      'uom': {'id': 'uom-1', 'name': 'Meter Persegi', 'code': 'M2'},
      'description': 'Sebelah Kanan',
    });

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository()
    : super(dioClient: DioClient(secureStorage: _FakeSecureStorage()));

  String? projectId;
  List<String>? taskIds;
  String? employeeId;

  @override
  Future<String?> bulkAssignQcTasks({
    required String projectId,
    required List<String> taskIds,
    required String employeeId,
  }) async {
    this.projectId = projectId;
    this.taskIds = taskIds;
    this.employeeId = employeeId;
    return 'QC task berhasil di-assign.';
  }
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'access-token';
}
