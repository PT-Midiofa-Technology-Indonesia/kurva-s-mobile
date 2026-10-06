import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/workforce/data/models/leave.dart';
import 'package:curva_mobile/modules/workforce/data/workforce_repository.dart';
import 'package:curva_mobile/modules/workforce/presentation/workforce_leave_request_page.dart';
import 'package:curva_mobile/modules/workforce/presentation/workforce_request_form_controllers.dart';
import 'package:curva_mobile/modules/workforce/workforce_providers.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  testWidgets('shows API leave errors below their respective fields', (
    tester,
  ) async {
    final storage = _FakeSecureStorage();
    final repository = _ValidationErrorWorkforceRepository(
      dioClient: DioClient(secureStorage: storage),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workforceRepositoryProvider.overrideWithValue(repository),
          leaveRequestFormControllerProvider.overrideWith((ref) {
            final controller = LeaveRequestFormController(ref)
              ..setLeaveType(_leaveType)
              ..reasonController.text = 'Keperluan pengujian'
              ..setStartDate(DateTime(2026, 8, 21))
              ..setEndDate(DateTime(2026, 8, 22));
            return controller;
          }),
        ],
        child: const MaterialApp(home: WorkforceLeaveRequestPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajukan cuti'));
    await tester.pumpAndSettle();

    expect(find.text('Jenis izin wajib dipilih.'), findsOneWidget);
    expect(find.text('Tanggal mulai wajib diisi.'), findsOneWidget);
    expect(find.text('Tanggal berakhir wajib diisi.'), findsOneWidget);
    expect(find.text('Periksa kembali data yang ditandai.'), findsNothing);
    expect(find.text('Data yang diberikan tidak valid.'), findsNothing);
  });

  testWidgets('shows warning for an unmapped leave date conflict', (
    tester,
  ) async {
    final storage = _FakeSecureStorage();
    final repository = _DateConflictWorkforceRepository(
      dioClient: DioClient(secureStorage: storage),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workforceRepositoryProvider.overrideWithValue(repository),
          leaveRequestFormControllerProvider.overrideWith((ref) {
            return LeaveRequestFormController(ref)
              ..setLeaveType(_leaveType)
              ..reasonController.text = 'Keperluan pengujian'
              ..setStartDate(DateTime(2026, 8, 21))
              ..setEndDate(DateTime(2026, 8, 21));
          }),
        ],
        child: const MaterialApp(home: WorkforceLeaveRequestPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajukan cuti'));
    await tester.pump();

    expect(
      find.text('Sudah ada pengajuan cuti pada tanggal yang sama.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}

const _leaveType = LeaveType(
  id: 'leave-type-1',
  code: 'ANNUAL',
  name: 'Cuti Tahunan',
  isPaid: true,
  requiresDocument: false,
  quota: 12,
  balance: LeaveBalance(quota: 12, used: 0, remaining: 12),
);

class _ValidationErrorWorkforceRepository extends WorkforceRepository {
  const _ValidationErrorWorkforceRepository({required super.dioClient});

  @override
  Future<List<LeaveType>> fetchLeaveTypes() async => const [_leaveType];

  @override
  Future<String?> submitLeave(LeaveRequestInput input) async {
    throw const AppException(
      'Data yang diberikan tidak valid.',
      code: 'VALIDATION_ERROR',
      details: [
        'leaveTypeId: Jenis izin wajib dipilih.',
        'startDate: Tanggal mulai wajib diisi.',
        'endDate: Tanggal berakhir wajib diisi.',
      ],
      hasErrors: true,
    );
  }
}

class _DateConflictWorkforceRepository extends WorkforceRepository {
  const _DateConflictWorkforceRepository({required super.dioClient});

  @override
  Future<List<LeaveType>> fetchLeaveTypes() async => const [_leaveType];

  @override
  Future<String?> submitLeave(LeaveRequestInput input) async {
    throw const AppException(
      'Pengajuan cuti gagal.',
      code: 'VALIDATION_ERROR',
      details: ['dateRange: Sudah ada pengajuan cuti pada tanggal yang sama.'],
      hasErrors: true,
    );
  }
}

class _FakeSecureStorage extends SecureStorageService {}
