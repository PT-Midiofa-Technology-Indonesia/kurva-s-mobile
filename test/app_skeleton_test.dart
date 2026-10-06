import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/shared/widgets/app_skeleton.dart';

void main() {
  testWidgets('list skeleton exposes one loading semantic label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSkeletonListView(
            itemCount: 2,
            variant: AppSkeletonListVariant.compact,
          ),
        ),
      ),
    );

    expect(find.byType(AppSkeletonBox), findsNWidgets(7));
    expect(find.bySemanticsLabel('Memuat daftar'), findsOneWidget);
  });

  testWidgets('metric skeleton honors disabled animations', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AppSkeletonMetricGrid()),
        ),
      ),
    );

    expect(find.byType(AppSkeletonBox), findsNWidgets(8));
    expect(find.bySemanticsLabel('Memuat ringkasan'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('kanban skeleton follows stage and card counts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSkeletonKanbanView(stageCount: 2, cardsPerStage: 2),
        ),
      ),
    );

    expect(find.byType(AppSkeletonBox), findsNWidgets(20));
    expect(find.bySemanticsLabel('Memuat papan kanban'), findsOneWidget);
  });

  testWidgets('detail skeleton follows configured sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSkeletonDetailView(sectionCount: 2, showHero: false),
        ),
      ),
    );

    expect(find.byType(AppSkeletonBox), findsNWidgets(10));
    expect(find.bySemanticsLabel('Memuat detail'), findsOneWidget);
  });

  testWidgets('embedded section skeletons expose matching semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppSkeletonHeroView(height: 142),
              SizedBox(height: 180, child: AppSkeletonSectionList()),
              AppSkeletonTable(),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Memuat ringkasan utama'), findsOneWidget);
    expect(find.bySemanticsLabel('Memuat bagian daftar'), findsOneWidget);
    expect(find.bySemanticsLabel('Memuat tabel'), findsOneWidget);
    expect(find.byType(AppSkeletonBox), findsNWidgets(18));
  });

  testWidgets('stacked hero keeps its requested height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppSkeletonHeroView(height: 216, stacked: true)),
      ),
    );

    expect(tester.getSize(find.byType(AppSkeletonHeroView)).height, 216);
    expect(find.byType(AppSkeletonBox), findsNWidgets(3));
  });
}
