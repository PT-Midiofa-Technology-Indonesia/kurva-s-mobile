import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/offline_first_providers.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_popup_menu_button.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../../../shared/widgets/selection_bottom_sheet.dart';
import '../../../shared/utils/date_formatter.dart';
import '../data/models/prospect_models.dart';
import '../prospect_providers.dart';
import 'prospect_detail/prospect_detail_page.dart';
import 'prospect_kanban_controller.dart';

class ProspectKanbanPage extends ConsumerStatefulWidget {
  const ProspectKanbanPage({super.key});

  static const _fontFamily = AppFonts.inter;
  static const _accentColor = AppColors.dashboardTeal;
  static const _boardBackground = AppColors.cardBackground;
  static const _stageBackground = AppColors.tabBorder;
  static const _chipBackground = AppColors.prospectChipBackground;
  static const _warningChipBackground = AppColors.warningBackground;
  static const _dangerChipBackground = AppColors.dangerBackground;
  static const _warningColor = AppColors.orange;
  static const _dangerColor = AppColors.rose;

  @override
  ConsumerState<ProspectKanbanPage> createState() => _ProspectKanbanPageState();
}

class _ProspectKanbanPageState extends ConsumerState<ProspectKanbanPage> {
  final _boardKey = GlobalKey();
  final _boardScrollController = ScrollController();
  Timer? _autoScrollTimer;
  double _autoScrollStep = 0;

  @override
  void dispose() {
    _stopAutoScroll();
    _boardScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prospects = ref.watch(prospectPipelineProvider);
    final controller = ref.watch(prospectKanbanControllerProvider);
    final isOffline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: ProspectKanbanPage._boardBackground,
          child: Column(
            children: [
              _ProspectHeader(
                onBackPressed: () => context.pop(),
                isRefreshing: controller.isRefreshing,
                showActions: !isOffline,
                onRefreshPressed:
                    controller.hasMutations || controller.isRefreshing
                    ? null
                    : _refreshPipeline,
              ),
              Expanded(
                child: prospects.when(
                  data: (stages) {
                    if (stages.isEmpty) {
                      controller.clear();
                      return const EmptyView(
                        message: 'Pipeline prospect belum tersedia.',
                      );
                    }

                    controller.syncPipeline(stages);
                    final visibleStages = controller.stages ?? stages;

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(prospectPipelineProvider.future),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            key: _boardKey,
                            controller: _boardScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: SizedBox(
                              height:
                                  constraints.maxHeight - (AppSpacing.md * 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    var index = 0;
                                    index < visibleStages.length;
                                    index++
                                  ) ...[
                                    _KanbanStage(
                                      stage: visibleStages[index],
                                      mutatingProspectIds:
                                          controller.mutatingProspectIds,
                                      onMoveProspect: _moveProspect,
                                      onDragMove: _updateAutoScroll,
                                      onDragEnd: _stopAutoScroll,
                                    ),
                                    if (index != visibleStages.length - 1)
                                      const SizedBox(width: AppSpacing.md),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  error: (error, stackTrace) => NetworkAwareErrorView(
                    error: error,
                    message: _errorMessage(error),
                    onRetry: () {
                      controller.clear();
                      ref.invalidate(prospectPipelineProvider);
                    },
                  ),
                  loading: () => const AppSkeletonKanbanView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshPipeline() async {
    _stopAutoScroll();
    try {
      await ref.read(prospectKanbanControllerProvider).refresh();
    } catch (error) {
      if (mounted) {
        AppToast.error(context, error);
      }
    }
  }

  Future<void> _moveProspect(
    ProspectProject prospect,
    ProspectStage targetStage,
  ) async {
    _stopAutoScroll();

    try {
      final message = await ref
          .read(prospectKanbanControllerProvider)
          .move(prospect, targetStage);
      if (!mounted) return;
      if (message == null) return;
      AppToast.success(context, message);
    } catch (error) {
      if (!mounted) return;

      AppToast.error(context, error);
    }
  }

  void _updateAutoScroll(Offset globalPosition) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_boardScrollController.hasClients) return;

    final position = box.globalToLocal(globalPosition);
    const edgeSize = 72.0;
    const maxStep = 22.0;

    if (position.dx < edgeSize) {
      final intensity = ((edgeSize - position.dx) / edgeSize).clamp(0.0, 1.0);
      _startAutoScroll(-maxStep * intensity);
      return;
    }

    if (position.dx > box.size.width - edgeSize) {
      final intensity = ((position.dx - (box.size.width - edgeSize)) / edgeSize)
          .clamp(0.0, 1.0);
      _startAutoScroll(maxStep * intensity);
      return;
    }

    _stopAutoScroll();
  }

  void _startAutoScroll(double step) {
    _autoScrollStep = step;
    _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_boardScrollController.hasClients || _autoScrollStep == 0) return;

      final maxScroll = _boardScrollController.position.maxScrollExtent;
      final nextOffset = (_boardScrollController.offset + _autoScrollStep)
          .clamp(0.0, maxScroll)
          .toDouble();

      if (nextOffset == _boardScrollController.offset) {
        return;
      }

      _boardScrollController.jumpTo(nextOffset);
    });
  }

  void _stopAutoScroll() {
    _autoScrollStep = 0;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }
}

class _ProspectHeader extends StatelessWidget {
  const _ProspectHeader({
    required this.onBackPressed,
    required this.isRefreshing,
    required this.showActions,
    required this.onRefreshPressed,
  });

  final VoidCallback onBackPressed;
  final bool isRefreshing;
  final bool showActions;
  final VoidCallback? onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      title: 'Prospect',
      onBackPressed: onBackPressed,
      actionWidgets: [
        if (showActions) ...[
          _HeaderRefreshButton(
            isRefreshing: isRefreshing,
            onPressed: onRefreshPressed,
          ),
          const _HeaderMenuButton(),
        ],
      ],
    );
  }
}

class _HeaderRefreshButton extends StatelessWidget {
  const _HeaderRefreshButton({
    required this.isRefreshing,
    required this.onPressed,
  });

