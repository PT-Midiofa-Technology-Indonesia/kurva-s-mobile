import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

/// Applies one shared shimmer animation to a tree of [AppSkeletonBox] widgets.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    required this.child,
    this.semanticLabel = 'Memuat konten',
    super.key,
  });

  final Widget child;
  final String semanticLabel;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _disableAnimations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_disableAnimations == disableAnimations && _controller.isAnimating) {
      return;
    }

    _disableAnimations = disableAnimations;
    if (_disableAnimations) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: _AppSkeletonAnimationScope(
            animation: _disableAnimations ? null : _controller,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _AppSkeletonAnimationScope extends InheritedNotifier<Animation<double>> {
  const _AppSkeletonAnimationScope({
    required Animation<double>? animation,
    required super.child,
  }) : super(notifier: animation);

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AppSkeletonAnimationScope>()
        ?.notifier;
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * ((progress * 2) - 1), 0, 0);
  }
}

/// A design-system placeholder used inside [AppSkeleton].
class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final animation = _AppSkeletonAnimationScope.maybeOf(context);

    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: animation == null ? AppColors.skeletonBase : null,
            gradient: animation == null
                ? null
                : LinearGradient(
                    colors: const [
                      AppColors.skeletonBase,
                      AppColors.skeletonHighlight,
                      AppColors.skeletonBase,
                    ],
                    stops: const [0.25, 0.5, 0.75],
                    transform: _SlidingGradientTransform(animation.value),
                  ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

enum AppSkeletonListVariant { compact, standard, detailed }

/// Skeleton preset for full-page lists. The variants approximate the card
/// density while keeping the final page dimensions stable during loading.
class AppSkeletonListView extends StatelessWidget {
  const AppSkeletonListView({
    this.itemCount = 5,
    this.variant = AppSkeletonListVariant.standard,
    this.showSectionHeader = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
    ),
    super.key,
  });

  final int itemCount;
  final AppSkeletonListVariant variant;
  final bool showSectionHeader;
  final EdgeInsetsGeometry padding;

  double get _cardHeight => switch (variant) {
    AppSkeletonListVariant.compact => 78,
    AppSkeletonListVariant.standard => 126,
    AppSkeletonListVariant.detailed => 174,
  };

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat daftar',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount + (showSectionHeader ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (showSectionHeader && index == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppSkeletonBox(width: 88, height: 20),
              ),
            );
          }

          return _SkeletonListCard(height: _cardHeight, variant: variant);
        },
      ),
    );
  }
}

class _SkeletonListCard extends StatelessWidget {
  const _SkeletonListCard({required this.height, required this.variant});

  final double height;
  final AppSkeletonListVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == AppSkeletonListVariant.compact) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _cardDecoration,
        child: const Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonBox(width: 180, height: 16),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeletonBox(width: 112, height: 14),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            AppSkeletonBox(width: 64, height: 14),
          ],
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBox(width: 200, height: 16),
          const SizedBox(height: AppSpacing.sm),
          const AppSkeletonBox(width: 144, height: 14),
          const Spacer(),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: AppSpacing.md),
          if (variant == AppSkeletonListVariant.detailed) ...[
            const AppSkeletonBox(width: 128, height: 14),
            const SizedBox(height: AppSpacing.md),
          ],
          const Row(
            children: [
              AppSkeletonBox(width: 76, height: 20),
              SizedBox(width: AppSpacing.sm),
              AppSkeletonBox(width: 104, height: 20),
              Spacer(),
              AppSkeletonBox(width: 48, height: 14),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: AppColors.line),
  );
}

/// Skeleton preset for detail pages composed of a summary and information
/// sections.
class AppSkeletonDetailView extends StatelessWidget {
  const AppSkeletonDetailView({
    this.sectionCount = 3,
    this.showHero = true,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.lg),
    super.key,
  });

  final int sectionCount;
  final bool showHero;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat detail',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        children: [
          if (showHero) const _SkeletonDetailHero(),
          for (var index = 0; index < sectionCount; index++)
            const _SkeletonDetailSection(),
        ],
      ),
    );
  }
}

