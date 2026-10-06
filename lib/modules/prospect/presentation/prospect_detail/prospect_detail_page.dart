import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/server_refresh_delay.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_underline_tabs.dart';
import '../../../../shared/widgets/app_popup_menu_button.dart';
import '../../../../shared/widgets/network_aware_error_view.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../data/models/prospect_models.dart';
import '../../data/prospect_repository.dart';
import '../../prospect_providers.dart';
import 'prospect_activity_tab.dart';
import 'prospect_detail_models.dart';
import 'prospect_detail_shared_widgets.dart';
import 'prospect_detail_tab.dart';
import 'prospect_stage_history_tab.dart';

export 'prospect_detail_models.dart';

class ProspectDetailPage extends ConsumerStatefulWidget {
  const ProspectDetailPage({required this.detail, super.key});

  final ProspectDetailData detail;

  @override
  ConsumerState<ProspectDetailPage> createState() => _ProspectDetailPageState();
}

class _ProspectDetailPageState extends ConsumerState<ProspectDetailPage> {
  bool _isMutating = false;
  var _selectedTabIndex = 0;

  Future<void> _runMutation(Future<String?> Function() action) async {
    if (_isMutating) return;

    setState(() => _isMutating = true);
    try {
      final message = await action();
      await waitForServerRefresh();
      if (!mounted) return;

      _refreshProspectProviders();
      AppToast.success(
        context,
        message ?? 'Data prospect berhasil diperbarui.',
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  void _refreshProspectProviders() {
    ref.invalidate(prospectPipelineProvider);
    ref.invalidate(prospectDetailProvider(widget.detail.id));
    ref.invalidate(prospectStageHistoryProvider(widget.detail.id));
  }

  Future<void> _updateStage(String stage) {
    return _runMutation(
      () => ref
          .read(prospectRepositoryProvider)
          .updateStage(
            prospectId: widget.detail.id,
            stage: stage,
            companyId: ref.read(prospectCompanyIdProvider),
          ),
    );
  }

  Future<void> _cancelProspect() async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Apakah anda yakin dibatalkan ?',
      cancelLabel: 'Tidak',
      confirmLabel: 'Ya, keluar',
    );

    if (confirmed != true || !mounted) return;

    return _runMutation(
      () => ref
          .read(prospectRepositoryProvider)
          .cancelProspect(
            prospectId: widget.detail.id,
            companyId: ref.read(prospectCompanyIdProvider),
          ),
    );
  }

  Future<void> _uploadDocument(
    ProspectDocumentData document,
    List<PlatformFile> files,
  ) {
    if (files.isEmpty) return Future.value();

    final uploads = [
      for (final file in files)
        ProspectFileUpload(name: file.name, path: file.path),
    ];
    final uploadedDocumentId = document.uploadedDocuments.isEmpty
        ? null
        : document.uploadedDocuments.first.id;
    if (uploadedDocumentId != null && uploadedDocumentId.isNotEmpty) {
      return _runMutation(
        () => ref
            .read(prospectRepositoryProvider)
            .updateDocument(
              prospectId: widget.detail.id,
              documentId: uploadedDocumentId,
              files: uploads,
              companyId: ref.read(prospectCompanyIdProvider),
            ),
      );
    }

    final documentTypeId = document.documentTypeId;
    if (documentTypeId == null || documentTypeId.isEmpty) {
      AppToast.info(context, 'Tipe dokumen tidak tersedia.');
      return Future.value();
    }

    return _runMutation(
      () => ref
          .read(prospectRepositoryProvider)
          .uploadDocument(
            prospectId: widget.detail.id,
            documentTypeId: documentTypeId,
            files: uploads,
            companyId: ref.read(prospectCompanyIdProvider),
          ),
    );
  }

  Future<void> _deleteDocument(
    ProspectDocumentData document,
    ProspectUploadedDocumentData uploadedDocument,
  ) {
    if (uploadedDocument.id.isEmpty) {
      return Future.value();
    }

    return _runMutation(
      () => ref
          .read(prospectRepositoryProvider)
          .deleteDocument(
            prospectId: widget.detail.id,
            documentId: uploadedDocument.id,
            companyId: ref.read(prospectCompanyIdProvider),
          ),
    );
  }

  Future<void> _saveActivity(
    String description,
    List<PlatformFile> files,
    List<StageDocumentData> deletedDocuments,
  ) {
    final uploads = [
      for (final file in files)
        ProspectFileUpload(name: file.name, path: file.path),
    ];

    return _runMutation(() async {
      final repository = ref.read(prospectRepositoryProvider);
      final companyId = ref.read(prospectCompanyIdProvider);
      final activityMessage = await repository.createActivity(
        prospectId: widget.detail.id,
        description: description,
        companyId: companyId,
      );
      String? deleteMessage;
      for (final document in deletedDocuments) {
        deleteMessage = await repository.deleteActivityDocument(
          prospectId: widget.detail.id,
          documentId: document.id,
          companyId: companyId,
        );
      }
      final uploadMessage = await repository.uploadActivityDocuments(
        prospectId: widget.detail.id,
        files: uploads,
        companyId: companyId,
      );

      return uploadMessage ?? deleteMessage ?? activityMessage;
    });
  }

  Future<void> _refreshProspect() async {
    final prospectId = widget.detail.id;
    if (prospectId.isEmpty) return;

    await Future.wait<Object?>([
      ref.refresh(prospectDetailProvider(prospectId).future),
      ref.refresh(prospectStageHistoryProvider(prospectId).future),
    ]);
  }

  Widget _refreshableTabs(ProspectDetailData detail) {
    return RefreshIndicator(
      onRefresh: _refreshProspect,
      child: _ProspectDetailTabs(
        selectedIndex: _selectedTabIndex,
        detail: detail,
        onUploadDocument: _uploadDocument,
        onDeleteDocument: _deleteDocument,
        onSaveActivity: _saveActivity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final detailState = detail.id.isEmpty
        ? null
        : ref.watch(prospectDetailProvider(detail.id));
    final stageHistoryState = detail.id.isEmpty
        ? null
        : ref.watch(prospectStageHistoryProvider(detail.id));
    final resolvedDetail =
        detailState?.maybeWhen(data: _toDetailData, orElse: () => detail) ??
        detail;
    final resolvedWithHistory =
        stageHistoryState?.maybeWhen(
          data: (history) => resolvedDetail.copyWith(
            stageHistory: _toStageHistoryData(history, resolvedDetail),
          ),
          orElse: () => resolvedDetail,
        ) ??
        resolvedDetail;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: resolvedWithHistory.stage,
              actionWidgets: [
                _ProspectHeaderMenuButton(
                  detail: resolvedWithHistory,
                  isBusy: _isMutating,
                  onUpdateStage: _updateStage,
                  onCancelProspect: _cancelProspect,
                ),
              ],
              onBackPressed: () => context.pop(),
            ),
            _ProspectTabs(
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() => _selectedTabIndex = index);
              },
            ),
            Expanded(
              child:
                  detailState?.maybeWhen(
                    error: (error, stackTrace) => NetworkAwareErrorView(
                      error: error,
                      message: _errorMessage(error),
                      onRetry: () =>
                          ref.invalidate(prospectDetailProvider(detail.id)),
                    ),
                    orElse: () => _refreshableTabs(resolvedWithHistory),
                  ) ??
                  _refreshableTabs(resolvedWithHistory),
            ),
          ],
        ),
      ),
    );
  }
}

