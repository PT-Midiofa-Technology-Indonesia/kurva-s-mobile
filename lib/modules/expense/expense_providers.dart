import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/date_formatter.dart';
import '../auth/auth_providers.dart';
import '../auth/data/models/auth_user.dart';
import 'data/models/cost_request.dart';
import 'data/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(dioClient: ref.watch(dioClientProvider));
});

final expenseCompanyOptionsProvider = Provider<List<AuthCompany>>((ref) {
  final authState = ref.watch(authControllerProvider).valueOrNull;
  final user = authState?.user;
  if (user == null) {
    return const [];
  }

  final companiesById = <String, AuthCompany>{};
  for (final assignment in user.assignments) {
    final company = assignment.company;
    if (company != null && company.id.isNotEmpty) {
      companiesById.putIfAbsent(company.id, () => company);
    }
  }
  for (final company in user.companies) {
    if (company.id.isNotEmpty) {
      companiesById.putIfAbsent(company.id, () => company);
    }
  }

  return companiesById.values.toList(growable: false);
});

final expenseSelectedCompanyIdProvider = StateProvider<String?>((ref) => null);

final expenseCompanyIdProvider = Provider<String?>((ref) {
  final selectedCompanyId = ref.watch(expenseSelectedCompanyIdProvider);
  if (selectedCompanyId != null && selectedCompanyId.isNotEmpty) {
    return selectedCompanyId;
  }

  return ref.watch(expenseCompanyOptionsProvider).firstOrNull?.id;
});

final expenseSelectedCompanyProvider = Provider<AuthCompany?>((ref) {
  final companyId = ref.watch(expenseCompanyIdProvider);
  if (companyId == null || companyId.isEmpty) {
    return null;
  }

  for (final company in ref.watch(expenseCompanyOptionsProvider)) {
    if (company.id == companyId) {
      return company;
    }
  }

  return null;
});

final costRequestFilterProvider = StateProvider<CostRequestFilter>((ref) {
  return const CostRequestFilter();
});

final costRequestListProvider =
    AutoDisposeAsyncNotifierProvider<
      CostRequestListController,
      CostRequestListState
    >(CostRequestListController.new);

class CostRequestListState {
  const CostRequestListState({
    required this.result,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final CostRequestListResult result;
  final bool isLoadingMore;
  final Object? loadMoreError;
  bool get hasMore => result.meta.currentPage < result.meta.lastPage;
}

class CostRequestListController
    extends AutoDisposeAsyncNotifier<CostRequestListState> {
  int _generation = 0;

  @override
  Future<CostRequestListState> build() async {
    _generation++;
    final filter = ref.watch(costRequestFilterProvider);
    final result = await ref
        .watch(expenseRepositoryProvider)
        .fetchCostRequests(
          companyId: ref.watch(expenseCompanyIdProvider),
          status: filter.status,
          requestType: filter.requestType,
          startDate: filter.startDateParam,
          endDate: filter.endDateParam,
          year: filter.year?.toString(),
          perPage: 15,
          page: 1,
        );
    return CostRequestListState(result: result);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    final generation = _generation;
    state = AsyncData(
      CostRequestListState(result: current.result, isLoadingMore: true),
    );
    try {
      final filter = ref.read(costRequestFilterProvider);
      final next = await ref
          .read(expenseRepositoryProvider)
          .fetchCostRequests(
            companyId: ref.read(expenseCompanyIdProvider),
            status: filter.status,
            requestType: filter.requestType,
            startDate: filter.startDateParam,
            endDate: filter.endDateParam,
            year: filter.year?.toString(),
            perPage: 15,
            page: current.result.meta.currentPage + 1,
          );
      if (generation != _generation) return;
      state = AsyncData(
        CostRequestListState(
          result: CostRequestListResult(
            costRequests: [
              ...current.result.costRequests,
              ...next.costRequests,
            ],
            meta: next.meta,
            links: next.links,
          ),
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      state = AsyncData(
        CostRequestListState(result: current.result, loadMoreError: error),
      );
    }
  }
}

final costRequestDetailProvider = FutureProvider.family<CostRequest, String>((
  ref,
  costRequestId,
) {
  return ref
      .watch(expenseRepositoryProvider)
      .fetchCostRequestDetail(
        costRequestId: costRequestId,
        companyId: ref.watch(expenseCompanyIdProvider),
      );
});

class CostRequestFilter {
  const CostRequestFilter({
    this.status,
    this.requestType,
    this.startDate,
    this.endDate,
    this.year,
  });

  final String? status;
  final String? requestType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? year;

  int get activeCount {
    return [
      status,
      requestType,
      startDate,
      endDate,
      year,
    ].where((value) => value != null).length;
  }

  String? get startDateParam => formatDateParam(startDate);

  String? get endDateParam => formatDateParam(endDate);
}
