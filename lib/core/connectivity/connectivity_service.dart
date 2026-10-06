import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_state.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<ConnectivityState> current() async {
    return _map(await _connectivity.checkConnectivity());
  }

  Stream<ConnectivityState> watch() async* {
    yield await current();
    yield* _connectivity.onConnectivityChanged
        .map(_map)
        .distinct((previous, next) => previous.status == next.status);
  }

  ConnectivityState _map(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none)) {
      return const ConnectivityState.offline();
    }
    return const ConnectivityState.online();
  }
}
