import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/core/sync/sync_policy.dart';

void main() {
  setUp(() {
    dotenv.testLoad(
      fileInput: '''
OFFLINE_PROJECT_CACHE_READ_ENABLED=true
OFFLINE_LOGISTIC_CACHE_READ_ENABLED=true
OFFLINE_QUEUE_PROJECT_TASK_DONE_ENABLED=true
OFFLINE_QUEUE_QC_TASK_DECISION_ENABLED=true
OFFLINE_QUEUE_LOGISTIC_INBOUND_RECEIVE_ENABLED=true
OFFLINE_QUEUE_LOGISTIC_OUTBOUND_ISSUE_ENABLED=true
OFFLINE_QUEUE_LOGISTIC_LOADING_REPORT_ENABLED=true
OFFLINE_QUEUE_LOGISTIC_PICKUP_REPORT_ENABLED=true
''',
    );
  });

  tearDown(dotenv.clean);

  test('project and logistic offline-first flags are active', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final policy = container.read(syncPolicyProvider);

    expect(policy.readMode('projectCacheRead'), ReadCapability.cacheRead);
    expect(policy.readMode('logisticCacheRead'), ReadCapability.cacheRead);
    expect(
      policy.writeMode(SyncOperationType.projectTaskDone),
      WriteCapability.queuedWrite,
    );
    expect(
      policy.writeMode(SyncOperationType.qcTaskDecision),
      WriteCapability.queuedWrite,
    );
    expect(
      policy.writeMode(SyncOperationType.logisticInboundReceive),
      WriteCapability.queuedWrite,
    );
    expect(
      policy.writeMode(SyncOperationType.logisticOutboundIssue),
      WriteCapability.queuedWrite,
    );
    expect(
      policy.writeMode(SyncOperationType.logisticLoadingReport),
      WriteCapability.queuedWrite,
    );
    expect(
      policy.writeMode(SyncOperationType.logisticPickupReport),
      WriteCapability.queuedWrite,
    );
  });

  test('disabled or absent environment flags keep operations online-only', () {
    for (final configuration in [
      '',
      'OFFLINE_PROJECT_CACHE_READ_ENABLED=false',
    ]) {
      dotenv.testLoad(fileInput: configuration);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final policy = container.read(syncPolicyProvider);

      expect(policy.readMode('projectCacheRead'), ReadCapability.networkOnly);
      expect(policy.readMode('logisticCacheRead'), ReadCapability.networkOnly);
      for (final operation in SyncOperationType.values) {
        expect(policy.writeMode(operation), WriteCapability.onlineOnly);
      }
    }
  });
}