  final bool isRefreshing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: 'Refresh',
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: isRefreshing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.dashboardTeal,
                ),
              )
            : const Icon(
                Icons.refresh,
                color: AppColors.dashboardTeal,
                size: 24,
              ),
      ),
    );
  }
}

enum _ProspectHeaderMenuAction {
  changeCompany,
  createProspect;

  String get label {
    return switch (this) {
      _ProspectHeaderMenuAction.changeCompany => 'Ganti perusahaan',
      _ProspectHeaderMenuAction.createProspect => 'Tambah prospect',
    };
  }
}

class _HeaderMenuButton extends ConsumerWidget {
  const _HeaderMenuButton();

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    _ProspectHeaderMenuAction action,
  ) async {
    switch (action) {
      case _ProspectHeaderMenuAction.changeCompany:
        await _changeCompany(context, ref);
      case _ProspectHeaderMenuAction.createProspect:
        context.push(RouteNames.prospectCreate);
    }
  }

  Future<void> _changeCompany(BuildContext context, WidgetRef ref) async {
    final companies = ref.read(prospectCompanyOptionsProvider);
    if (companies.isEmpty) {
      AppToast.info(context, 'Daftar perusahaan tidak tersedia.');
      return;
    }

    final selectedCompany = ref.read(prospectSelectedCompanyProvider);
    final selected = await SelectionBottomSheet.show(
      context,
      title: 'Ganti perusahaan',
      options: companies,
      selectedOption: selectedCompany,
      labelBuilder: (company) => company.name,
    );

    if (!context.mounted || selected == null) return;

    ref.read(prospectSelectedCompanyIdProvider.notifier).state = selected.id;
    ref.invalidate(prospectPipelineProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPopupMenuButton<_ProspectHeaderMenuAction>(
      items: _ProspectHeaderMenuAction.values,
      labelBuilder: (action) => action.label,
      iconColor: AppColors.dashboardTeal,
      fontFamily: ProspectKanbanPage._fontFamily,
      onSelected: (action) => _handleMenuAction(context, ref, action),
    );
  }
}

class _KanbanStage extends StatelessWidget {
  const _KanbanStage({
    required this.stage,
    required this.mutatingProspectIds,
    required this.onMoveProspect,
    required this.onDragMove,
    required this.onDragEnd,
  });

  final ProspectStage stage;
  final Set<String> mutatingProspectIds;
  final Future<void> Function(ProspectProject prospect, ProspectStage stage)
  onMoveProspect;
  final ValueChanged<Offset> onDragMove;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ProspectProject>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage.stage,
      onMove: (details) => onDragMove(details.offset),
      onAcceptWithDetails: (details) => onMoveProspect(details.data, stage),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;

