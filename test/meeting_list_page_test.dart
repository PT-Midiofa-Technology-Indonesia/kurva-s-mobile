import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/meeting/meeting_list_page.dart';

void main() {
  Widget buildPage(MeetingListType type) {
    return ProviderScope(
      overrides: [
        meetingListProvider.overrideWith(
          (ref, query) async => const MeetingListResult(
            meetings: [
              Meeting(
                id: '1',
                title: 'Diskusi persiapan pembangunan',
                description: 'Persiapan project',
                status: 'progress',
                projectName: 'Project A',
                startDate: '2026-06-20',
                endDate: '2026-12-20',
                durationDays: 128,
                taskCount: 203,
              ),
              Meeting(
                id: '2',
                title: 'Persiapan tender PT. Sinar Mas',
                description: 'Persiapan tender',
                status: 'progress',
                projectName: 'Project B',
                startDate: '2026-06-20',
                endDate: '2026-12-20',
                durationDays: 128,
                taskCount: 203,
              ),
              Meeting(
                id: '3',
                title: 'Review kualitas pembangunan',
                description: 'Review kualitas',
                status: 'progress',
                projectName: 'Project C',
                startDate: '2026-06-20',
                endDate: '2026-12-20',
                durationDays: 128,
                taskCount: 203,
              ),
              Meeting(
                id: '4',
                title: 'Evaluasi hasil inspeksi lapangan',
                description: 'Evaluasi hasil',
                status: 'progress',
                projectName: 'Project D',
                startDate: '2026-06-20',
                endDate: '2026-12-20',
                durationDays: 128,
                taskCount: 203,
              ),
            ],
            currentPage: 1,
            lastPage: 1,
          ),
        ),
      ],
      child: MaterialApp(home: MeetingListPage(type: type)),
    );
  }

  testWidgets('renders task meeting design content', (tester) async {
    await tester.pumpWidget(buildPage(MeetingListType.task));
    await tester.pump();

    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Diskusi persiapan pembangunan'), findsOneWidget);
    expect(find.text('Persiapan tender PT. Sinar Mas'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('renders quality meeting content', (tester) async {
    await tester.pumpWidget(buildPage(MeetingListType.quality));
    await tester.pump();

    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('Review kualitas pembangunan'), findsOneWidget);
    expect(find.text('Evaluasi hasil inspeksi lapangan'), findsOneWidget);
  });

  testWidgets('loads the next meeting page only after scrolling', (
    tester,
  ) async {
    final requestedPages = <int>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meetingListProvider.overrideWith((ref, query) async {
            requestedPages.add(query.page);
            return MeetingListResult(
              meetings: List.generate(
                query.page == 1 ? 5 : 1,
                (index) => Meeting(
                  id: '${query.page}-$index',
                  title: query.page == 1
                      ? 'Meeting halaman pertama $index'
                      : 'Meeting halaman kedua',
                  description: 'Deskripsi meeting',
                  status: 'progress',
                  projectName: 'Project',
                  startDate: '2026-06-20',
                  endDate: '2026-12-20',
                  durationDays: 128,
                  taskCount: 3,
                ),
              ),
              currentPage: query.page,
              lastPage: 2,
            );
          }),
        ],
        child: const MaterialApp(
          home: MeetingListPage(type: MeetingListType.task),
        ),
      ),
    );
    await tester.pump();

    expect(requestedPages, [1]);
    expect(find.text('Meeting halaman kedua'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    await tester.pump();

    expect(requestedPages, [1, 2]);
    expect(find.text('Meeting halaman kedua'), findsOneWidget);
  });
}
