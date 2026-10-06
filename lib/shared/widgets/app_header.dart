import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.onBackPressed,
    this.height = 64,
    this.backgroundColor = AppColors.white,
    this.horizontalPadding = AppSpacing.md,
    this.iconColor = AppColors.dashboardTeal,
    this.leadingSize = 48,
    this.leadingIconSize = 32,
    this.leadingIcon = Icons.arrow_back,
    this.leading,
    this.showLeading = true,
    this.titleSpacing = AppSpacing.md,
    this.titleColor = AppColors.ink,
    this.titleFontFamily = AppFonts.inter,
    this.titleFontSize = 20,
    this.titleHeight = 1.33,
    this.titleFontWeight = FontWeight.w700,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.titleWidget,
    this.backTooltip = 'Kembali',
    this.actionIcon,
    this.actionAssetPath,
    this.onActionPressed,
    this.actionTooltip,
    this.actionBadge,
    this.actionSize = 40,
    this.actionIconSize = 24,
    this.actionSpacing = 0,
    this.actions = const [],
    this.actionWidgets = const [],
    this.onTap,
    super.key,
  });

  final String title;
  final VoidCallback? onBackPressed;
  final double height;
  final Color backgroundColor;
  final double horizontalPadding;
  final Color iconColor;
  final double leadingSize;
  final double leadingIconSize;
  final IconData leadingIcon;
  final Widget? leading;
  final bool showLeading;
  final double titleSpacing;
  final Color titleColor;
  final String titleFontFamily;
  final double titleFontSize;
  final double titleHeight;
  final FontWeight titleFontWeight;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? titleWidget;
  final String? backTooltip;
  final IconData? actionIcon;
  final String? actionAssetPath;
  final VoidCallback? onActionPressed;
  final String? actionTooltip;
  final String? actionBadge;
  final double actionSize;
  final double actionIconSize;
  final double actionSpacing;
  final List<AppHeaderAction> actions;
  final List<Widget> actionWidgets;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final header = Container(
      height: height,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          if (showLeading) ...[
            leading ??
                SizedBox(
                  width: leadingSize,
                  height: leadingSize,
                  child: IconButton(
                    icon: Icon(leadingIcon, size: leadingIconSize),
                    color: iconColor,
                    tooltip: backTooltip,
                    padding: EdgeInsets.zero,
                    onPressed: onBackPressed,
                  ),
                ),
            SizedBox(width: titleSpacing),
          ],
          Expanded(child: titleWidget ?? _HeaderTitle(this)),
          ..._buildActions(),
        ],
      ),
    );

    if (onTap == null) return header;

    return Material(
      color: backgroundColor,
      child: InkWell(onTap: onTap, child: header),
    );
  }

  List<Widget> _buildActions() {
    final headerActions = [
      ...actions,
      if (actionIcon != null || actionAssetPath != null)
        AppHeaderAction(
          icon: actionIcon,
          assetPath: actionAssetPath,
          onPressed: onActionPressed,
          tooltip: actionTooltip,
          badge: actionBadge,
        ),
    ];

    final widgets = <Widget>[
      for (final action in headerActions)
        _HeaderActionButton(
          action: action,
          iconColor: action.iconColor ?? iconColor,
          actionSize: action.size ?? actionSize,
          iconSize: action.iconSize ?? actionIconSize,
        ),
      ...actionWidgets,
    ];

    if (widgets.isEmpty || actionSpacing == 0) return widgets;

    return [
      for (var index = 0; index < widgets.length; index++) ...[
        if (index > 0) SizedBox(width: actionSpacing),
        widgets[index],
      ],
    ];
  }
}

class AppHeaderAction {
  const AppHeaderAction({
    this.icon,
    this.assetPath,
    this.onPressed,
    this.tooltip,
    this.badge,
    this.iconColor,
    this.size,
    this.iconSize,
  }) : assert(icon != null || assetPath != null);

  final IconData? icon;
  final String? assetPath;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? badge;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle(this.header);

  final AppHeader header;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      header.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          header.titleStyle ??
          TextStyle(
            color: header.titleColor,
            fontFamily: header.titleFontFamily,
            fontSize: header.titleFontSize,
            height: header.titleHeight,
            fontWeight: header.titleFontWeight,
            letterSpacing: 0,
          ),
    );

    final subtitle = header.subtitle;
    if (subtitle == null) return title;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              header.subtitleStyle ??
              const TextStyle(
                color: AppColors.secondaryText,
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.action,
    required this.iconColor,
    required this.actionSize,
    required this.iconSize,
  });

  final AppHeaderAction action;
  final Color iconColor;
  final double actionSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: actionSize,
      height: actionSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: action.assetPath != null
                ? ImageIcon(AssetImage(action.assetPath!), size: iconSize)
                : Icon(action.icon, size: iconSize),
            color: iconColor,
            tooltip: action.tooltip,
            onPressed: action.onPressed,
          ),
          if (action.badge != null)
            Positioned(
              right: -1,
              bottom: 1,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1),
                ),
                child: Text(
                  action.badge!,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
