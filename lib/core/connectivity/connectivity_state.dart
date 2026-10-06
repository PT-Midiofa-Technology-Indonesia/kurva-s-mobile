enum ConnectionStatus { unknown, online, offline }

class ConnectivityState {
  const ConnectivityState(this.status);

  const ConnectivityState.unknown() : status = ConnectionStatus.unknown;
  const ConnectivityState.online() : status = ConnectionStatus.online;
  const ConnectivityState.offline() : status = ConnectionStatus.offline;

  final ConnectionStatus status;

  bool get hasNetworkInterface => status == ConnectionStatus.online;
  bool get isOffline => status == ConnectionStatus.offline;
}
