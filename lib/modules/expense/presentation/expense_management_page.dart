import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/offline_first_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/full_page_search_bottom_sheet.dart';
import '../../../shared/widgets/app_popup_menu_button.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/selection_bottom_sheet.dart';
import '../data/models/cost_request.dart';
import '../expense_providers.dart';
import 'widgets/expense_filter_bottom_sheet.dart';

class ExpenseManagementPage extends ConsumerWidget {
  const ExpenseManagementPage({super.key});

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;
  static const _backgroundColor = AppColors.cardBackground;
  static const _cardBorderColor = AppColors.line;
  static const _lightTeal = AppColors.workforceIconBackground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final costRequestState = ref.watch(costRequestListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: _backgroundColor,
          child: Column(
            children: [
              const _ExpenseHeader(),
              Expanded(
                child: costRequestState.when(
                  data: (state) => _ExpenseList(state: state),
                  loading: () => const AppSkeletonListView(
                    variant: AppSkeletonListVariant.detailed,
                    itemCount: 4,
                  ),
                  error: (error, _) => NetworkAwareErrorView(
                    error: error,
                    message: _errorMessage(error),
                    onRetry: () => ref.invalidate(costRequestListProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _errorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? 'Data reimbursement gagal dimuat.' : message;
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.state});

  final CostRequestListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = state.result.costRequests;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(costRequestListProvider.future),
      child: expenses.isEmpty
          ? const LayoutBuilder(builder: _emptyListBuilder)
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 160) {
                  ref.read(costRequestListProvider.notifier).loadNextPage();
                }
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                children: [
                  _MonthTitle(title: _monthTitle(expenses.first)),
                  const SizedBox(height: 6),
                  ...expenses.map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _ExpenseCard(expense),
                    ),
                  ),
                  if (state.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.loadMoreError != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => ref
                              .read(costRequestListProvider.notifier)
                              .loadNextPage(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Gagal memuat data. Coba lagi'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  static Widget _emptyListBuilder(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: constraints.maxHeight,
          child: const _ExpenseEmptyState(),
        ),
      ],
    );
  }

  static String _monthTitle(CostRequest expense) {
    final date = _parseDate(expense.submittedAt) ?? _parseDate(expense.dueDate);
    if (date == null) return 'Reimbursement';

    return '${_monthNames[date.month - 1]} ${date.year}';
  }
}

class _ExpenseHeader extends ConsumerWidget {
  const _ExpenseHeader();

  Future<void> _showFilter(BuildContext context, WidgetRef ref) async {
    final selectedFilter = await ExpenseFilterBottomSheet.show(
      context,
      initialFilter: ref.read(costRequestFilterProvider),
    );

    if (!context.mounted || selectedFilter == null) return;

    ref.read(costRequestFilterProvider.notifier).state = selectedFilter;
  }

  Future<void> _showSearch(BuildContext context, WidgetRef ref) async {
    final costRequestState = ref.read(costRequestListProvider);
    final expenses =
        costRequestState.valueOrNull?.result.costRequests ??
        const <CostRequest>[];

    if (expenses.isEmpty) {
      AppToast.info(
        context,
        costRequestState.isLoading
            ? 'Daftar reimbursement sedang dimuat.'
            : 'Data reimbursement belum tersedia.',
      );
      return;
    }

    final selectedExpense = await FullPageSearchBottomSheet.show<CostRequest>(
      context,
      title: 'Pencarian',
      options: expenses,
      labelBuilder: _expenseSearchLabel,
      searchTextBuilder: (expense) => [
        expense.code,
        expense.reason,
        expense.project?.name ?? '',
        expense.statusLabel,
        _requestTypeLabel(expense.requestType),
      ].join(' '),
    );

    if (!context.mounted || selectedExpense == null) return;

    context.push(
      RouteNames.expenseReimbursementDetail,
      extra: selectedExpense.id,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterCount = ref.watch(costRequestFilterProvider).activeCount;
    final isOffline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;

    return AppHeader(
      title: 'Expenses',
      onBackPressed: () => context.pop(),
      actions: isOffline
          ? const []
          : [
              AppHeaderAction(
                icon: Icons.search,
                tooltip: 'Cari',
                onPressed: () => _showSearch(context, ref),
              ),
              AppHeaderAction(
                assetPath: AssetPaths.iconFilter,
                tooltip: 'Filter',
                badge: activeFilterCount == 0
                    ? null
                    : activeFilterCount.toString(),
                onPressed: () => _showFilter(context, ref),
              ),
            ],
      actionWidgets: [if (!isOffline) const _HeaderMenuButton()],
    );
  }
}

enum _ExpenseHeaderMenuAction {
  changeCompany,
  createReimbursement;

  String get label {
    return switch (this) {
      _ExpenseHeaderMenuAction.changeCompany => 'Ganti perusahaan',
      _ExpenseHeaderMenuAction.createReimbursement => 'Buat reimbursement',
    };
  }
}

enum _ReimbursementType {
  project('Proyek'),
  nonProject('Non-proyek');

  const _ReimbursementType(this.label);

