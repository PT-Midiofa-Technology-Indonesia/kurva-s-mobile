const serverRefreshDelay = Duration(seconds: 1);

/// Gives eventually consistent server reads time to reflect a successful write
/// before dependent providers fetch their data again.
Future<void> waitForServerRefresh() => Future<void>.delayed(serverRefreshDelay);
