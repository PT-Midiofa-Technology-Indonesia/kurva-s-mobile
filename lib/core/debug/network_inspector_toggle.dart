import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final networkInspectorEnabled = ValueNotifier<bool>(false);

const _debugToolsEnabledKey = 'debug_tools_enabled';
const _legacyNetworkInspectorEnabledKey = 'network_inspector_enabled';
const _storage = FlutterSecureStorage();

bool isNetworkInspectorEnabledAtStartup = false;

Future<void> loadNetworkInspectorPreference() async {
  final isEnabled = await readNetworkInspectorPreference();
  isNetworkInspectorEnabledAtStartup = isEnabled;
  networkInspectorEnabled.value = isEnabled;
}

Future<bool> readNetworkInspectorPreference() async {
  final value = await _storage.read(key: _debugToolsEnabledKey);
  if (value != null) {
    return value == 'true';
  }

  return await _storage.read(key: _legacyNetworkInspectorEnabledKey) == 'true';
}

Future<void> setNetworkInspectorPreference(bool isEnabled) async {
  await _storage.write(key: _debugToolsEnabledKey, value: isEnabled.toString());
}
