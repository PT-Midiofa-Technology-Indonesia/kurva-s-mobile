import 'package:flutter/material.dart';

import 'expense_reimbursement_create_page.dart';

/// Form reimbursement untuk biaya yang tidak berkaitan dengan proyek.
///
/// Form dan perilaku submit mengikuti halaman reimbursement proyek, tetapi
/// field proyek tidak ditampilkan dan request dikirim sebagai `non_project`.
class ExpenseReimbursementNonProjectPage extends StatelessWidget {
  const ExpenseReimbursementNonProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExpenseReimbursementCreatePage(isProject: false);
  }
}
