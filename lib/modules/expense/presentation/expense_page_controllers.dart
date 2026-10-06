import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/page_open_refresh_scope.dart';
import '../../project/project_providers.dart';
import '../expense_providers.dart';

final expenseManagementPageControllerProvider =
    Provider.autoDispose<ExpenseManagementPageController>((ref) {
      return ExpenseManagementPageController(ref);
    });

final expenseReimbursementCreatePageControllerProvider =
    Provider.autoDispose<ExpenseReimbursementCreatePageController>((ref) {
      return ExpenseReimbursementCreatePageController(ref);
    });

final expenseReimbursementNonProjectPageControllerProvider =
    Provider.autoDispose<ExpenseReimbursementNonProjectPageController>((ref) {
      return const ExpenseReimbursementNonProjectPageController();
    });

final expenseReimbursementDetailPageControllerProvider = Provider.autoDispose
    .family<ExpenseReimbursementDetailPageController, String>((ref, id) {
      return ExpenseReimbursementDetailPageController(ref, id);
    });

class ExpenseManagementPageController implements PageOpenRefreshController {
  const ExpenseManagementPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(costRequestListProvider);
  }
}

class ExpenseReimbursementCreatePageController
    implements PageOpenRefreshController {
  const ExpenseReimbursementCreatePageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(projectListProvider);
  }
}

class ExpenseReimbursementNonProjectPageController
    implements PageOpenRefreshController {
  const ExpenseReimbursementNonProjectPageController();

  @override
  void refresh() {}
}

class ExpenseReimbursementDetailPageController
    implements PageOpenRefreshController {
  const ExpenseReimbursementDetailPageController(this._ref, this._id);

  final Ref _ref;
  final String _id;

  @override
  void refresh() {
    if (_id.isEmpty) return;
    _ref.invalidateIfExists(costRequestDetailProvider(_id));
  }
}
