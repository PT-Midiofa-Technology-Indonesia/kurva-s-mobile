import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'data/inventory_repository.dart';
import 'data/models/inventory_models.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(dioClient: ref.watch(dioClientProvider));
});

final inventoryMaterialsProvider = FutureProvider<List<InventoryMaterial>>((
  ref,
) {
  return ref.watch(inventoryRepositoryProvider).fetchMaterials();
});

final inventoryMaterialDetailProvider =
    FutureProvider.family<InventoryMaterialDetail, String>((
      ref,
      itemCatalogId,
    ) {
      return ref
          .watch(inventoryRepositoryProvider)
          .fetchMaterialDetail(itemCatalogId);
    });

final inventoryEquipmentProvider = FutureProvider<List<InventoryEquipment>>((
  ref,
) {
  return ref.watch(inventoryRepositoryProvider).fetchEquipment();
});

final inventoryEquipmentDetailProvider =
    FutureProvider.family<InventoryEquipmentDetail, String>((
      ref,
      resourceUnitId,
    ) {
      return ref
          .watch(inventoryRepositoryProvider)
          .fetchEquipmentDetail(resourceUnitId);
    });

final inventoryStockAdjustmentsProvider =
    FutureProvider<List<InventoryStockAdjustment>>((ref) {
      return ref.watch(inventoryRepositoryProvider).fetchStockAdjustments();
    });
