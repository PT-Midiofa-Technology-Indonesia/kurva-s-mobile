import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_underline_tabs.dart';
import '../workforce_providers.dart';
import 'widgets/attendance_filter_bottom_sheet.dart';
import 'workforce_attendance_tab.dart';
import 'workforce_leave_tab.dart';

/// Hosts the common workforce navigation. Each tab owns its own data and UI.
class WorkforceManagementPage extends ConsumerStatefulWidget {
  const WorkforceManagementPage({super.key});

  @override
  ConsumerState<WorkforceManagementPage> createState() =>
      _WorkforceManagementPageState();
}

class _WorkforceManagementPageState
    extends ConsumerState<WorkforceManagementPage> {
  var _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeFilterCount = switch (_selectedTabIndex) {
      1 => ref.watch(leaveFilterProvider).activeCount,
      _ => ref.watch(attendanceFilterProvider).activeCount,
    };

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: switch (_selectedTabIndex) {
                1 => 'Cuti',
                _ => 'Presensi',
              },
              actionAssetPath: AssetPaths.iconFilter,
              actionBadge: activeFilterCount == 0 ? null : '$activeFilterCount',
              onBackPressed: context.pop,
              onActionPressed: _showFilterSheet,
            ),
            AppUnderlineTabs(
              items: const [
                AppUnderlineTabItem(label: 'Presensi'),
                AppUnderlineTabItem(label: 'Cuti'),
              ],
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) =>
                  setState(() => _selectedTabIndex = index),
              fontFamily: AppFonts.inter,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: const [WorkforceAttendanceTab(), WorkforceLeaveTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    switch (_selectedTabIndex) {
      case 1:
        final filter = await LeaveFilterBottomSheet.show(
          context,
          initialFilter: ref.read(leaveFilterProvider),
        );
        if (mounted && filter != null) {
          ref.read(leaveFilterProvider.notifier).state = filter;
        }
      default:
        final filter = await AttendanceFilterBottomSheet.show(
          context,
          initialFilter: ref.read(attendanceFilterProvider),
        );
        if (mounted && filter != null) {
          ref.read(attendanceFilterProvider.notifier).state = filter;
        }
    }
  }
}
