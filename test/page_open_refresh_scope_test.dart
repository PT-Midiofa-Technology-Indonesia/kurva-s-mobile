import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/shared/widgets/page_open_refresh_scope.dart';

final _backendProvider = Provider<_FakeBackend>((ref) {
  throw UnimplementedError();
});

final _pageDataProvider = FutureProvider<String>((ref) async {
  return ref.read(_backendProvider).fetch();
});

final _pageControllerProvider = Provider.autoDispose<_TestPageController>((
  ref,
) {
  return _TestPageController(ref);
});

class _TestPageController implements PageOpenRefreshController {
  const _TestPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(_pageDataProvider);
  }
}

void main() {
  testWidgets('requests fresh data after page is popped and opened again', (
    tester,
  ) async {
    final backend = _FakeBackend();
    final container = ProviderContainer(
      overrides: [_backendProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _NavigationHost()),
      ),
    );

    await tester.tap(find.text('Buka halaman'));
    await tester.pumpAndSettle();

    expect(find.text('versi-1'), findsOneWidget);
    expect(backend.requestCount, 1);

    Navigator.of(tester.element(find.text('versi-1'))).pop();
    await tester.pumpAndSettle();
    backend.value = 'versi-2';

    await tester.tap(find.text('Buka halaman'));
    await tester.pumpAndSettle();

    expect(find.text('versi-1'), findsNothing);
    expect(find.text('versi-2'), findsOneWidget);
    expect(backend.requestCount, 2);
  });
}

class _FakeBackend {
  var value = 'versi-1';
  var requestCount = 0;

  Future<String> fetch() async {
    requestCount++;
    return value;
  }
}

class _NavigationHost extends StatelessWidget {
  const _NavigationHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PageOpenRefreshScope(
                  controllerProvider: _pageControllerProvider,
                  child: const _ApiPage(),
                ),
              ),
            );
          },
          child: const Text('Buka halaman'),
        ),
      ),
    );
  }
}

class _ApiPage extends ConsumerWidget {
  const _ApiPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_pageDataProvider);

    return Scaffold(
      body: Center(
        child: data.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text(error.toString()),
          data: Text.new,
        ),
      ),
    );
  }
}