ProspectDetailData _toDetailData(ProspectDetail detail) {
  final prospect = detail.prospect;

  return ProspectDetailData(
    id: prospect.id,
    currentStageValue: prospect.stage,
    stage: prospect.stageName.isEmpty ? prospect.stage : prospect.stageName,
    title: prospect.name.isEmpty ? prospect.code : prospect.name,
    client: prospect.client?.name ?? '-',
    dateRange: _dateRange(prospect.projectStartDate, prospect.projectEndDate),
    projectValue: _currency(prospect.estimatedValue),
    description: prospect.description ?? '-',
    availableStages: [
      for (final stage in detail.availableStages)
        ProspectStageOptionData(value: stage.value, label: stage.label),
    ],
    documents: [
      for (final document in detail.documents)
        ProspectDocumentData(
          title: document.documentType?.name ?? 'Dokumen prospect',
          requirementId: document.id,
          documentTypeId: document.documentType?.id,
          isMandatory: document.isMandatory,
          allowedFileTypes: document.documentType?.allowedFileTypes ?? '',
          allowedFileSize: document.documentType?.allowedFileSize ?? 0,
          uploadedDocuments: [
            for (final uploadedDocument in document.uploadedDocuments)
              ProspectUploadedDocumentData(
                id: uploadedDocument.id,
                name: uploadedDocument.fileName,
                size: uploadedDocument.fileSize,
                url: uploadedDocument.fileUrl,
              ),
          ],
        ),
    ],
    stageHistory: _sortStageHistoryNewestFirst([
      StageHistoryData(
        stage: prospect.stageName.isEmpty ? prospect.stage : prospect.stageName,
        date: _shortDate(prospect.updatedAt ?? prospect.createdAt),
        isCurrent: true,
        dateValue: parseApiDateTime(prospect.updatedAt ?? prospect.createdAt),
      ),
      for (final stage in detail.availableStages)
        StageHistoryData(stage: stage.label, date: '-'),
    ]),
    activityDescription: detail.activity.description,
    activityDocuments: [
      for (final document in detail.activity.documents)
        StageDocumentData(
          id: document.id,
          name: document.fileName,
          size: _fileSize(document.fileSize),
          sizeBytes: document.fileSize,
          fileUrl: document.fileUrl,
        ),
    ],
  );
}

