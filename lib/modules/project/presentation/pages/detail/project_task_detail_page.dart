import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/core/network/server_refresh_delay.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:curva_mobile/shared/widgets/app_confirmation_dialog.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_assignee_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_report_page.dart';
import 'package:curva_mobile/modules/project/presentation/widgets/project_manpower_form_bottom_sheet.dart';
import 'package:curva_mobile/modules/project/presentation/widgets/project_target_icon.dart';

class ProjectTaskDetailPage extends ConsumerStatefulWidget {
  const ProjectTaskDetailPage({required this.detail, super.key});

  final ProjectTaskDetailData detail;

  static const _backgroundColor = AppColors.white;

  @override
  ConsumerState<ProjectTaskDetailPage> createState() =>
      _ProjectTaskDetailPageState();
}

class _ProjectTaskDetailPageState extends ConsumerState<ProjectTaskDetailPage> {
  ProjectTaskDetailData? _loadedDetail;
  final Set<String> _deletingManpowerIds = {};
  bool _isDelegating = false;
  late bool isEditMode;
  bool? _lastIsDraft;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.detail.isDraft;
    _lastIsDraft = widget.detail.isApiDetail ? widget.detail.isDraft : null;
  }

  Future<void> _editManpower(ProjectTaskManpower manpower) async {
    final detail = _loadedDetail ?? widget.detail;
    final employee = manpower.employee;
    if (!isEditMode || employee == null || manpower.id.isEmpty) return;
    final assignee = await Navigator.of(context).push<ProjectManpowerAssignee>(
      MaterialPageRoute(
        builder: (_) =>
            ProjectManpowerAssigneePickerPage(projectId: detail.projectId),
      ),
    );
    if (!mounted || assignee == null) return;

    final message = await ProjectManpowerFormBottomSheet.show(
      context,
      projectId: detail.projectId,
      taskId: detail.taskId,
      assignee: assignee,
      maxTargetVolume: detail.availableTargetVolume + manpower.targetVolume,
      manpower: manpower,
    );
    if (!mounted || message == null) return;
    await _refreshAfterManpowerReport();
    if (mounted) AppToast.success(context, message);
  }

  Future<void> _refreshAfterManpowerReport() async {
    final detail = _loadedDetail ?? widget.detail;
    await waitForServerRefresh();
    if (!mounted) return;

    final query = ProjectTaskQuery(
      projectId: detail.projectId,
      taskId: detail.taskId,
    );
    setState(() => _loadedDetail = null);
    ref
      ..invalidate(projectTaskDetailProvider(query))
      ..invalidate(projectTasksProvider)
      ..invalidate(projectTaskChildrenProvider)
      ..invalidate(projectDetailProvider(detail.projectId));
  }

  bool _canShowAddManpower(ProjectTaskDetailData detail) =>
      (isEditMode || (!detail.isDraft && detail.manpower.isEmpty)) &&
      detail.canAddManpower;

  Future<void> _addManpower() async {
    final detail = _loadedDetail ?? widget.detail;
    if (!_canShowAddManpower(detail)) return;
    final availableTargetVolume = detail.availableTargetVolume;
    final assignee = await Navigator.of(context).push<ProjectManpowerAssignee>(
      MaterialPageRoute(
        builder: (_) =>
            ProjectManpowerAssigneePickerPage(projectId: detail.projectId),
      ),
    );
    if (!mounted || assignee == null) return;

    final message = await ProjectManpowerFormBottomSheet.show(
      context,
      projectId: detail.projectId,
      taskId: detail.taskId,
      assignee: assignee,
      maxTargetVolume: availableTargetVolume,
    );
    if (!mounted || message == null) return;
    setState(() => isEditMode = true);
    await waitForServerRefresh();
    if (!mounted) return;
    final query = ProjectTaskQuery(
      projectId: detail.projectId,
      taskId: detail.taskId,
    );
    setState(() => _loadedDetail = null);
    ref
      ..invalidate(projectTaskDetailProvider(query))
      ..invalidate(projectTasksProvider)
      ..invalidate(projectTaskChildrenProvider)
      ..invalidate(projectDetailProvider(detail.projectId));
    AppToast.success(context, message);
  }

  Future<void> _deleteManpower(ProjectTaskManpower manpower) async {
    if (!isEditMode || !manpower.canDelete) return;
    final detail = _loadedDetail ?? widget.detail;
    final employeeName = manpower.employee?.name.trim() ?? '';
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: employeeName.isEmpty
          ? 'Hapus manpower ini?'
          : 'Hapus manpower $employeeName?',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, hapus',
    );
    if (!mounted || confirmed != true) return;

    setState(() => _deletingManpowerIds.add(manpower.id));
    try {
      final message = await ref
          .read(projectRepositoryProvider)
          .deleteTaskManpower(
            projectId: detail.projectId,
            taskId: detail.taskId,
            manpowerTaskId: manpower.id,
          );
      await waitForServerRefresh();
      if (!mounted) return;

      final query = ProjectTaskQuery(
        projectId: detail.projectId,
        taskId: detail.taskId,
      );
      setState(() => _loadedDetail = null);
      ref
        ..invalidate(projectTaskDetailProvider(query))
        ..invalidate(projectTasksProvider)
        ..invalidate(projectTaskChildrenProvider)
        ..invalidate(projectDetailProvider(detail.projectId));
      AppToast.success(context, message ?? 'Manpower berhasil dihapus.');
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _deletingManpowerIds.remove(manpower.id));
      }
    }
  }

  Future<void> _delegateFinalTask() async {
    final detail = _loadedDetail ?? widget.detail;
    if (!isEditMode || !detail.canAssignDraftManpower) return;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Assign manpower ke task ini?',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, assign',
    );
    if (!mounted || confirmed != true) return;

    setState(() => _isDelegating = true);
    try {
      final message = await ref
          .read(projectRepositoryProvider)
          .delegateFinalTask(
            projectId: detail.projectId,
            taskId: detail.taskId,
          );
      await waitForServerRefresh();
      if (!mounted) return;

      final query = ProjectTaskQuery(
        projectId: detail.projectId,
        taskId: detail.taskId,
      );
      setState(() => _loadedDetail = null);
      ref
        ..invalidate(projectTaskDetailProvider(query))
        ..invalidate(projectTasksProvider)
        ..invalidate(projectTaskChildrenProvider)
        ..invalidate(projectDetailProvider(detail.projectId));
      AppToast.success(context, message ?? 'Manpower berhasil di-assign.');
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    } finally {
      if (mounted) {
        setState(() {
          _isDelegating = false;
          isEditMode = false;
          _lastIsDraft = detail.isDraft;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ProjectTaskDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.taskId != widget.detail.taskId) {
      _loadedDetail = null;
      isEditMode = widget.detail.isDraft;
      _lastIsDraft = widget.detail.isApiDetail ? widget.detail.isDraft : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final displayedDetail = _loadedDetail ?? detail;
    final canAssignDraftManpower =
        isEditMode && displayedDetail.canAssignDraftManpower;
    final showAddManpower = _canShowAddManpower(displayedDetail);

    return Scaffold(
      backgroundColor: ProjectTaskDetailPage._backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Detail', onBackPressed: () => context.pop()),
            Expanded(
              child: detail.canLoadFromApi
                  ? _ProjectTaskDetailLoader(
                      initialDetail: detail,
                      isEditMode: isEditMode,
                      onEditManpower: _editManpower,
                      deletingManpowerIds: _deletingManpowerIds,
                      onDeleteManpower: _deleteManpower,
                      onReportSubmitted: _refreshAfterManpowerReport,
                      onLoaded: (loadedDetail) {
                        final currentDetail = _loadedDetail;
                        final hasChanged =
                            currentDetail == null ||
                            currentDetail.taskId != loadedDetail.taskId ||
                            currentDetail.version != loadedDetail.version ||
                            currentDetail.childCount !=
                                loadedDetail.childCount ||
                            currentDetail.isFinalLevel !=
                                loadedDetail.isFinalLevel ||
                            currentDetail.canAssign != loadedDetail.canAssign ||
                            currentDetail.canAssignDraft !=
                                loadedDetail.canAssignDraft ||
                            currentDetail.isDraft != loadedDetail.isDraft ||
                            currentDetail.hasDraftManpower !=
                                loadedDetail.hasDraftManpower ||
                            currentDetail.manpower.length !=
                                loadedDetail.manpower.length ||
                            currentDetail.maxTargetVolume !=
                                loadedDetail.maxTargetVolume;
                        if (mounted && hasChanged) {
                          setState(() {
                            _loadedDetail = loadedDetail;
                            if (_lastIsDraft != loadedDetail.isDraft) {
                              isEditMode = loadedDetail.isDraft;
                              _lastIsDraft = loadedDetail.isDraft;
                            }
                          });
                        }
                      },
                    )
                  : _ProjectTaskDetailContent(
                      detail: detail,
                      isEditMode: isEditMode,
                      onEditManpower: _editManpower,
                      deletingManpowerIds: _deletingManpowerIds,
                      onDeleteManpower: _deleteManpower,
                      onReportSubmitted: _refreshAfterManpowerReport,
                    ),
            ),
            if (displayedDetail.isLeaf &&
                (showAddManpower || canAssignDraftManpower))
              SafeArea(
                top: false,
                child: _BottomAction(
                  showAddManpower: showAddManpower,
                  showAssignee: canAssignDraftManpower,
                  isAssigneeLoading: _isDelegating,
                  onAddManpower: _isDelegating ? null : _addManpower,
                  onAssignee: _isDelegating ? null : _delegateFinalTask,
                ),
              ),
            if (displayedDetail.isLeaf &&
                !displayedDetail.isDraft &&
                !isEditMode &&
                displayedDetail.hasDraftManpower)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    label: 'Edit',
                    variant: AppButtonVariant.outlined,
                    borderColor: AppColors.dashboardTeal,
                    textStyle: const TextStyle(
                      color: AppColors.dashboardTeal,
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () => setState(() => isEditMode = true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTaskDetailLoader extends ConsumerWidget {
  const _ProjectTaskDetailLoader({
    required this.isEditMode,
    required this.onEditManpower,
    required this.initialDetail,
    required this.deletingManpowerIds,
    required this.onDeleteManpower,
    required this.onReportSubmitted,
    required this.onLoaded,
  });

  final ProjectTaskDetailData initialDetail;
  final bool isEditMode;
  final Future<void> Function(ProjectTaskManpower) onEditManpower;
  final Set<String> deletingManpowerIds;
  final Future<void> Function(ProjectTaskManpower) onDeleteManpower;
  final Future<void> Function() onReportSubmitted;
  final ValueChanged<ProjectTaskDetailData> onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ProjectTaskQuery(
      projectId: initialDetail.projectId,
      taskId: initialDetail.taskId,
    );
    final detailState = ref.watch(projectTaskDetailProvider(query));

    return detailState.when(
      loading: () => const AppSkeletonDetailView(),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        cacheFeatureKey: 'projectCacheRead',
        message: error.toString(),
        onRetry: () => ref.invalidate(projectTaskDetailProvider(query)),
      ),
      data: (task) {
        final detail = ProjectTaskDetailData.fromTask(
          task,
          fallbackProjectId: initialDetail.projectId,
          fallbackTaskId: initialDetail.taskId,
          fallbackChildCount: initialDetail.childCount,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onLoaded(detail);
        });
        return RefreshIndicator(
          onRefresh: () => ref.refresh(projectTaskDetailProvider(query).future),
          child: _ProjectTaskDetailContent(
            detail: detail,
            isEditMode: isEditMode,
            onEditManpower: onEditManpower,
            deletingManpowerIds: deletingManpowerIds,
            onDeleteManpower: onDeleteManpower,
            onReportSubmitted: onReportSubmitted,
          ),
        );
      },
    );
  }
}

class _ProjectTaskDetailContent extends StatelessWidget {
  const _ProjectTaskDetailContent({
    required this.isEditMode,
    required this.onEditManpower,
    required this.detail,
    required this.deletingManpowerIds,
    required this.onDeleteManpower,
    required this.onReportSubmitted,
  });

  final ProjectTaskDetailData detail;
  final bool isEditMode;
  final Future<void> Function(ProjectTaskManpower) onEditManpower;
  final Set<String> deletingManpowerIds;
  final Future<void> Function(ProjectTaskManpower) onDeleteManpower;
  final Future<void> Function() onReportSubmitted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        if (!detail.isLeaf)
          _ParentTaskDetailContent(detail: detail)
        else ...[
          _LeafTaskDetailContent(detail: detail),
          _ManpowerSection(
            detail: detail,
            isEditMode: isEditMode,
            onEditManpower: onEditManpower,
            deletingManpowerIds: deletingManpowerIds,
            onDeleteManpower: onDeleteManpower,
            onReportSubmitted: onReportSubmitted,
          ),
        ],
      ],
    );
  }
}

class _ParentTaskDetailContent extends StatelessWidget {
  const _ParentTaskDetailContent({required this.detail});

  final ProjectTaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailField(label: 'Job/Item', value: detail.jobItem),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Status',
                  value: detail.status,
                  valueColor: AppColors.orange,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(label: 'Assign', value: detail.assignee),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Progres', value: detail.progress),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Last Update',
                  value: detail.updatedDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(label: 'Catatan', value: detail.note),
        ],
      ),
    );
  }
}