        return LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 306,
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                decoration: BoxDecoration(
                  color: ProspectKanbanPage._stageBackground,
                  border: active
                      ? Border.all(color: ProspectKanbanPage._accentColor)
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              stage.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontFamily: ProspectKanbanPage._fontFamily,
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _CountBadge(value: stage.totalProjects),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: stage.projects.length,
                        itemBuilder: (context, index) {
                          final prospect = stage.projects[index];
                          return _DraggableProspectCard(
                            prospect: prospect,
                            isMutating: mutatingProspectIds.contains(
                              prospect.id,
                            ),
                            onDragMove: onDragMove,
                            onDragEnd: onDragEnd,
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DraggableProspectCard extends StatelessWidget {
  const _DraggableProspectCard({
    required this.prospect,
    required this.isMutating,
    required this.onDragMove,
    required this.onDragEnd,
  });

  final ProspectProject prospect;
  final bool isMutating;
  final ValueChanged<Offset> onDragMove;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final card = _ProspectCard(prospect: prospect);

    if (isMutating) {
      return Opacity(opacity: 0.56, child: IgnorePointer(child: card));
    }

    return LongPressDraggable<ProspectProject>(
      data: prospect,
      onDragUpdate: (details) => onDragMove(details.globalPosition),
      onDragCompleted: onDragEnd,
      onDraggableCanceled: (_, _) => onDragEnd(),
      onDragEnd: (_) => onDragEnd(),
      feedback: Material(
        color: AppColors.transparent,
        child: SizedBox(width: 290, child: _ProspectCard(prospect: prospect)),
      ),
      childWhenDragging: Opacity(opacity: 0.32, child: card),
      child: card,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: ProspectKanbanPage._fontFamily,
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ProspectCard extends StatelessWidget {
  const _ProspectCard({required this.prospect});

  final ProspectProject prospect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(
          RouteNames.prospectDetail,
          extra: prospect.toDetailData(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prospect.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: ProspectKanbanPage._fontFamily,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              if (prospect.description != null &&
                  prospect.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  prospect.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: ProspectKanbanPage._fontFamily,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, thickness: 1, color: AppColors.line),
              const SizedBox(height: AppSpacing.md),
              Text(
                prospect.displayClient,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: ProspectKanbanPage._fontFamily,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Flexible(
                    child: _DateChip(
                      label: prospect.dateRange,
                      color: _statusColor(prospect),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Image.asset(
                    AssetPaths.iconPaperclip,
                    width: 16,
                    height: 16,
                    color: ProspectKanbanPage._accentColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    prospect.attachments,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontFamily: ProspectKanbanPage._fontFamily,
                      fontSize: 14,
                      height: 1.43,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (color) {
      ProspectKanbanPage._warningColor =>
        ProspectKanbanPage._warningChipBackground,
      ProspectKanbanPage._dangerColor =>
        ProspectKanbanPage._dangerChipBackground,
      _ => ProspectKanbanPage._chipBackground,
    };

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: ProspectKanbanPage._fontFamily,
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on ProspectStage {
  String get title => stageName.isEmpty ? stage : stageName;
}

extension on ProspectProject {
  String get title => name.isEmpty ? code : name;
  String get displayClient => client?.name ?? '-';
  String get dateRange => _dateRange(projectStartDate, projectEndDate);
  String get attachments =>
      '$totalUploadedDocuments/$totalDocumentRequirements';

  ProspectDetailData toDetailData() {
    return ProspectDetailData(
      id: id,
      currentStageValue: stage,
      stage: stageName.isEmpty ? stage : stageName,
      title: title,
      client: displayClient,
      dateRange: dateRange,
      projectValue: _currency(estimatedValue),
      description: description ?? '-',
      availableStages: const [],
      documents: const [],
      stageHistory: [
        StageHistoryData(
          stage: stageName.isEmpty ? stage : stageName,
          date: _shortDate(updatedAt ?? createdAt),
          isCurrent: true,
        ),
      ],
    );
  }
}

Color _statusColor(ProspectProject prospect) {
  final deadline = parseApiDateTime(prospect.tenderSubmissionDeadline);
  if (deadline == null) {
    return ProspectKanbanPage._accentColor;
  }

  final remaining = deadline.difference(DateTime.now()).inDays;
  if (remaining < 0) {
    return ProspectKanbanPage._dangerColor;
  }
  if (remaining <= 7) {
    return ProspectKanbanPage._warningColor;
  }

  return ProspectKanbanPage._accentColor;
}

String _errorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }

  return error.toString();
}

String _dateRange(String? start, String? end) {
  final startLabel = _shortDate(start);
  final endLabel = _shortDate(end);
  if (startLabel == '-' && endLabel == '-') {
    return '-';
  }

  return '$startLabel - $endLabel';
}

String _shortDate(String? value) {
  final date = parseApiDateTime(value);
  if (date == null) {
    return '-';
  }

  const months = [
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

  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

String _currency(num? value) {
  if (value == null) {
    return '-';
  }

  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp $buffer';
}
