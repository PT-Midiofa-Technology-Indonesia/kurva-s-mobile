import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_inspector/network_inspector.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/app_environment.dart';
import 'core/debug/network_inspector_toggle.dart';
import 'core/database/app_database.dart';
import 'core/offline_first_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await dotenv.load(fileName: AppEnvironment.currentEnvFile);
  AppConfig.validate();
  await loadNetworkInspectorPreference();
  if (isNetworkInspectorEnabledAtStartup) {
    await NetworkInspector.initialize();
  }
  final database = AppDatabase();
  await database.customSelect('SELECT 1').get();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const CurvaApp(),
    ),
  );
}
