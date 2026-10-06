import 'package:flutter/material.dart';

import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';

class LogisticOpenCloseTabs extends StatelessWidget {
  const LogisticOpenCloseTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTabs(
      items: const [
        AppUnderlineTabItem(label: 'Open', width: 69),
        AppUnderlineTabItem(label: 'Close', width: 70),
      ],
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
    );
  }
}
