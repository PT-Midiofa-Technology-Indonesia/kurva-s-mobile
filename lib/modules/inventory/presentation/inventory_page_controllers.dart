import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/page_open_refresh_scope.dart';
import '../inventory_providers.dart';

final inventoryPageControllerProvider =
    Provider.autoDispose<InventoryPageController>((ref) {
      return InventoryPageController(ref);
    });

final inventoryDetailPageControllerProvider = Provider.autoDispose
    .family<InventoryDetailPageController, String>((ref, itemCatalogId) {
      return InventoryDetailPageController(ref, itemCatalogId);
    });

final inventoryAdjustmentHistoryPageControllerProvider =
    Provider.autoDispose<InventoryAdjustmentHistoryPageController>((ref) {
      return InventoryAdjustmentHistoryPageController(ref);
    });

final inventoryEquipmentDetailPageControllerProvider = Provider.autoDispose
    .family<InventoryEquipmentDetailPageController, String>((
      ref,
      resourceUnitId,
    ) {
      return InventoryEquipmentDetailPageController(ref, resourceUnitId);
    });

class InventoryPageController implements PageOpenRefreshController {
  const InventoryPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(inventoryMaterialsProvider);
    _ref.invalidateIfExists(inventoryEquipmentProvider);
  }
}

class InventoryDetailPageController implements PageOpenRefreshController {
  const InventoryDetailPageController(this._ref, this._itemCatalogId);

  final Ref _ref;
  final String _itemCatalogId;

  @override
  void refresh() {
    if (_itemCatalogId.isEmpty) return;
    _ref.invalidateIfExists(inventoryMaterialDetailProvider(_itemCatalogId));
  }
}

class InventoryAdjustmentHistoryPageController
    implements PageOpenRefreshController {
  const InventoryAdjustmentHistoryPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(inventoryStockAdjustmentsProvider);
  }
}

class InventoryEquipmentDetailPageController
    implements PageOpenRefreshController {
  const InventoryEquipmentDetailPageController(this._ref, this._resourceUnitId);

  final Ref _ref;
  final String _resourceUnitId;

  @override
  void refresh() {
    if (_resourceUnitId.isEmpty) return;
    _ref.invalidateIfExists(inventoryEquipmentDetailProvider(_resourceUnitId));
  }
}
