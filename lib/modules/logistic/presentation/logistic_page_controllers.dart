import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/page_open_refresh_scope.dart';
import '../logistic_providers.dart';

final loadingPageControllerProvider =
    Provider.autoDispose<LoadingPageController>((ref) {
      return LoadingPageController(ref);
    });

final pickupPageControllerProvider = Provider.autoDispose<PickupPageController>(
  (ref) {
    return PickupPageController(ref);
  },
);

final loadingDetailPageControllerProvider = Provider.autoDispose
    .family<LoadingDetailPageController, String>((ref, loadingOrderId) {
      return LoadingDetailPageController(ref, loadingOrderId);
    });

final pickupDetailPageControllerProvider = Provider.autoDispose
    .family<PickupDetailPageController, String>((ref, pickupOrderId) {
      return PickupDetailPageController(ref, pickupOrderId);
    });

final inboundPageControllerProvider =
    Provider.autoDispose<InboundPageController>((ref) {
      return InboundPageController(ref);
    });

final inboundDetailPageControllerProvider = Provider.autoDispose
    .family<InboundDetailPageController, String>((ref, deliveryOrderId) {
      return InboundDetailPageController(ref, deliveryOrderId);
    });

final outboundPageControllerProvider =
    Provider.autoDispose<OutboundPageController>((ref) {
      return OutboundPageController(ref);
    });

final outboundDetailPageControllerProvider = Provider.autoDispose
    .family<OutboundDetailPageController, String>((ref, deliveryOrderId) {
      return OutboundDetailPageController(ref, deliveryOrderId);
    });

class LoadingPageController implements PageOpenRefreshController {
  const LoadingPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(
      loadingOrdersProvider(const LogisticListQuery(tab: 'open')),
    );
    _ref.invalidateIfExists(
      loadingOrdersProvider(const LogisticListQuery(tab: 'close')),
    );
  }
}

class PickupPageController implements PageOpenRefreshController {
  const PickupPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(
      pickupOrdersProvider(const LogisticListQuery(tab: 'open')),
    );
    _ref.invalidateIfExists(
      pickupOrdersProvider(const LogisticListQuery(tab: 'close')),
    );
  }
}

class LoadingDetailPageController implements PageOpenRefreshController {
  const LoadingDetailPageController(this._ref, this._loadingOrderId);

  final Ref _ref;
  final String _loadingOrderId;

  @override
  void refresh() {
    if (_loadingOrderId.isEmpty) return;
    _ref.invalidateIfExists(loadingDetailProvider(_loadingOrderId));
  }
}

class PickupDetailPageController implements PageOpenRefreshController {
  const PickupDetailPageController(this._ref, this._pickupOrderId);

  final Ref _ref;
  final String _pickupOrderId;

  @override
  void refresh() {
    if (_pickupOrderId.isEmpty) return;
    _ref.invalidateIfExists(pickupDetailProvider(_pickupOrderId));
  }
}

class InboundPageController implements PageOpenRefreshController {
  const InboundPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(
      inboundOrdersProvider(const LogisticListQuery(tab: 'open')),
    );
    _ref.invalidateIfExists(
      inboundOrdersProvider(const LogisticListQuery(tab: 'close')),
    );
  }
}

class InboundDetailPageController implements PageOpenRefreshController {
  const InboundDetailPageController(this._ref, this._deliveryOrderId);

  final Ref _ref;
  final String _deliveryOrderId;

  @override
  void refresh() {
    if (_deliveryOrderId.isEmpty) return;
    _ref.invalidateIfExists(inboundDetailProvider(_deliveryOrderId));
  }
}

class OutboundPageController implements PageOpenRefreshController {
  const OutboundPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(
      outboundOrdersProvider(const LogisticListQuery(tab: 'open')),
    );
    _ref.invalidateIfExists(
      outboundOrdersProvider(const LogisticListQuery(tab: 'close')),
    );
  }
}

class OutboundDetailPageController implements PageOpenRefreshController {
  const OutboundDetailPageController(this._ref, this._deliveryOrderId);

  final Ref _ref;
  final String _deliveryOrderId;

  @override
  void refresh() {
    if (_deliveryOrderId.isEmpty) return;
    _ref.invalidateIfExists(outboundDetailProvider(_deliveryOrderId));
  }
}
