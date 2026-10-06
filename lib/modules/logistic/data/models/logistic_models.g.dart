// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logistic_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$LogisticPickupOrderToJson(
  LogisticPickupOrder instance,
) => <String, dynamic>{
  'pickupOrderId': instance.pickupOrderId,
  'code': instance.code,
  'type': instance.type,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'warehouseName': instance.warehouseName,
  'scheduledDate': instance.scheduledDate,
  'createdAt': instance.createdAt?.toIso8601String(),
};

Map<String, dynamic> _$LogisticPickupOrderDetailToJson(
  LogisticPickupOrderDetail instance,
) => <String, dynamic>{
  'pickupOrderId': instance.pickupOrderId,
  'code': instance.code,
  'type': instance.type,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'warehouseName': instance.warehouseName,
  'scheduledDate': instance.scheduledDate,
  'createdAt': instance.createdAt?.toIso8601String(),
  'pic': instance.pic?.toJson(),
  'pickupLocation': instance.pickupLocation,
  'notes': instance.notes,
  'canSubmit': instance.canSubmit,
  'canSubmitReport': instance.canSubmitReport,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'report': instance.report?.toJson(),
};

Map<String, dynamic> _$LogisticPickupPicToJson(LogisticPickupPic instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

Map<String, dynamic> _$LogisticPickupOrderItemToJson(
  LogisticPickupOrderItem instance,
) => <String, dynamic>{
  'pickupOrderItemId': instance.pickupOrderItemId,
  'itemType': instance.itemType,
  'name': instance.name,
  'code': instance.code,
  'uom': instance.uom,
  'quantity': instance.quantity,
  'notes': instance.notes,
};

Map<String, dynamic> _$LogisticPickupReportToJson(
  LogisticPickupReport instance,
) => <String, dynamic>{
  'notes': instance.notes,
  'photos': instance.photos.map((e) => e.toJson()).toList(),
};

Map<String, dynamic> _$LogisticPickupReportPhotoToJson(
  LogisticPickupReportPhoto instance,
) => <String, dynamic>{
  'name': instance.name,
  'url': instance.url,
  'size': instance.size,
};

Map<String, dynamic> _$LogisticLoadingOrderToJson(
  LogisticLoadingOrder instance,
) => <String, dynamic>{
  'loadingOrderId': instance.loadingOrderId,
  'code': instance.code,
  'sourceType': instance.sourceType,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'sourceWarehouseName': instance.sourceWarehouseName,
  'destinationWarehouseName': instance.destinationWarehouseName,
  'createdAt': instance.createdAt?.toIso8601String(),
};

Map<String, dynamic> _$LogisticLoadingOrderDetailToJson(
  LogisticLoadingOrderDetail instance,
) => <String, dynamic>{
  'loadingOrderId': instance.loadingOrderId,
  'code': instance.code,
  'sourceType': instance.sourceType,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'sourceWarehouseName': instance.sourceWarehouseName,
  'destinationWarehouseName': instance.destinationWarehouseName,
  'createdAt': instance.createdAt?.toIso8601String(),
  'resourceAllocation': instance.resourceAllocation,
  'notes': instance.notes,
  'canSubmit': instance.canSubmit,
  'canSubmitReport': instance.canSubmitReport,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'reports': instance.reports.map((e) => e.toJson()).toList(),
};

Map<String, dynamic> _$LogisticLoadingReportToJson(
  LogisticLoadingReport instance,
) => <String, dynamic>{
  'reportId': instance.reportId,
  'notes': instance.notes,
  'submittedAt': instance.submittedAt?.toIso8601String(),
  'submittedBy': instance.submittedBy,
  'files': instance.files.map((e) => e.toJson()).toList(),
};

Map<String, dynamic> _$LogisticLoadingReportFileToJson(
  LogisticLoadingReportFile instance,
) => <String, dynamic>{
  'id': instance.id,
  'fileName': instance.fileName,
  'url': instance.url,
};

Map<String, dynamic> _$LogisticLoadingOrderItemToJson(
  LogisticLoadingOrderItem instance,
) => <String, dynamic>{
  'loadingOrderItemId': instance.loadingOrderItemId,
  'itemType': instance.itemType,
  'name': instance.name,
  'code': instance.code,
  'uom': instance.uom,
  'quantity': instance.quantity,
  'notes': instance.notes,
};

Map<String, dynamic> _$LogisticDeliveryOrderToJson(
  LogisticDeliveryOrder instance,
) => <String, dynamic>{
  'deliveryOrderId': instance.deliveryOrderId,
  'code': instance.code,
  'sourceType': instance.sourceType,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'carrier': instance.carrier,
  'resi': instance.resi,
  'sourceWarehouseName': instance.sourceWarehouseName,
  'destinationWarehouseName': instance.destinationWarehouseName,
  'createdAt': instance.createdAt?.toIso8601String(),
  'version': instance.version,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'allowedActions': instance.allowedActions,
};

Map<String, dynamic> _$LogisticDeliveryOrderDetailToJson(
  LogisticDeliveryOrderDetail instance,
) => <String, dynamic>{
  'deliveryOrderId': instance.deliveryOrderId,
  'code': instance.code,
  'sourceType': instance.sourceType,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'canSubmit': instance.canSubmit,
  'carrier': instance.carrier,
  'resi': instance.resi,
  'sourceWarehouseName': instance.sourceWarehouseName,
  'destinationWarehouseName': instance.destinationWarehouseName,
  'createdAt': instance.createdAt?.toIso8601String(),
  'weight': instance.weight,
  'shippingCost': instance.shippingCost,
  'etd': instance.etd,
  'eta': instance.eta,
  'notes': instance.notes,
  'submittedNotes': instance.submittedNotes,
  'evidences': instance.evidences.map((e) => e.toJson()).toList(),
  'items': instance.items.map((e) => e.toJson()).toList(),
  'version': instance.version,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'allowedActions': instance.allowedActions,
};

Map<String, dynamic> _$LogisticDeliveryOrderEvidenceToJson(
  LogisticDeliveryOrderEvidence instance,
) => <String, dynamic>{
  'id': instance.id,
  'fileName': instance.fileName,
  'url': instance.url,
};

Map<String, dynamic> _$LogisticDeliveryOrderItemToJson(
  LogisticDeliveryOrderItem instance,
) => <String, dynamic>{
  'deliveryOrderItemId': instance.deliveryOrderItemId,
  'itemType': instance.itemType,
  'name': instance.name,
  'code': instance.code,
  'serialNumber': instance.serialNumber,
  'uom': instance.uom,
  'plannedQuantity': instance.plannedQuantity,
  'receivedQuantity': instance.receivedQuantity,
  'remainingQuantity': instance.remainingQuantity,
};

Map<String, dynamic> _$LogisticReceiveItemInputToJson(
  LogisticReceiveItemInput instance,
) => <String, dynamic>{
  'deliveryOrderItemId': instance.deliveryOrderItemId,
  'quantityReceived': instance.quantityReceived,
};
