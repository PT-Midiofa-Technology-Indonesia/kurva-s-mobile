import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class PageOpenRefreshController {
  void refresh();
}

extension PageOpenRefreshRef on Ref {
  void invalidateIfExists(ProviderBase<Object?> provider) {
    if (exists(provider)) {
      invalidate(provider);
    }
  }
}

class PageOpenRefreshScope<T extends PageOpenRefreshController>
    extends ConsumerStatefulWidget {
  const PageOpenRefreshScope({
    super.key,
    required this.controllerProvider,
    required this.child,
    this.deferChildUntilRefresh = true,
  });

  final ProviderListenable<T> controllerProvider;
  final Widget child;
  final bool deferChildUntilRefresh;

  @override
  ConsumerState<PageOpenRefreshScope<T>> createState() =>
      _PageOpenRefreshScopeState<T>();
}

class _PageOpenRefreshScopeState<T extends PageOpenRefreshController>
    extends ConsumerState<PageOpenRefreshScope<T>> {
  var _isReady = false;
  var _refreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    _isReady = !widget.deferChildUntilRefresh;
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(PageOpenRefreshScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllerProvider != widget.controllerProvider ||
        oldWidget.deferChildUntilRefresh != widget.deferChildUntilRefresh) {
      _isReady = !widget.deferChildUntilRefresh;
      _scheduleRefresh();
    }
  }

  void _scheduleRefresh() {
    final generation = ++_refreshGeneration;
    Future<void>.microtask(() {
      if (!mounted || generation != _refreshGeneration) return;
      ref.read(widget.controllerProvider).refresh();
      if (!mounted || generation != _refreshGeneration) return;
      setState(() => _isReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Run the controller before the page starts watching its data providers.
    // This avoids briefly rendering cached data and prevents a duplicate first
    // request caused by invalidating a provider immediately after its first read.
    return _isReady ? widget.child : const SizedBox.shrink();
  }
}
