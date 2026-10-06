import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_task_list_page.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';

void main() {
  for (final hasUnread in [true, false, null]) {
    testWidgets('children history dot with status $hasUnread', (tester) async {
      final status = Completer<bool>();
      final requestedTabs = <String?>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectTaskChildrenProvider.overrideWith((ref, query) {
              requestedTabs.add(query.tab);
              return Stream.value([]);
            }),
            projectTaskChildrenHistoryHasUnreadProvider.overrideWith((
              ref,
              query,
            ) {
              expect(query.projectId, 'project-1');
              expect(query.parentTaskId, 'parent-1');
              return status.future;
            }),
          ],
          child: const MaterialApp(
            home: ProjectTaskListPage(
              parentTaskId: 'parent-1',
              detail: ProjectDetailData(
                projectId: 'project-1',
                projectName: 'Test',
                status: '',
                client: '',
                period: '',
                description: '',
                workingDays: '',
                taskCount: '',
              ),
            ),
          ),
        ),
      );
      bool showsDot() => tester
          .widget<AppUnderlineTabs>(find.byType(AppUnderlineTabs))
          .items
          .singleWhere((item) => item.label == 'History')
          .showIndicatorDot;
      expect(showsDot(), isFalse);
      if (hasUnread == null) {
        status.completeError(Exception('offline'));
      } else {
        status.complete(hasUnread);
      }
      await tester.pumpAndSettle();
      expect(showsDot(), hasUnread == true);
      expect(requestedTabs, isNot(contains('history')));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(requestedTabs, contains('history'));
      expect(showsDot(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