class _SkeletonDetailHero extends StatelessWidget {
  const _SkeletonDetailHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(width: 192, height: 20),
          Spacer(),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 16)),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: AppSkeletonBox(height: 16)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 14)),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: AppSkeletonBox(height: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonDetailSection extends StatelessWidget {
  const _SkeletonDetailSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(width: 120, height: 18),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 14)),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: AppSkeletonBox(height: 14)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 14)),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: AppSkeletonBox(height: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton preset for attendance-style hero sections.
class AppSkeletonHeroView extends StatelessWidget {
  const AppSkeletonHeroView({
    required this.height,
    this.stacked = false,
    super.key,
  });

  final double height;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat ringkasan utama',
      child: Container(
        height: height,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: stacked
            ? const _StackedHeroSkeleton()
            : const _WideHeroSkeleton(),
      ),
    );
  }
}

class _WideHeroSkeleton extends StatelessWidget {
  const _WideHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSkeletonBox(width: 128, height: 14),
              SizedBox(height: AppSpacing.md),
              AppSkeletonBox(width: 88, height: 36),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.lg),
        AppSkeletonBox(width: 120, height: 36, borderRadius: AppRadius.md),
      ],
    );
  }
}

class _StackedHeroSkeleton extends StatelessWidget {
  const _StackedHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppSpacing.lg),
        AppSkeletonBox(width: 128, height: 14),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonBox(width: 88, height: 40),
        Spacer(),
        AppSkeletonBox(height: 48, borderRadius: AppRadius.md),
      ],
    );
  }
}

/// Non-scrollable skeleton for a short list embedded in another scroll view.
class AppSkeletonSectionList extends StatelessWidget {
  const AppSkeletonSectionList({this.itemCount = 2, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat bagian daftar',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: [
            for (var index = 0; index < itemCount; index++) ...[
              const _SkeletonSectionCard(),
              if (index != itemCount - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonSectionCard extends StatelessWidget {
  const _SkeletonSectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(width: 176, height: 16),
                SizedBox(height: AppSpacing.sm),
                AppSkeletonBox(width: 112, height: 14),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          AppSkeletonBox(width: 56, height: 20),
        ],
      ),
    );
  }
}

/// Non-scrollable skeleton matching a compact three-column data table.
class AppSkeletonTable extends StatelessWidget {
  const AppSkeletonTable({this.rowCount = 2, super.key});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat tabel',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              const _SkeletonTableRow(header: true),
              for (var index = 0; index < rowCount; index++)
                _SkeletonTableRow(showDivider: index != rowCount - 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonTableRow extends StatelessWidget {
  const _SkeletonTableRow({this.header = false, this.showDivider = true});

  final bool header;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: header ? 40 : 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: header ? AppColors.cardBackground : AppColors.white,
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: const Row(
        children: [
          AppSkeletonBox(width: 44, height: 14),
          SizedBox(width: AppSpacing.md),
          Expanded(child: AppSkeletonBox(height: 14)),
          SizedBox(width: AppSpacing.md),
          AppSkeletonBox(width: 64, height: 20),
        ],
      ),
    );
  }
}

/// Skeleton preset matching the two-column metrics on the dashboard.
class AppSkeletonMetricGrid extends StatelessWidget {
  const AppSkeletonMetricGrid({this.itemCount = 4, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat ringkasan',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 90,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
          ),
          itemBuilder: (context, index) {
            return const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSkeletonBox(width: 88, height: 14),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeletonBox(width: 44, height: 36),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton preset matching horizontally scrollable kanban stages.
class AppSkeletonKanbanView extends StatelessWidget {
  const AppSkeletonKanbanView({
    this.stageCount = 3,
    this.cardsPerStage = 3,
    super.key,
  });

  final int stageCount;
  final int cardsPerStage;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat papan kanban',
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var stageIndex = 0; stageIndex < stageCount; stageIndex++) ...[
              _SkeletonKanbanStage(cardsPerStage: cardsPerStage),
              if (stageIndex != stageCount - 1)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonKanbanStage extends StatelessWidget {
  const _SkeletonKanbanStage({required this.cardsPerStage});

  final int cardsPerStage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.tabBorder,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                AppSkeletonBox(width: 112, height: 18),
                Spacer(),
                AppSkeletonBox(width: 28, height: 18),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var cardIndex = 0; cardIndex < cardsPerStage; cardIndex++) ...[
            const _SkeletonKanbanCard(),
            if (cardIndex != cardsPerStage - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SkeletonKanbanCard extends StatelessWidget {
  const _SkeletonKanbanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(width: 176, height: 16),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonBox(width: 128, height: 14),
          Spacer(),
          Row(
            children: [
              AppSkeletonBox(width: 72, height: 20),
              Spacer(),
              AppSkeletonBox(width: 48, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}
