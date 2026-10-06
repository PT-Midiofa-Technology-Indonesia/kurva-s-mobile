import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/server_refresh_delay.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../../../shared/utils/date_formatter.dart';
import '../data/models/cost_request.dart';
import '../expense_providers.dart';

class ExpenseReimbursementDetailPage extends ConsumerStatefulWidget {
  const ExpenseReimbursementDetailPage({
    super.key,
    required this.costRequestId,
  });

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;

  final String costRequestId;

  @override
  ConsumerState<ExpenseReimbursementDetailPage> createState() =>
      _ExpenseReimbursementDetailPageState();
}

class _ExpenseReimbursementDetailPageState
    extends ConsumerState<ExpenseReimbursementDetailPage> {
  bool _isCancelling = false;

  Future<void> _cancel(CostRequest detail) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Batalkan reimbursement?',
      cancelLabel: 'Tidak',
      confirmLabel: 'Ya, batalkan',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      final message = await ref
          .read(expenseRepositoryProvider)
          .cancelCostRequest(
            costRequestId: detail.id,
            companyId: ref.read(expenseCompanyIdProvider),
          );

      await waitForServerRefresh();
      if (!mounted) return;
      ref
        ..invalidate(costRequestListProvider)
        ..invalidate(costRequestDetailProvider(detail.id));

      AppToast.success(
        context,
        message ?? 'Reimbursement berhasil dibatalkan.',
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;

      AppToast.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.costRequestId;
    final detailState = id.isEmpty
        ? const AsyncValue<CostRequest>.error(
            'ID reimbursement tidak tersedia.',
            StackTrace.empty,
          )
        : ref.watch(costRequestDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Detail Reimbursement',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: detailState.when(
                data: (detail) => RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(costRequestDetailProvider(id).future),
                  child: _DetailContent(detail: detail),
                ),
                loading: () => const AppSkeletonDetailView(),
                error: (error, _) => NetworkAwareErrorView(
                  error: error,
                  message: _errorMessage(error),
                  onRetry: id.isEmpty
                      ? null
                      : () => ref.invalidate(costRequestDetailProvider(id)),
                ),
              ),
            ),
            if (detailState.hasValue && detailState.value!.canSubmit)
              SafeArea(
                top: false,
                child: _CancelActionBar(
                  isLoading: _isCancelling,
                  onCancel: () => _cancel(detailState.value!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final CostRequest detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        _DescriptionSection(detail: detail),
        const Divider(height: 1, thickness: 1, color: AppColors.line),
        _FinanceInformationSection(detail: detail),
        const Divider(height: 1, thickness: 1, color: AppColors.line),
        const _SectionTitle(title: 'Informasi item'),
        ...detail.items.map(
          (item) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: _ExpenseItemCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.detail});

  final CostRequest detail;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(detail.statusLabel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: 'Keterangan'),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(label: 'Keperluan', value: _fallback(detail.reason)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Tanggal pengajuan',
                  value: _formatDate(detail.submittedAt),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Tenggat waktu',
                  value: _formatDate(detail.dueDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Pilih proyek',
            value: _fallback(detail.project?.name),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Payment request',
            value: _paymentMethodLabel(detail.paymentMethod),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Status',
            value: status.label,
            valueColor: status.color,
          ),
        ],
      ),
    );
  }
}

class _FinanceInformationSection extends StatelessWidget {
  const _FinanceInformationSection({required this.detail});

  final CostRequest detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: 'Informasi dari finance'),
          const SizedBox(height: AppSpacing.lg),
          if (detail.status.toLowerCase() == 'rejected')
            _DetailField(
              label: 'Alasan penolakan',
              value: _fallback(detail.rejectionReason),
            )
          else
            Text(
              _fallback(detail.notes),
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontFamily: ExpenseReimbursementDetailPage._fontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: _SectionHeading(title: title),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: ExpenseReimbursementDetailPage._fontFamily,
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.secondaryText,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: ExpenseReimbursementDetailPage._fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontFamily: ExpenseReimbursementDetailPage._fontFamily,
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

class _ExpenseItemCard extends StatelessWidget {
  const _ExpenseItemCard({required this.item});

  final CostRequestItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailField(label: 'No nota', value: _fallback(item.receiptNumber)),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(label: 'Nama item', value: _fallback(item.description)),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(label: 'Nominal', value: _formatCurrency(item.amount)),
          if (item.proofs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...item.proofs.map(
              (proof) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AttachmentTile(proof: proof),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.proof});

  final CostRequestProof proof;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softLine),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _fallback(proof.fileName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: ExpenseReimbursementDetailPage._accentFontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _formatFileSize(proof.fileSize),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.inputBorder,
              fontFamily: ExpenseReimbursementDetailPage._accentFontFamily,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelActionBar extends StatelessWidget {
  const _CancelActionBar({required this.isLoading, required this.onCancel});

  final bool isLoading;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppButton(
        label: isLoading ? 'Membatalkan...' : 'Batalkan',
        isLoading: isLoading,
        backgroundColor: AppColors.rose,
        onPressed: isLoading ? null : onCancel,
      ),
    );
  }
}

class _StatusDisplay {
  const _StatusDisplay({required this.label, required this.color});

  final String label;
  final Color color;
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

String _fallback(String? value) {
  if (value == null || value.trim().isEmpty) return '-';
  return value;
}

String _formatDate(String? value) {
  final date = parseApiDateTime(value);
  if (date == null) return '-';

  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
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

String _formatFileSize(int bytes) {
  if (bytes <= 0) return '-';
  if (bytes < 1024) return '$bytes B';

  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}

String _paymentMethodLabel(String? value) {
  return switch (value) {
    'cash' => 'Cash',
    'transfer' => 'Transfer',
    'check' => 'Check',
    null || '' => '-',
    _ => value,
  };
}

_StatusDisplay _statusLabel(String value) {
  return switch (value) {
    'paid' => _StatusDisplay(label: value, color: AppColors.green),
    'rejected' => _StatusDisplay(label: value, color: AppColors.rose),
    'cancelled' => _StatusDisplay(label: value, color: AppColors.secondaryText),
    'submitted' => _StatusDisplay(label: value, color: AppColors.orange),
    _ => _StatusDisplay(label: value, color: AppColors.secondaryText),
  };
}

String _errorMessage(Object error) {
  final message = error.toString();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message.isEmpty ? 'Detail reimbursement gagal dimuat.' : message;
}
