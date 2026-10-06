import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/page_open_refresh_scope.dart';

final splashControllerProvider = Provider<SplashController>((ref) {
  return const SplashController();
});

class SplashController implements PageOpenRefreshController {
  const SplashController();

  @override
  void refresh() {}
}
