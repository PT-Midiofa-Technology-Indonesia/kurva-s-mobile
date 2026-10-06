import 'dart:async';

import 'sync_engine.dart';
import 'sync_models.dart';

class SyncCoordinator {
  SyncCoordinator({
    required SyncEngine engine,
    required String? Function() accountIdResolver,
  }) : _engine = engine,
       _accountIdResolver = accountIdResolver;

  final SyncEngine _engine;
  final String? Function() _accountIdResolver;
  final _statusController = StreamController<SyncStatus>.broadcast();

  SyncStatus _status = const SyncStatus();
  Future<void>? _runFuture;
  bool _rerunRequested = false;
  Timer? _debounce;
  Timer? _retryTimer;
  bool _disposed = false;

  SyncStatus get currentStatus => _status;
  Stream<SyncStatus> get status => _statusController.stream;

  void requestSync(
    SyncTrigger trigger, {
    Duration debounce = const Duration(milliseconds: 350),
  }) {
    if (_disposed) return;
    _debounce?.cancel();
    _debounce = Timer(debounce, () => unawaited(syncNow(trigger)));
  }

  Future<void> syncNow(SyncTrigger trigger) {
    if (_disposed) return Future.value();
    _retryTimer?.cancel();
    final activeRun = _runFuture;
    if (activeRun != null) {
      _rerunRequested = true;
      return activeRun;
    }

    final run = _run(trigger);
    _runFuture = run;
    return run.whenComplete(() {
      _runFuture = null;
      if (_rerunRequested) {
        _rerunRequested = false;
        requestSync(SyncTrigger.operationEnqueued, debounce: Duration.zero);
      }
    });
  }

  Future<void> _run(SyncTrigger trigger) async {
    final accountId = _accountIdResolver();
    if (accountId == null || accountId.isEmpty) return;

    _emit(
      _status.copyWith(
        state: SyncRunState.syncing,
        completedCount: 0,
        clearMessage: true,
      ),
    );
    try {
      if (trigger == SyncTrigger.userInitiated ||
          trigger == SyncTrigger.connectivityRestored ||
          trigger == SyncTrigger.foreground) {
        await _engine.makeRetriesDueForAccount(accountId);
      }
      final result = await _engine.pushPendingForAccount(accountId);
      if (result.pausedForAuth) {
        _emit(
          _status.copyWith(
            state: SyncRunState.paused,
            pendingCount: result.remainingCount,
            completedCount: result.completedCount,
            message: 'Sinkronisasi dijeda. Silakan login kembali.',
          ),
        );
        return;
      }
      final retryAt = await _engine.nextRetryAtForAccount(accountId);
      if (!_disposed && retryAt != null && _accountIdResolver() == accountId) {
        final delay = retryAt.difference(DateTime.now().toUtc());
        _retryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
          if (_accountIdResolver() == accountId) {
            unawaited(syncNow(SyncTrigger.operationEnqueued));
          }
        });
      }
      _emit(
        _status.copyWith(
          state: SyncRunState.completed,
          pendingCount: result.remainingCount,
          completedCount: result.completedCount,
          lastSyncedAt: DateTime.now().toUtc(),
          clearMessage: true,
        ),
      );
    } catch (error) {
      _emit(
        _status.copyWith(state: SyncRunState.failed, message: error.toString()),
      );
    }
  }

  void updatePendingCount(int count) {
    if (_status.pendingCount != count) {
      _emit(_status.copyWith(pendingCount: count));
    }
  }

  void _emit(SyncStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _debounce?.cancel();
    await _statusController.close();
  }
}