  final String label;
}

Future<void> _showCreateReimbursementSelection(BuildContext context) async {
  final selectedType = await SelectionBottomSheet.show<_ReimbursementType>(
    context,
    title: 'Pilih Aksi Selanjutnya',
    options: _ReimbursementType.values,
    selectedOption: null,
    labelBuilder: (type) => type.label,
  );

  if (!context.mounted || selectedType == null) return;

  final route = selectedType == _ReimbursementType.project
      ? RouteNames.expenseReimbursementCreate
      : RouteNames.expenseReimbursementNonProject;
  context.push(route);
}

class _HeaderMenuButton extends ConsumerWidget {
  const _HeaderMenuButton();

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    _ExpenseHeaderMenuAction action,
  ) async {
    switch (action) {
      case _ExpenseHeaderMenuAction.changeCompany:
        await _changeCompany(context, ref);
      case _ExpenseHeaderMenuAction.createReimbursement:
        await _showCreateReimbursementSelection(context);
    }
  }

  Future<void> _changeCompany(BuildContext context, WidgetRef ref) async {
    final companies = ref.read(expenseCompanyOptionsProvider);
    if (companies.isEmpty) {
      AppToast.info(context, 'Daftar perusahaan tidak tersedia.');
      return;
    }

    final selectedCompany = ref.read(expenseSelectedCompanyProvider);
    final selected = await SelectionBottomSheet.show(
      context,
      title: 'Ganti perusahaan',
      options: companies,
      selectedOption: selectedCompany,
      labelBuilder: (company) => company.name,
    );

    if (!context.mounted || selected == null) return;

    ref.read(expenseSelectedCompanyIdProvider.notifier).state = selected.id;
    ref.invalidate(costRequestListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPopupMenuButton<_ExpenseHeaderMenuAction>(
      items: _ExpenseHeaderMenuAction.values,
      labelBuilder: (action) => action.label,
      iconColor: AppColors.dashboardTeal,
      fontFamily: ExpenseManagementPage._fontFamily,
      onSelected: (action) => _handleMenuAction(context, ref, action),
    );
  }
}

class _MonthTitle extends StatelessWidget {
  const _MonthTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.strongText,
              fontFamily: ExpenseManagementPage._fontFamily,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseEmptyState extends StatelessWidget {
  const _ExpenseEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AssetPaths.expenseReimbursementEmpty,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 48),
            const Text(
              'Belum ada riwayat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.dashboardTeal,
                fontFamily: ExpenseManagementPage._fontFamily,
                fontSize: 18,
                height: 1.33,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Kamu belum pernah membuat\nreimbursement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontFamily: ExpenseManagementPage._fontFamily,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 36),
            AppButton(
              label: 'Buat sekarang',
              fullWidth: false,
              backgroundColor: AppColors.errorBackground,
              borderRadius: AppRadius.md,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              textStyle: const TextStyle(color: AppColors.expenseText),
              onPressed: () => _showCreateReimbursementSelection(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard(this.expense);

  final CostRequest expense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(
          RouteNames.expenseReimbursementDetail,
          extra: expense.id,
        ),
        child: Ink(
          height: 128,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: ExpenseManagementPage._cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.reason.isEmpty ? expense.code : expense.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: ExpenseManagementPage._accentFontFamily,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: AppColors.line),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _ExpenseAmount(expense: expense)),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(width: 161, child: _ExpenseStatus(expense: expense)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseAmount extends StatelessWidget {
  const _ExpenseAmount({required this.expense});

  final CostRequest expense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatCurrency(expense.totalAmount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: ExpenseManagementPage._fontFamily,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _requestTypeLabel(expense.requestType),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontFamily: ExpenseManagementPage._accentFontFamily,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ExpenseStatus extends StatelessWidget {
  const _ExpenseStatus({required this.expense});

  final CostRequest expense;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(expense.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          expense.statusLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: statusColor,
            fontFamily: ExpenseManagementPage._accentFontFamily,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _SubmittedBadge(label: _submittedLabel(expense.submittedAt)),
      ],
    );
  }
}

class _SubmittedBadge extends StatelessWidget {
  const _SubmittedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      height: 20,
      padding: const EdgeInsets.fromLTRB(6, 2, AppSpacing.sm, 2),
      decoration: BoxDecoration(
        color: ExpenseManagementPage._lightTeal,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.dashboardTeal),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            size: 14,
            color: AppColors.dashboardTeal,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: ExpenseManagementPage._accentFontFamily,
                fontSize: 12,
                height: 1.33,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

DateTime? _parseDate(String? value) {
  return parseApiDateTime(value);
}

String _submittedLabel(String? submittedAt) {
  final date = _parseDate(submittedAt);
  if (date == null) return 'Diajukan -';

  return 'Diajukan ${_shortDate(date)}';
}

String _shortDate(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatCurrency(String value) {
  final number = double.tryParse(value) ?? 0;
  final rounded = number.round().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < rounded.length; index++) {
    final reverseIndex = rounded.length - index;
    buffer.write(rounded[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp $buffer';
}

String _requestTypeLabel(String value) {
  return switch (value) {
    'project' => 'Project cost',
    'non_project' => 'Non-project cost',
    _ => value.isEmpty ? '-' : value,
  };
}

String _expenseSearchLabel(CostRequest expense) {
  if (expense.code.isNotEmpty) return expense.code;
  if (expense.reason.isNotEmpty) return expense.reason;
  return '-';
}

Color _statusColor(String value) {
  return switch (value) {
    'paid' => AppColors.green,
    'rejected' => AppColors.rose,
    'cancelled' => AppColors.secondaryText,
    'submitted' => AppColors.orange,
    _ => AppColors.secondaryText,
  };
}
