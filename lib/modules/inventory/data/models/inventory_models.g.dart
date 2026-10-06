// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$InventoryMaterialToJson(InventoryMaterial instance) =>
    <String, dynamic>{
      'itemCatalogId': instance.itemCatalogId,
      'code': instance.code,
      'name': instance.name,
      'quantityOnHand': instance.quantityOnHand,
      'reservedQuantity': instance.reservedQuantity,
      'availableQuantity': instance.availableQuantity,
      'uom': instance.uom,
      'warehouseName': instance.warehouseName,
      'status': instance.status,
      'lastMovementAt': instance.lastMovementAt?.toIso8601String(),
    };

Map<String, dynamic> _$InventoryMaterialDetailToJson(
  InventoryMaterialDetail instance,
) => <String, dynamic>{
  'itemCatalogId': instance.itemCatalogId,
  'code': instance.code,
  'name': instance.name,
  'quantityOnHand': instance.quantityOnHand,
  'reservedQuantity': instance.reservedQuantity,
  'availableQuantity': instance.availableQuantity,
  'uom': instance.uom,
  'warehouseName': instance.warehouseName,
  'status': instance.status,
  'lastMovementAt': instance.lastMovementAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'adjustmentHistory': instance.adjustmentHistory
      .map((e) => e.toJson())
      .toList(),
};

Map<String, dynamic> _$InventoryEquipmentToJson(InventoryEquipment instance) =>
    <String, dynamic>{
      'resourceUnitId': instance.resourceUnitId,
      'unitCode': instance.unitCode,
      'name': instance.name,
      'warehouseName': instance.warehouseName,
      'status': instance.status,
    };

Map<String, dynamic> _$InventoryEquipmentDetailToJson(
  InventoryEquipmentDetail instance,
) => <String, dynamic>{
  'resourceUnitId': instance.resourceUnitId,
  'unitCode': instance.unitCode,
  'name': instance.name,
  'warehouseName': instance.warehouseName,
  'status': instance.status,
  'serialNumber': instance.serialNumber,
  'acquisitionDate': instance.acquisitionDate?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'allocationHistory': instance.allocationHistory
      .map((e) => e.toJson())
      .toList(),
};

Map<String, dynamic> _$InventoryEquipmentAllocationToJson(
  InventoryEquipmentAllocation instance,
) => <String, dynamic>{'from': instance.from, 'until': instance.until};

Map<String, dynamic> _$InventoryStockAdjustmentToJson(
  InventoryStockAdjustment instance,
) => <String, dynamic>{
  'id': instance.id,
  'itemCatalogId': instance.itemCatalogId,
  'itemCode': instance.itemCode,
  'itemName': instance.itemName,
  'uom': instance.uom,
  'quantityBefore': instance.quantityBefore,
  'quantityAfter': instance.quantityAfter,
  'adjustmentQty': instance.adjustmentQty,
  'status': instance.status,
  'adjustmentCode': instance.adjustmentCode,
  'warehouseName': instance.warehouseName,
  'date': instance.date,
};
