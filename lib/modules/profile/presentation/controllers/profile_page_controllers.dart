import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/page_open_refresh_scope.dart';
import '../../../auth/auth_providers.dart';

final profilePageControllerProvider =
    Provider.autoDispose<ProfilePageController>((ref) {
      return ProfilePageController(ref);
    });

final profileFaqPageControllerProvider =
    Provider.autoDispose<ProfileStaticPageController>((ref) {
      return const ProfileStaticPageController();
    });

final profileTermConditionPageControllerProvider =
    Provider.autoDispose<ProfileStaticPageController>((ref) {
      return const ProfileStaticPageController();
    });

final profileChangePasswordPageControllerProvider =
    Provider.autoDispose<ProfileChangePasswordPageController>((ref) {
      return ProfileChangePasswordPageController(ref);
    });

class ProfilePageController implements PageOpenRefreshController {
  const ProfilePageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(authControllerProvider);
  }
}

class ProfileChangePasswordPageController implements PageOpenRefreshController {
  const ProfileChangePasswordPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(authControllerProvider);
  }
}

class ProfileStaticPageController implements PageOpenRefreshController {
  const ProfileStaticPageController();

  @override
  void refresh() {}
}
