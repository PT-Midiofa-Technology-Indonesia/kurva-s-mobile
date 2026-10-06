import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/expense/data/expense_repository.dart';
import 'package:curva_mobile/modules/expense/expense_providers.dart';
import 'package:curva_mobile/modules/expense/presentation/expense_reimbursement_create_controller.dart';
import 'package:curva_mobile/modules/expense/presentation/expense_reimbursement_create_page.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  testWidgets('maps API reimbursement errors to their respective fields', (
    tester,
  ) async {
    final storage = _FakeSecureStorage();
    final repository = _ValidationErrorExpenseRepository(
      dioClient: DioClient(secureStorage: storage),
    );
    late ExpenseReimbursementCreateController form;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repository),
          expenseCompanyIdProvider.overrideWithValue(null),
          expenseReimbursementFormControllerProvider.overrideWith((ref, _) {
            form = ExpenseReimbursementCreateController(ref, false)
              ..purposeController.text = 'Keperluan pengujian'
              ..setDeadline(DateTime(2026, 8, 25))
              ..setPaymentRequest('Cash');
            final item = form.items.first;
            item.receiptNumberController.text = 'INV-001';
            item.itemNameController.text = 'Transportasi';
            item.amountController.text = '100000';
            form.addProofs(0, [
              ExpenseProofAttachment(
                name: 'proof.jpg',
                size: 1,
                pickedFile: PlatformFile(
                  name: 'proof.jpg',
                  size: 1,
                  bytes: Uint8List.fromList([1]),
                ),
              ),
            ]);
            return form;
          }),
        ],
        child: const MaterialApp(
          home: ExpenseReimbursementCreatePage(isProject: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajukan reimburse'));
    await tester.pumpAndSettle();

    expect(form.purposeError, 'Keperluan wajib diisi.');
    expect(form.deadlineError, 'Tenggat waktu wajib diisi.');
    expect(form.itemsError, 'Minimal satu item wajib diisi.');
    expect(find.text('Periksa kembali data yang ditandai.'), findsNothing);
    expect(find.text('Data yang diberikan tidak valid.'), findsNothing);
  });
}

class _ValidationErrorExpenseRepository extends ExpenseRepository {
  const _ValidationErrorExpenseRepository({required super.dioClient});

  @override
  Future<String?> createCostRequest({
    required ExpenseCostRequest request,
    String? companyId,
  }) async {
    throw const AppException(
      'Data yang diberikan tidak valid.',
      code: 'VALIDATION_ERROR',
      details: [
        'reason: Keperluan wajib diisi.',
        'dueDate: Tenggat waktu wajib diisi.',
        'items: Minimal satu item wajib diisi.',
      ],
      hasErrors: true,
    );
  }
}

class _FakeSecureStorage extends SecureStorageService {}
