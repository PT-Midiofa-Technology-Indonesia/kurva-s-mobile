import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../shared/widgets/page_open_refresh_scope.dart';
import '../workforce/workforce_providers.dart';
import 'data/dashboard_repository.dart';
import 'data/models/dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(dioClient: ref.watch(dioClientProvider));
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchDashboard();
});

final dashboardPageControllerProvider =
    Provider.autoDispose<DashboardPageController>((ref) {
      return DashboardPageController(ref);
    });

class DashboardPageController implements PageOpenRefreshController {
  const DashboardPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(authControllerProvider);
    _ref.invalidateIfExists(dashboardSummaryProvider);
    _ref.invalidateIfExists(todayAttendanceProvider);
  }
}
