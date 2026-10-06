import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_task_action_controllers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_sub_task_picker_page.dart';

void main() {
  test('parses alreadyBrokenDown separately from selection state', () {
    final option = ProjectBreakdownOption.fromJson(const {
      'id': 'boq-1',
      'code': 'A.1',
      'title': 'Already broken down',
      'alreadyBrokenDown': true,
    });

    expect(option.alreadyBrokenDown, isTrue);
    expect(option.isSelected, isFalse);
  });

  testWidgets('already broken down task cannot be selected again', (
    tester,
  ) async {
    const detail = ProjectSubTaskPickerData(
      tasks: [
        ProjectSubTaskPickerItemData(
          id: 'boq-1',
          code: 'A.1',
          title: 'Already broken down',
          alreadyBrokenDown: true,
        ),
        ProjectSubTaskPickerItemData(
          id: 'boq-2',
          code: 'A.2',
          title: 'Available',
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProjectSubTaskPickerPage(detail: detail)),
      ),
    );

    final controller = container.read(
      projectBreakdownActionControllerProvider(detail),
    );
    expect(controller.selectedCodes, isEmpty);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('A.1 Already broken down'));
    await tester.pump();

    expect(controller.selectedCodes, isEmpty);

    await tester.tap(find.text('A.2 Available'));
    await tester.pump();

    expect(controller.selectedCodes, {'boq-2'});
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });
}