List<StageHistoryData> _toStageHistoryData(
  List<ProspectStageHistory> history,
  ProspectDetailData fallback,
) {
  if (history.isEmpty) {
    return fallback.stageHistory;
  }

  return _sortStageHistoryNewestFirst([
    for (final item in history)
      StageHistoryData(
        stage: item.stageName.isEmpty ? item.stage : item.stageName,
        date: _shortDate(item.createdAt),
        dateValue: parseApiDateTime(item.createdAt),
        activity: item.activity?.description ?? item.description,
        isCurrent:
            item.isCurrent ||
            item.stage == fallback.currentStageValue ||
            item.stageName == fallback.stage,
        documents: [
          for (final document in item.documents)
            StageDocumentData(
              id: document.id,
              name: document.fileName,
              size: _fileSize(document.fileSize),
              sizeBytes: document.fileSize,
              fileUrl: document.fileUrl,
            ),
        ],
        activityDocuments: [
          for (final document in item.activity?.documents ?? const [])
            StageDocumentData(
              id: document.id,
              name: document.fileName,
              size: _fileSize(document.fileSize),
              sizeBytes: document.fileSize,
              fileUrl: document.fileUrl,
            ),
        ],
      ),
  ]);
}

List<StageHistoryData> _sortStageHistoryNewestFirst(
  List<StageHistoryData> history,
) {
  return [...history]..sort((first, second) {
    final firstDate = first.dateValue;
    final secondDate = second.dateValue;

    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;

    return secondDate.compareTo(firstDate);
  });
}

enum _ProspectHeaderMenuAction {
  setToNextStage,
  setToLost,
  cancelProspect;

  String get label {
    return switch (this) {
      _ProspectHeaderMenuAction.setToNextStage => 'Set to next stage',
      _ProspectHeaderMenuAction.setToLost => 'Set to lost',
      _ProspectHeaderMenuAction.cancelProspect => 'Batalkan prospect',
    };
  }
}

class _ProspectHeaderMenuButton extends StatelessWidget {
  const _ProspectHeaderMenuButton({
    required this.detail,
    required this.isBusy,
    required this.onUpdateStage,
    required this.onCancelProspect,
  });

  final ProspectDetailData detail;
  final bool isBusy;
  final Future<void> Function(String stage) onUpdateStage;
  final Future<void> Function() onCancelProspect;

  Future<void> _handleMenuAction(_ProspectHeaderMenuAction action) async {
    switch (action) {
      case _ProspectHeaderMenuAction.setToNextStage:
        final nextStage = detail.availableStages
            .where((stage) => stage.value != 'cancel')
            .firstOrNull;
        if (nextStage != null) {
          await onUpdateStage(nextStage.value);
        }
      case _ProspectHeaderMenuAction.setToLost:
        await onUpdateStage('lost');
      case _ProspectHeaderMenuAction.cancelProspect:
        await onCancelProspect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPopupMenuButton<_ProspectHeaderMenuAction>(
      items: _ProspectHeaderMenuAction.values,
      labelBuilder: (action) => action.label,
      iconColor: prospectDetailAccentColor,
      fontFamily: prospectDetailFontFamily,
      tooltip: 'Menu prospect',
      enabled: !isBusy,
      onSelected: _handleMenuAction,
    );
  }
}

String _errorMessage(Object error) {
  if (error is AppException) {
    return error.detailedMessage;
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

String _fileSize(int bytes) {
  if (bytes <= 0) {
    return '0 KB';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _ProspectDetailTabs extends StatelessWidget {
  const _ProspectDetailTabs({
    required this.selectedIndex,
    required this.detail,
    required this.onUploadDocument,
    required this.onDeleteDocument,
    required this.onSaveActivity,
  });

  final int selectedIndex;
  final ProspectDetailData detail;
  final Future<void> Function(
    ProspectDocumentData document,
    List<PlatformFile> files,
  )
  onUploadDocument;
  final Future<void> Function(
    ProspectDocumentData document,
    ProspectUploadedDocumentData uploadedDocument,
  )
  onDeleteDocument;
  final Future<void> Function(
    String description,
    List<PlatformFile> files,
    List<StageDocumentData> deletedDocuments,
  )
  onSaveActivity;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        ProspectDetailTab(
          detail: detail,
          onUploadDocument: onUploadDocument,
          onDeleteDocument: onDeleteDocument,
        ),
        ProspectStageHistoryTab(history: detail.stageHistory),
        ProspectActivityTab(detail: detail, onSaveActivity: onSaveActivity),
      ],
    );
  }
}

class _ProspectTabs extends StatelessWidget {
  const _ProspectTabs({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTabs(
      items: const [
        AppUnderlineTabItem(label: 'Detail'),
        AppUnderlineTabItem(label: 'Stage history'),
        AppUnderlineTabItem(label: 'Aktivitas'),
      ],
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      fontFamily: prospectDetailFontFamily,
      activeColor: prospectDetailAccentColor,
      inactiveColor: AppColors.muted,
    );
  }
}
