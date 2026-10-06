import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class AppPopupMenuButton<T> extends StatelessWidget {
  const AppPopupMenuButton({
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
    required this.iconColor,
    required this.fontFamily,
    this.tooltip = 'Menu',
    this.enabled = true,
    this.width = 40,
    this.height = 40,
    this.iconSize = 24,
    this.menuWidth = 244,
    this.menuItemHeight = 56,
    super.key,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final Future<void> Function(T item) onSelected;
  final Color iconColor;
  final String fontFamily;
  final String tooltip;
  final bool enabled;
  final double width;
  final double height;
  final double iconSize;
  final double menuWidth;
  final double menuItemHeight;

  Future<void> _showPopupMenu(BuildContext context) async {
    if (!enabled) return;

    final buttonBox = context.findRenderObject()! as RenderBox;
    final overlayBox =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final buttonOffset = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

    final selectedItem = await showMenu<T>(
      context: context,
      color: AppColors.white,
      elevation: 8,
      shadowColor: AppColors.black.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      constraints: BoxConstraints.tightFor(width: menuWidth),
      position: RelativeRect.fromLTRB(
        buttonOffset.dx + buttonBox.size.width - menuWidth,
        buttonOffset.dy + buttonBox.size.height,
        overlayBox.size.width - buttonOffset.dx - buttonBox.size.width,
        0,
      ),
      items: _buildMenuItems(),
    );

    if (!context.mounted || selectedItem == null) return;

    await onSelected(selectedItem);
  }

  List<PopupMenuEntry<T>> _buildMenuItems() {
    return [
      for (var index = 0; index < items.length; index++) ...[
        if (index > 0) const PopupMenuDivider(height: 1),
        _buildMenuItem(items[index]),
      ],
    ];
  }

  PopupMenuItem<T> _buildMenuItem(T item) {
    return PopupMenuItem<T>(
      value: item,
      height: menuItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        labelBuilder(item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.ink,
          fontFamily: fontFamily,
          fontSize: 16,
          height: 1.2,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: IconButton(
        icon: Icon(Icons.more_vert, size: iconSize),
        color: iconColor,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: enabled ? () => _showPopupMenu(context) : null,
      ),
    );
  }
}
