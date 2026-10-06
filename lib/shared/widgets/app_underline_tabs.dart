import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class AppUnderlineTabItem {
  const AppUnderlineTabItem({
    required this.label,
    this.width,
    this.showIndicatorDot = false,
  });

  final String label;
  final double? width;
  final bool showIndicatorDot;
}

class AppUnderlineTabs extends StatelessWidget {
  const AppUnderlineTabs({
    required this.items,
    required this.selectedIndex,
    required this.onTabSelected,
    this.fontFamily = AppFonts.inter,
    this.horizontalPadding = EdgeInsets.zero,
    this.activeColor = AppColors.dashboardTeal,
    this.inactiveColor = AppColors.secondaryText,
    this.indicatorWeight = 2,
    this.itemHorizontalPadding = 16,
    this.expandItems = false,
    super.key,
  });

  final List<AppUnderlineTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final String fontFamily;
  final EdgeInsetsGeometry horizontalPadding;
  final Color activeColor;
  final Color inactiveColor;
  final double indicatorWeight;
  final double itemHorizontalPadding;
  final bool expandItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: horizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < items.length; index += 1)
            if (expandItems)
              Expanded(child: _buildTab(index))
            else
              _buildTab(index),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    return _AppUnderlineTab(
      item: items[index],
      selected: selectedIndex == index,
      onPressed: () => onTabSelected(index),
      fontFamily: fontFamily,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      indicatorWeight: indicatorWeight,
      itemHorizontalPadding: itemHorizontalPadding,
    );
  }
}

class _AppUnderlineTab extends StatelessWidget {
  const _AppUnderlineTab({
    required this.item,
    required this.selected,
    required this.onPressed,
    required this.fontFamily,
    required this.activeColor,
    required this.inactiveColor,
    required this.indicatorWeight,
    required this.itemHorizontalPadding,
  });

  final AppUnderlineTabItem item;
  final bool selected;
  final VoidCallback onPressed;
  final String fontFamily;
  final Color activeColor;
  final Color inactiveColor;
  final double indicatorWeight;
  final double itemHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: item.width,
          height: 44,
          padding: item.width == null
              ? EdgeInsets.symmetric(horizontal: itemHorizontalPadding)
              : null,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? activeColor : AppColors.transparent,
                width: indicatorWeight,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? activeColor : inactiveColor,
                    fontFamily: fontFamily,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (item.showIndicatorDot) ...[
                const SizedBox(width: 5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.dashboardTeal,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