class _LeafTaskDetailContent extends StatelessWidget {
  const _LeafTaskDetailContent({required this.detail});

  final ProjectTaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailField(label: 'Job/Item', value: detail.jobItem),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Status',
            value: detail.status,
            valueColor: AppColors.orange,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Durasi', value: detail.duration),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Volume BOQ',
                  value: detail.boqVolume,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Progress saat ini',
                  value: detail.currentProgress,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Last Update',
                  value: detail.updatedDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManpowerSection extends StatelessWidget {
  const _ManpowerSection({
    required this.isEditMode,
    required this.onEditManpower,
    required this.detail,
    required this.deletingManpowerIds,
    required this.onDeleteManpower,
    required this.onReportSubmitted,
  });

  final ProjectTaskDetailData detail;
  final bool isEditMode;
  final Future<void> Function(ProjectTaskManpower) onEditManpower;
  final Set<String> deletingManpowerIds;
  final Future<void> Function(ProjectTaskManpower) onDeleteManpower;
  final Future<void> Function() onReportSubmitted;

  static const _items = [
    _ManpowerItem(
      initials: 'AG',
      name: 'Agung Prasetyo',
      avatarColor: AppColors.assigneePurple,
      status: 'Belum Dilaporkan',
      helpers: 'Budi, 2+',
      target: '5 m³',
      note: 'Sebelah Kanan',
    ),
    _ManpowerItem(
      initials: 'AR',
      name: 'Arish Noah',
      avatarColor: AppColors.assigneeGreen,
      status: 'Belum Dilaporkan',
      helpers: 'Yugi',
      target: '3 m³',
      note: 'Sebelah Kiri',
    ),
    _ManpowerItem(
      initials: 'DI',
      name: 'Dimas Masdim',
      avatarColor: AppColors.assigneeMagenta,
      status: 'Belum Dilaporkan',
      helpers: 'Yugo',
      target: '2 m³',
      note: 'Bagian Depan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      hasBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Manpower'),
          if (detail.isApiDetail)
            if (detail.manpower.isEmpty)
              const _EmptyManpowerState()
            else ...[
              const SizedBox(height: AppSpacing.md),
              for (var index = 0; index < detail.manpower.length; index++) ...[
                _ManpowerCard(
                  item: _ManpowerItem.fromApi(
                    detail.manpower[index],
                    projectId: detail.projectId,
                    unit: detail.unit,
                  ),
                  isDeleting: deletingManpowerIds.contains(
                    detail.manpower[index].id,
                  ),
                  onDelete:
                      isEditMode &&
                          detail.manpower[index].canDelete &&
                          detail.manpower[index].id.isNotEmpty
                      ? () => onDeleteManpower(detail.manpower[index])
                      : null,
                  isEditMode: isEditMode,
                  onEdit:
                      detail.manpower[index].canDelete &&
                          detail.manpower[index].id.isNotEmpty &&
                          detail.manpower[index].employee != null
                      ? () => onEditManpower(detail.manpower[index])
                      : null,
                  onReportSubmitted: onReportSubmitted,
                ),
                if (index != detail.manpower.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ]
          else ...[
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < _items.length; index++) ...[
              _ManpowerCard(
                item: _items[index],
                onReportSubmitted: onReportSubmitted,
              ),
              if (index != _items.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyManpowerState extends StatelessWidget {
  const _EmptyManpowerState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 32, color: AppColors.muted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Anda belum menambahkan\n'
              'manpower,silahkan tambah manpower\n'
              'untuk assignee tugas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontFamily: AppFonts.inter,
                fontSize: 16,
                height: 1.75,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManpowerItem {
  const _ManpowerItem({
    required this.initials,
    required this.name,
    required this.avatarColor,
    required this.status,
    required this.helpers,
    required this.target,
    required this.note,
    this.retryCount = 0,
    this.projectId = '',
    this.taskId = '',
    this.canSubmit = true,
  });

  final String initials;
  final String name;
  final Color avatarColor;
  final String status;
  final String helpers;
  final String target;
  final String note;
  final int retryCount;
  final String projectId;
  final String taskId;
  final bool canSubmit;

  factory _ManpowerItem.fromApi(
    ProjectTaskManpower manpower, {
    required String projectId,
    required String unit,
  }) {
    final employee = manpower.employee;
    final helpers = manpower.helpers;
    final helperLabel = helpers.isEmpty
        ? '-'
        : helpers.length == 1
        ? helpers.first.name
        : '${helpers.first.name}, ${helpers.length - 1}+';
    return _ManpowerItem(
      initials: employee?.initials ?? '-',
      name: employee?.name.isNotEmpty == true ? employee!.name : '-',
      avatarColor: _manpowerAvatarColor(
        '${employee?.id ?? ''}${employee?.name ?? ''}',
      ),
      status: manpower.statusLabel.isNotEmpty
          ? manpower.statusLabel
          : manpower.status,
      helpers: helperLabel,
      target: _formatTaskVolume(manpower.targetVolume, unit),
      note: manpower.note ?? '-',
      retryCount: manpower.retryCount,
      projectId: projectId,
      taskId: manpower.id,
      canSubmit: manpower.canSubmit,
    );
  }
}

class _ManpowerCard extends ConsumerWidget {
  const _ManpowerCard({
    required this.item,
    required this.onReportSubmitted,
    this.onDelete,
    this.isDeleting = false,
    this.isEditMode = false,
    this.onEdit,
  });

  final _ManpowerItem item;
  final Future<void> Function() onReportSubmitted;
  final VoidCallback? onDelete;
  final bool isDeleting;
  final bool isEditMode;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = item.projectId.isNotEmpty && item.taskId.isNotEmpty
        ? ref
              .watch(
                projectTargetOperationProvider(
                  ProjectTargetOperationQuery(
                    operationType: SyncOperationType.projectTaskDone,
                    targetResourceKey:
                        'project:${item.projectId}:task:${item.taskId}',
                  ),
                ),
              )
              .valueOrNull
        : null;
    final status = switch (overlay?.state) {
      OutboxState.pending || OutboxState.retry => 'Menunggu sinkronisasi',
      OutboxState.processing => 'Sedang menyinkronkan',
      OutboxState.conflict => 'Data berubah di server',
      OutboxState.failed || OutboxState.rejected => 'Laporan perlu diperiksa',
      _ => item.status,
    };
    final isEditDisabled = isEditMode && onEdit == null;
    return Material(
      color: isEditDisabled ? const Color(0xFFF3F4F6) : AppColors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.tabBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDeleting
            ? null
            : isEditMode
            ? onEdit
            : () async {
                final submitted = await context.push<bool>(
                  RouteNames.projectManpowerReport,
                  extra: item.projectId.isNotEmpty && item.taskId.isNotEmpty
                      ? ProjectManpowerReportArgs(
                          projectId: item.projectId,
                          taskId: item.taskId,
                          manpowerName: item.name,
                          canSubmit: item.canSubmit,
                        )
                      : item.name,
                );
                if (submitted == true) await onReportSubmitted();
              },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: item.avatarColor,
                    child: Text(
                      item.initials,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontFamily: AppFonts.geist,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.expenseText,
                        fontFamily: AppFonts.geist,
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Hapus manpower ${item.name}',
                      onPressed: isDeleting || overlay != null
                          ? null
                          : onDelete,
                      visualDensity: VisualDensity.compact,
                      icon: isDeleting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(CupertinoIcons.delete, size: 22),
                      color: AppColors.muted,
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppColors.tabBorder),
              ),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  _ManpowerInfo(
                    leading: const Icon(Icons.description_outlined, size: 16),
                    label: status,
                    showBorder: true,
                    iconColor: AppColors.muted,
                  ),
                  _ManpowerInfo(
                    leading: const Icon(Icons.people_outline, size: 16),
                    label: item.helpers,
                  ),
                  _ManpowerInfo(
                    leading: const ProjectTargetIcon(size: 16),
                    label: item.target,
                  ),
                  _ManpowerInfo(
                    leading: const Icon(Icons.sync, size: 16),
                    label: '${item.retryCount}x',
                  ),
                  _ManpowerInfo(
                    leading: const Icon(Icons.notes_outlined, size: 16),
                    label: item.note,
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

class _ManpowerInfo extends StatelessWidget {
  const _ManpowerInfo({
    required this.leading,
    required this.label,
    this.showBorder = false,
    this.iconColor = AppColors.dashboardTeal,
  });

  final Widget leading;
  final String label;
  final bool showBorder;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: showBorder
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : EdgeInsets.zero,
      decoration: showBorder
          ? BoxDecoration(
              color: AppColors.cardBackground,
              border: Border.all(color: AppColors.muted),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: iconColor),
            child: leading,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.geist,
                fontSize: 12,
                height: 1.33,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.hasBorder = true});

  final Widget child;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: hasBorder
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: child,
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.muted,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: AppFonts.inter,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: AppFonts.inter,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.showAddManpower,
    required this.showAssignee,
    required this.isAssigneeLoading,
    required this.onAddManpower,
    required this.onAssignee,
  });

  final bool showAddManpower;
  final bool showAssignee;
  final bool isAssigneeLoading;
  final VoidCallback? onAddManpower;
  final VoidCallback? onAssignee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(color: AppColors.white),
      child: Row(
        children: [
          if (showAddManpower)
            Expanded(
              child: AppButton(
                label: 'Add Manpower',
                variant: showAssignee
                    ? AppButtonVariant.outlined
                    : AppButtonVariant.primary,
                backgroundColor: AppColors.dashboardTeal,
                borderColor: AppColors.dashboardTeal,
                textStyle: _buttonTextStyle(
                  showAssignee ? AppColors.dashboardTeal : AppColors.white,
                ),
                onPressed: onAddManpower,
              ),
            ),
          if (showAddManpower && showAssignee)
            const SizedBox(width: AppSpacing.md),
          if (showAssignee)
            Expanded(
              child: AppButton(
                label: 'Assignee',
                isLoading: isAssigneeLoading,
                backgroundColor: AppColors.dashboardTeal,
                textStyle: _buttonTextStyle(AppColors.white),
                onPressed: onAssignee,
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _buttonTextStyle(Color color) {
    return TextStyle(
      color: color,
      fontFamily: AppFonts.inter,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
  }
}

class ProjectTaskDetailData {
  const ProjectTaskDetailData({
    this.projectId = '',
    this.taskId = '',
    this.isQc = false,
    this.statusKey = '',
    this.canSubmitFromApi,
    this.canAssign = false,
    this.canAssignDraft = false,
    this.isDraft = false,
    this.isFinalLevel,
    this.isApiDetail = false,
    this.manpower = const [],
    this.unit = '',
    this.volumeBoq = 0,
    this.maxTargetVolume = 0,
    this.version = 0,
    this.childCount = 0,
    this.qcOwnerId = '',
    this.qcOwnerName = '',
    this.note = '-',
    this.helperSummary = '-',
    this.target = '-',
    this.completedVolume = '-',
    this.supervisorNote = '-',
    this.manpowerNote = '-',
    this.reportedDate = '-',
    this.progress = '-',
    this.duration = '-',
    this.boqVolume = '-',
    this.currentProgress = '-',
    required this.code,
    required this.task,
    required this.creator,
    required this.createdDate,
    required this.status,
    required this.assignee,
    required this.updatedDate,
    required this.previousEvidence,
    required this.updatedEvidence,
    required this.qcApproval,
    required this.qcUpdateDate,
    required this.qcStatus,
    required this.qcNote,
    required this.qcEvidence,
  });

  final String projectId;
  final String taskId;
  final bool isQc;
  final String statusKey;
  final bool? canSubmitFromApi;
  final bool canAssign;
  final bool canAssignDraft;
  final bool isDraft;
  final bool? isFinalLevel;
  final bool isApiDetail;
  final List<ProjectTaskManpower> manpower;
  final String unit;
  final double volumeBoq;
  final double maxTargetVolume;
  final int version;
  final int childCount;
  final String qcOwnerId;
  final String qcOwnerName;
  final String note;
  final String helperSummary;
  final String target;
  final String completedVolume;
  final String supervisorNote;
  final String manpowerNote;
  final String reportedDate;
  final String progress;
  final String duration;
  final String boqVolume;
  final String currentProgress;
  final String code;
  final String task;
  final String creator;
  final String createdDate;
  final String status;
  final String assignee;
  final String updatedDate;
  final List<TaskEvidenceAttachment> previousEvidence;
  final List<TaskEvidenceAttachment> updatedEvidence;
  final String qcApproval;
  final String qcUpdateDate;
  final String qcStatus;
  final String qcNote;
  final List<TaskEvidenceAttachment> qcEvidence;

  bool get isLeaf => isFinalLevel ?? childCount == 0;
  bool get hasChild => !isLeaf;
  bool get hasDraftManpower => manpower.any((item) => item.canDelete);
  bool get canAssignDraftManpower => canAssignDraft && hasDraftManpower;
  double get availableTargetVolume {
    if (volumeBoq <= 0) return maxTargetVolume;
    final allocatedVolume = manpower.fold<double>(
      0,
      (total, item) => total + item.targetVolume,
    );
    final remainingVolume = volumeBoq - allocatedVolume;
    if (remainingVolume <= 0) return 0;
    if (maxTargetVolume > 0 && maxTargetVolume < remainingVolume) {
      return maxTargetVolume;
    }
    return remainingVolume;
  }

  bool get canAddManpower => canAssignDraft && availableTargetVolume > 0;
  String get jobItem => '$code · $task';
  bool get canLoadFromApi => projectId.isNotEmpty && taskId.isNotEmpty;
  bool get canSubmit =>
      !isQc &&
      (canSubmitFromApi ?? const {'created', 'reopened'}.contains(statusKey));

  bool get hasQcFeedback =>
      qcApproval != '-' ||
      qcStatus.isNotEmpty ||
      qcNote != '-' ||
      qcEvidence.isNotEmpty;

  bool isQcOwnedByName(String? accountName) {
    final normalizedOwnerName = qcOwnerName.trim().toLowerCase();
    final normalizedAccountName = accountName?.trim().toLowerCase() ?? '';
    return normalizedOwnerName.isNotEmpty &&
        normalizedAccountName.isNotEmpty &&
        normalizedOwnerName == normalizedAccountName;
  }

  factory ProjectTaskDetailData.fromTask(
    ProjectTask task, {
    bool isQc = false,
    String fallbackProjectId = '',
    String fallbackTaskId = '',
    int fallbackChildCount = 0,
  }) {
    final firstAssignee =
        task.assignee ?? (task.assignees.isEmpty ? null : task.assignees.first);
    final qcOwner = task.qcOwner ?? (isQc ? firstAssignee : null);
    final unit = _taskUnit(task.uom);
    final progressMaximum = task.volumeBoq > 0
        ? task.volumeBoq
        : task.maxTargetVolume;
    final progress = _formatTaskProgress(
      task.currentProgress,
      progressMaximum,
      unit,
    );

    return ProjectTaskDetailData(
      projectId: task.projectId.isNotEmpty ? task.projectId : fallbackProjectId,
      taskId: task.id.isNotEmpty ? task.id : fallbackTaskId,
      isQc: isQc,
      statusKey: task.status.toLowerCase(),
      canSubmitFromApi: task.canSubmit,
      canAssign: task.canAssign,
      canAssignDraft: task.canAssignDraft,
      isDraft: task.isDraft,
      isFinalLevel: task.isFinalLevel,
      isApiDetail: true,
      manpower: task.manpower,
      unit: unit,
      volumeBoq: task.volumeBoq,
      maxTargetVolume: task.maxTargetVolume,
      version: task.version,
      childCount: task.childCount > 0 ? task.childCount : fallbackChildCount,
      qcOwnerId: qcOwner?.id ?? '',
      qcOwnerName: qcOwner?.name ?? '',
      note: task.description?.trim().isNotEmpty == true
          ? task.description!.trim()
          : '-',
      helperSummary: _formatQcHelpers(task.helpers),
      target: _formatTaskVolume(task.targetVolume, unit),
      completedVolume: _formatTaskVolume(task.completedVolume, unit),
      supervisorNote: task.note?.trim().isNotEmpty == true
          ? task.note!.trim()
          : '-',
      manpowerNote: task.manpowerNote?.trim().isNotEmpty == true
          ? task.manpowerNote!.trim()
          : '-',
      reportedDate: _formatProjectDate(task.createdAt),
      progress: progress,
      duration: task.durationDays == null ? '-' : '${task.durationDays} hari',
      boqVolume: _formatTaskVolume(task.volumeBoq, unit),
      currentProgress: progress,
      code: task.code.isNotEmpty ? task.code : '-',
      task: task.title.isNotEmpty ? task.title : '-',
      creator: task.creator?.name ?? '-',
      createdDate: _formatProjectDate(task.createdAt),
      status: task.statusLabel.isNotEmpty ? task.statusLabel : task.status,
      assignee: firstAssignee?.name ?? '-',
      updatedDate: _formatProjectDate(
        task.updatedAt ?? task.assignDate ?? task.doneAt ?? task.createdAt,
      ),
      previousEvidence: task.previousEvidence
          .map(TaskEvidenceAttachment.fromProjectAttachment)
          .toList(growable: false),
      updatedEvidence: task.updatedEvidence
          .map(TaskEvidenceAttachment.fromProjectAttachment)
          .toList(growable: false),
      qcApproval: task.qcApproval?.name ?? '-',
      qcUpdateDate: _formatProjectDate(task.qcUpdatedAt),
      qcStatus: task.qcStatus,
      qcNote: task.qcNote ?? '-',
      qcEvidence: task.qcEvidence
          .map(TaskEvidenceAttachment.fromProjectAttachment)
          .toList(growable: false),
    );
  }

  factory ProjectTaskDetailData.fallback() {
    return ProjectTaskDetailData.sample(
      code: 'A.1.1.1.1',
      task: 'Penataan Bata Dinding',
    );
  }

  factory ProjectTaskDetailData.sample({
    required String code,
    required String task,
    int childCount = 0,
  }) {
    return ProjectTaskDetailData(
      canAssign: true,
      canAssignDraft: true,
      isDraft: true,
      volumeBoq: 10,
      maxTargetVolume: 10,
      childCount: childCount,
      duration: '5 hari',
      boqVolume: '10 m³',
      currentProgress: '0/10 m³',
      code: code,
      task: task,
      creator: 'Agung Prasetyo',
      createdDate: '1 Jun 2026',
      status: 'Proses QC',
      assignee: 'Arish',
      updatedDate: '22 Jun 2026',
      previousEvidence: const [
        TaskEvidenceAttachment(
          name: 'img-src-200626.jpg',
          size: '89.5 KB',
          thumbnailColor: AppColors.attachmentBrown,
        ),
        TaskEvidenceAttachment(
          name: 'img-src-200627.jpg',
          size: '89.5 KB',
          thumbnailColor: AppColors.attachmentTaupe,
        ),
      ],
      updatedEvidence: const [
        TaskEvidenceAttachment(
          name: 'img-src-200628.jpg',
          size: '89.5 KB',
          thumbnailColor: AppColors.attachmentCopper,
        ),
      ],
      qcApproval: 'Arman Maulana',
      qcUpdateDate: '21 Jun 2026',
      qcStatus: 'Ditolak',
      qcNote:
          'In a laoreet purus. Integer turpis quam, laoreet id orci nec, ultrices lacinia nunc. Aliquam erat vo',
      qcEvidence: const [
        TaskEvidenceAttachment(
          name: 'img-src-111628.jpg',
          size: '89.5 KB',
          thumbnailColor: AppColors.attachmentDarkBrown,
        ),
      ],
    );
  }
}

String _taskUnit(ProjectTaskUom? uom) {
  final code = uom?.code.trim() ?? '';
  if (code.isNotEmpty) return code;
  return uom?.name.trim() ?? '';
}

String _formatTaskProgress(double current, double maximum, String unit) {
  final suffix = unit.isEmpty ? '' : ' $unit';
  return '${_formatTaskNumber(current)}/${_formatTaskNumber(maximum)}$suffix';
}

String _formatTaskVolume(double volume, String unit) {
  final suffix = unit.isEmpty ? '' : ' $unit';
  return '${_formatTaskNumber(volume)}$suffix';
}

String _formatTaskNumber(double value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatQcHelpers(List<ProjectReference> helpers) {
  final names = helpers
      .map((helper) => helper.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (names.isEmpty) return '-';
  return names.length > 1 ? '${names.first} +${names.length - 1}' : names.first;
}

Color _manpowerAvatarColor(String value) {
  const colors = [
    AppColors.assigneePurple,
    AppColors.assigneeGreen,
    AppColors.assigneeMagenta,
  ];
  if (value.isEmpty) return colors.first;
  final index = value.codeUnits.fold<int>(0, (sum, code) => sum + code);
  return colors[index % colors.length];
}

class TaskEvidenceAttachment {
  const TaskEvidenceAttachment({
    required this.name,
    required this.size,
    this.path = '',
    required this.thumbnailColor,
  });

  final String name;
  final String size;
  final String path;
  final Color thumbnailColor;

  factory TaskEvidenceAttachment.fromProjectAttachment(
    ProjectAttachment attachment,
  ) {
    return TaskEvidenceAttachment(
      name: attachment.name,
      size: attachment.size,
      path: attachment.url,
      thumbnailColor: _attachmentColor(attachment.id + attachment.name),
    );
  }
}

Color _attachmentColor(String value) {
  const colors = [
    AppColors.attachmentBrown,
    AppColors.attachmentTaupe,
    AppColors.attachmentCopper,
    AppColors.attachmentDarkBrown,
  ];
  if (value.isEmpty) return colors.first;

  return colors[value.codeUnits.fold<int>(0, (sum, code) => sum + code) %
      colors.length];
}

String _formatProjectDate(String? value) {
  final date = parseApiDateTime(value);
  if (date == null) return '-';

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

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
