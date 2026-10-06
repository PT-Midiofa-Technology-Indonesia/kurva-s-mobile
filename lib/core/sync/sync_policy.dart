import 'sync_models.dart';

enum ReadCapability { networkOnly, cacheRead }

enum WriteCapability { onlineOnly, queuedWrite }

class SyncPolicy {
  const SyncPolicy({
    this.readCapabilities = const {},
    this.writeCapabilities = const {},
    this.showGlobalStatusUi = false,
  });

  final Map<String, ReadCapability> readCapabilities;
  final Map<SyncOperationType, WriteCapability> writeCapabilities;
  final bool showGlobalStatusUi;

  ReadCapability readMode(String featureKey) {
    return readCapabilities[featureKey] ?? ReadCapability.networkOnly;
  }

  WriteCapability writeMode(SyncOperationType operationType) {
    return writeCapabilities[operationType] ?? WriteCapability.onlineOnly;
  }

  bool canQueue(SyncOperationType operationType) {
    return writeMode(operationType) == WriteCapability.queuedWrite;
  }
}
