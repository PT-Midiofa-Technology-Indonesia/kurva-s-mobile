import 'package:json_annotation/json_annotation.dart';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/utils/date_formatter.dart';

part 'inventory_models.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class InventoryMaterial {
  const InventoryMaterial({
    required this.itemCatalogId,
    required this.code,
    required this.name,
    required this.quantityOnHand,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.uom,
    required this.warehouseName,
    required this.status,
    this.lastMovementAt,
  });

  final String itemCatalogId;
  final String code;
  final String name;
  final num quantityOnHand;
  final num reservedQuantity;
  final num availableQuantity;
  final String uom;
  final String warehouseName;
  final String status;
  final DateTime? lastMovementAt;

  factory InventoryMaterial.fromJson(Map<String, dynamic> json) {
    return InventoryMaterial(
      itemCatalogId: json['itemCatalogId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantityOnHand: _numValue(json['quantityOnHand']),
      reservedQuantity: _numValue(json['reservedQuantity']),
      availableQuantity: _numValue(json['availableQuantity']),
      uom: json['uom'] as String? ?? '',
      warehouseName: json['warehouseName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      lastMovementAt: _dateTimeValue(json['lastMovementAt']),
    );
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get quantityLabel => '${_formatNumber(quantityOnHand)} $uom'.trim();
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get reservedLabel => '${_formatNumber(reservedQuantity)} $uom'.trim();
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get availableLabel =>
      '${_formatNumber(availableQuantity)} $uom'.trim();
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get statusLabel => status;

  Map<String, dynamic> toJson() => _$InventoryMaterialToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class InventoryMaterialDetail extends InventoryMaterial {
  const InventoryMaterialDetail({
    required super.itemCatalogId,
    required super.code,
    required super.name,
    required super.quantityOnHand,
    required super.reservedQuantity,
    required super.availableQuantity,
    required super.uom,
    required super.warehouseName,
    required super.status,
    super.lastMovementAt,
    this.updatedAt,
    this.adjustmentHistory = const [],
  });

  final DateTime? updatedAt;
  final List<InventoryStockAdjustment> adjustmentHistory;

  factory InventoryMaterialDetail.fromJson(Map<String, dynamic> json) {
    return InventoryMaterialDetail(
      itemCatalogId: json['itemCatalogId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantityOnHand: _numValue(json['quantityOnHand']),
      reservedQuantity: _numValue(json['reservedQuantity']),
      availableQuantity: _numValue(json['availableQuantity']),
      uom: json['uom'] as String? ?? '',
      warehouseName: json['warehouseName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      lastMovementAt: _dateTimeValue(json['lastMovementAt']),
      updatedAt: _dateTimeValue(json['updatedAt']),
      adjustmentHistory: InventoryStockAdjustment.listFromPayload(
        json['adjustmentHistory'],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => _$InventoryMaterialDetailToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class InventoryEquipment {
  const InventoryEquipment({
    required this.resourceUnitId,
    required this.unitCode,
    required this.name,
    required this.warehouseName,
    required this.status,
  });

  final String resourceUnitId;
  final String unitCode;
  final String name;
  final String warehouseName;
  final String status;

  factory InventoryEquipment.fromJson(Map<String, dynamic> json) {
    return InventoryEquipment(
      resourceUnitId: json['resourceUnitId'] as String? ?? '',
      unitCode: json['unitCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      warehouseName: json['warehouseName'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get statusLabel => status;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Color get statusColor => _equipmentStatusColor(status);

  Map<String, dynamic> toJson() => _$InventoryEquipmentToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class InventoryEquipmentDetail extends InventoryEquipment {
  const InventoryEquipmentDetail({
    required super.resourceUnitId,
    required super.unitCode,
    required super.name,
    required super.warehouseName,
    required super.status,
    this.serialNumber,
    this.acquisitionDate,
    this.updatedAt,
    this.allocationHistory = const [],
  });

  final String? serialNumber;
  final DateTime? acquisitionDate;
  final DateTime? updatedAt;
  final List<InventoryEquipmentAllocation> allocationHistory;

  factory InventoryEquipmentDetail.fromJson(Map<String, dynamic> json) {
    return InventoryEquipmentDetail(
      resourceUnitId: json['resourceUnitId'] as String? ?? '',
      unitCode: json['unitCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      warehouseName: json['warehouseName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      serialNumber: json['serialNumber'] as String?,
      acquisitionDate: _dateTimeValue(json['acquisitionDate']),
      updatedAt: _dateTimeValue(json['updatedAt']),
      allocationHistory: InventoryEquipmentAllocation.listFromPayload(
        json['allocationHistory'],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => _$InventoryEquipmentDetailToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class InventoryEquipmentAllocation {
  const InventoryEquipmentAllocation({required this.from, required this.until});

  final String from;
  final String until;

  factory InventoryEquipmentAllocation.fromJson(Map<String, dynamic> json) {
    return InventoryEquipmentAllocation(
      from: _stringValue(
        json['from'] ??
            json['startDate'] ??
            json['allocatedFrom'] ??
            json['dateFrom'],
      ),
      until: _stringValue(
        json['until'] ??
            json['endDate'] ??
            json['allocatedUntil'] ??
            json['dateTo'],
      ),
    );
  }

  static List<InventoryEquipmentAllocation> listFromPayload(Object? payload) {
    if (payload is! List) return const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(InventoryEquipmentAllocation.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => _$InventoryEquipmentAllocationToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class InventoryStockAdjustment {
  const InventoryStockAdjustment({
    required this.id,
    required this.itemCatalogId,
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.adjustmentQty,
    required this.status,
    required this.adjustmentCode,
    required this.warehouseName,
    required this.date,
  });

  final String id;
  final String itemCatalogId;
  final String itemCode;
  final String itemName;
  final String uom;
  final num quantityBefore;
  final num quantityAfter;
  final num adjustmentQty;
  final String status;
  final String adjustmentCode;
  final String warehouseName;
  final String date;

  factory InventoryStockAdjustment.fromJson(Map<String, dynamic> json) {
    return InventoryStockAdjustment(
      id: json['id'] as String? ?? '',
      itemCatalogId: json['itemCatalogId'] as String? ?? '',
      itemCode: json['itemCode'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      quantityBefore: _numValue(json['quantityBefore']),
      quantityAfter: _numValue(json['quantityAfter']),
      adjustmentQty: _numValue(json['adjustmentQty']),
      status: json['status'] as String? ?? '',
      adjustmentCode: json['adjustmentCode'] as String? ?? '',
      warehouseName: json['warehouseName'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  static List<InventoryStockAdjustment> listFromPayload(Object? payload) {
    if (payload is! List) return const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(InventoryStockAdjustment.fromJson)
        .toList(growable: false);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get statusLabel => status;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isApproved => status == 'approved';
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get beforeLabel => '${_formatNumber(quantityBefore)} $uom'.trim();
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get afterLabel => '${_formatNumber(quantityAfter)} $uom'.trim();

  Map<String, dynamic> toJson() => _$InventoryStockAdjustmentToJson(this);
}

num _numValue(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return parseApiDateTime(value);
}

String _stringValue(Object? value) => value?.toString() ?? '-';

String _formatNumber(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toString();
}

String formatInventoryDate(DateTime? value) {
  if (value == null) return '-';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

Color _equipmentStatusColor(String status) {
  switch (status) {
    case 'available':
      return AppColors.dashboardTeal;
    case 'broken':
      return AppColors.rose;
    case 'in_maintenance':
      return AppColors.orange;
    default:
      return AppColors.secondaryText;
  }
}
