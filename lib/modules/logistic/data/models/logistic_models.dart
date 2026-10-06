import 'package:json_annotation/json_annotation.dart';

import '../../../../shared/utils/date_formatter.dart';

part 'logistic_models.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticPickupOrder {
  const LogisticPickupOrder({
    required this.pickupOrderId,
    required this.code,
    required this.type,
    required this.status,
    this.statusLabel,
    this.warehouseName,
    this.scheduledDate,
    this.createdAt,
  });

  factory LogisticPickupOrder.fromJson(Map<String, dynamic> json) {
    return LogisticPickupOrder(
      pickupOrderId: json['pickupOrderId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String?,
      warehouseName: json['warehouseName'] as String?,
      scheduledDate: json['scheduledDate'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String?),
    );
  }

  static List<LogisticPickupOrder> listFromPayload(Object? payload) {
    if (payload is! List) return const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticPickupOrder.fromJson)
        .toList(growable: false);
  }

  final String pickupOrderId;
  final String code;
  final String type;
  final String status;
  final String? statusLabel;
  final String? warehouseName;
  final String? scheduledDate;
  final DateTime? createdAt;
  Map<String, dynamic> toJson() => _$LogisticPickupOrderToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticPickupOrderDetail {
  const LogisticPickupOrderDetail({
    required this.pickupOrderId,
    required this.code,
    required this.type,
    required this.status,
    required this.canSubmit,
    required this.canSubmitReport,
    required this.items,
    this.statusLabel,
    this.warehouseName,
    this.scheduledDate,
    this.createdAt,
    this.pic,
    this.pickupLocation,
    this.notes,
    this.report,
  });

  factory LogisticPickupOrderDetail.fromJson(Map<String, dynamic> json) {
    final reports = json['reports'];
    final latestReport = reports is List && reports.isNotEmpty
        ? reports.last
        : null;
    final reportJson = json['report'] ?? latestReport;

    return LogisticPickupOrderDetail(
      pickupOrderId: json['pickupOrderId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String?,
      warehouseName: json['warehouseName'] as String?,
      scheduledDate: json['scheduledDate'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String?),
      pic: LogisticPickupPic.fromPayload(json['pic']),
      pickupLocation: json['pickupLocation'] as String?,
      notes: json['notes'] as String?,
      canSubmit: json['canSubmit'] as bool? ?? false,
      canSubmitReport: json['canSubmitReport'] as bool? ?? false,
      items: LogisticPickupOrderItem.listFromPayload(json['items']),
      report: LogisticPickupReport.fromPayload(reportJson),
    );
  }

  final String pickupOrderId;
  final String code;
  final String type;
  final String status;
  final String? statusLabel;
  final String? warehouseName;
  final String? scheduledDate;
  final DateTime? createdAt;
  final LogisticPickupPic? pic;
  final String? pickupLocation;
  final String? notes;
  final bool canSubmit;
  final bool canSubmitReport;
  final List<LogisticPickupOrderItem> items;
  final LogisticPickupReport? report;
  Map<String, dynamic> toJson() => _$LogisticPickupOrderDetailToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticPickupPic {
  const LogisticPickupPic({required this.id, required this.name});

  factory LogisticPickupPic.fromJson(Map<String, dynamic> json) {
    return LogisticPickupPic(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  static LogisticPickupPic? fromPayload(Object? payload) {
    return payload is Map<String, dynamic>
        ? LogisticPickupPic.fromJson(payload)
        : null;
  }

  final String id;
  final String name;
  Map<String, dynamic> toJson() => _$LogisticPickupPicToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticPickupOrderItem {
  const LogisticPickupOrderItem({
    required this.pickupOrderItemId,
    required this.itemType,
    required this.name,
    required this.code,
    this.uom,
    this.quantity,
    this.notes,
  });

  factory LogisticPickupOrderItem.fromJson(Map<String, dynamic> json) {
    return LogisticPickupOrderItem(
      pickupOrderItemId: json['pickupOrderItemId'] as String? ?? '',
      itemType: json['itemType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      uom: json['uom'] as String?,
      quantity: json['quantity'] as num?,
      notes: json['notes'] as String?,
    );
  }

  static List<LogisticPickupOrderItem> listFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticPickupOrderItem.fromJson)
        .toList(growable: false);
  }

  final String pickupOrderItemId;
  final String itemType;
  final String name;
  final String code;
  final String? uom;
  final num? quantity;
  final String? notes;
  Map<String, dynamic> toJson() => _$LogisticPickupOrderItemToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticPickupReport {
  const LogisticPickupReport({this.notes, this.photos = const []});

  factory LogisticPickupReport.fromJson(Map<String, dynamic> json) {
    return LogisticPickupReport(
      notes: json['notes'] as String?,
      photos: LogisticPickupReportPhoto.listFromPayload(
        json['files'] ?? json['photos'] ?? json['attachments'],
      ),
    );
  }

  static LogisticPickupReport? fromPayload(Object? payload) {
    return payload is Map<String, dynamic>
        ? LogisticPickupReport.fromJson(payload)
        : null;
  }

  final String? notes;
  final List<LogisticPickupReportPhoto> photos;
  Map<String, dynamic> toJson() => _$LogisticPickupReportToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticPickupReportPhoto {
  const LogisticPickupReportPhoto({
    required this.name,
    required this.url,
    this.size = 0,
  });

  static List<LogisticPickupReportPhoto> listFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .map((photo) {
          if (photo is String) {
            return LogisticPickupReportPhoto(
              name: Uri.tryParse(photo)?.pathSegments.lastOrNull ?? photo,
              url: photo,
            );
          }
          if (photo is! Map<String, dynamic>) return null;
          final url =
              photo['url'] as String? ??
              photo['path'] as String? ??
              photo['photoUrl'] as String? ??
              photo['fileUrl'] as String? ??
              '';
          return LogisticPickupReportPhoto(
            name:
                photo['name'] as String? ??
                photo['fileName'] as String? ??
                photo['originalName'] as String? ??
                Uri.tryParse(url)?.pathSegments.lastOrNull ??
                'Bukti foto',
            url: url,
            size: _intOrNull(photo['size']) ?? 0,
          );
        })
        .whereType<LogisticPickupReportPhoto>()
        .where((photo) => photo.url.isNotEmpty)
        .toList(growable: false);
  }

  final String name;
  final String url;
  final int size;
  Map<String, dynamic> toJson() => _$LogisticPickupReportPhotoToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticLoadingOrder {
  const LogisticLoadingOrder({
    required this.loadingOrderId,
    required this.code,
    required this.sourceType,
    required this.status,
    this.statusLabel,
    this.sourceWarehouseName,
    this.destinationWarehouseName,
    this.createdAt,
  });

  factory LogisticLoadingOrder.fromJson(Map<String, dynamic> json) {
    return LogisticLoadingOrder(
      loadingOrderId: json['loadingOrderId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String?,
      sourceWarehouseName: json['sourceWarehouseName'] as String?,
      destinationWarehouseName: json['destinationWarehouseName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String?),
    );
  }

  static List<LogisticLoadingOrder> listFromPayload(Object? payload) {
    if (payload is! List) return const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticLoadingOrder.fromJson)
        .toList(growable: false);
  }

  final String loadingOrderId;
  final String code;
  final String sourceType;
  final String status;
  final String? statusLabel;
  final String? sourceWarehouseName;
  final String? destinationWarehouseName;
  final DateTime? createdAt;
  Map<String, dynamic> toJson() => _$LogisticLoadingOrderToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticLoadingOrderDetail {
  const LogisticLoadingOrderDetail({
    required this.loadingOrderId,
    required this.code,
    required this.sourceType,
    required this.status,
    required this.items,
    required this.canSubmit,
    required this.canSubmitReport,
    this.statusLabel,
    this.sourceWarehouseName,
    this.destinationWarehouseName,
    this.createdAt,
    this.resourceAllocation,
    this.notes,
    this.reports = const [],
  });

  factory LogisticLoadingOrderDetail.fromJson(Map<String, dynamic> json) {
    return LogisticLoadingOrderDetail(
      loadingOrderId: json['loadingOrderId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String?,
      sourceWarehouseName: json['sourceWarehouseName'] as String?,
      destinationWarehouseName: json['destinationWarehouseName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String?),
      resourceAllocation: json['resourceAllocation'],
      notes: json['notes'] as String?,
      canSubmit: json['canSubmit'] as bool? ?? false,
      canSubmitReport: json['canSubmitReport'] as bool? ?? false,
      items: LogisticLoadingOrderItem.listFromPayload(json['items']),
      reports: LogisticLoadingReport.listFromPayload(json['reports']),
    );
  }

  final String loadingOrderId;
  final String code;
  final String sourceType;
  final String status;
  final String? statusLabel;
  final String? sourceWarehouseName;
  final String? destinationWarehouseName;
  final DateTime? createdAt;
  final Object? resourceAllocation;
  final String? notes;
  final bool canSubmit;
  final bool canSubmitReport;
  final List<LogisticLoadingOrderItem> items;
  final List<LogisticLoadingReport> reports;
  LogisticLoadingReport? get latestReport => reports.lastOrNull;
  Map<String, dynamic> toJson() => _$LogisticLoadingOrderDetailToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticLoadingReport {
  const LogisticLoadingReport({
    required this.reportId,
    required this.files,
    this.notes,
    this.submittedAt,
    this.submittedBy,
  });

  factory LogisticLoadingReport.fromJson(Map<String, dynamic> json) {
    return LogisticLoadingReport(
      reportId: json['reportId'] as String? ?? '',
      notes: json['notes'] as String?,
      submittedAt: parseApiDateTime(json['submittedAt'] as String?),
      submittedBy: json['submittedBy'] as String?,
      files: LogisticLoadingReportFile.listFromPayload(json['files']),
    );
  }

  static List<LogisticLoadingReport> listFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticLoadingReport.fromJson)
        .toList(growable: false);
  }

  final String reportId;
  final String? notes;
  final DateTime? submittedAt;
  final String? submittedBy;
  final List<LogisticLoadingReportFile> files;
  Map<String, dynamic> toJson() => _$LogisticLoadingReportToJson(this);
}

@JsonSerializable(createFactory: false)
class LogisticLoadingReportFile {
  const LogisticLoadingReportFile({
    required this.id,
    required this.fileName,
    required this.url,
  });

  factory LogisticLoadingReportFile.fromJson(Map<String, dynamic> json) {
    return LogisticLoadingReportFile(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  static List<LogisticLoadingReportFile> listFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticLoadingReportFile.fromJson)
        .where((file) => file.url.isNotEmpty)
        .toList(growable: false);
  }

  final String id;
  final String fileName;
  final String url;
  Map<String, dynamic> toJson() => _$LogisticLoadingReportFileToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticLoadingOrderItem {
  const LogisticLoadingOrderItem({
    required this.loadingOrderItemId,
    required this.itemType,
    required this.name,
    required this.code,
    this.uom,
    this.quantity,
    this.notes,
  });

  factory LogisticLoadingOrderItem.fromJson(Map<String, dynamic> json) {
    return LogisticLoadingOrderItem(
      loadingOrderItemId: json['loadingOrderItemId'] as String? ?? '',
      itemType: json['itemType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      uom: json['uom'] as String?,
      quantity: json['quantity'] as num?,
      notes: json['notes'] as String?,
    );
  }

  static List<LogisticLoadingOrderItem> listFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticLoadingOrderItem.fromJson)
        .toList(growable: false);
  }

  final String loadingOrderItemId;
  final String itemType;
  final String name;
  final String code;
  final String? uom;
  final num? quantity;
  final String? notes;
  Map<String, dynamic> toJson() => _$LogisticLoadingOrderItemToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticDeliveryOrder {
  const LogisticDeliveryOrder({
    required this.deliveryOrderId,
    required this.code,
    required this.sourceType,
    required this.status,
    this.statusLabel,
    this.carrier,
    this.resi,
    this.sourceWarehouseName,
    this.destinationWarehouseName,
    this.createdAt,
    this.version,
    this.updatedAt,
    this.allowedActions = const [],
  });

  factory LogisticDeliveryOrder.fromJson(Map<String, dynamic> json) {
    return LogisticDeliveryOrder(
      deliveryOrderId: json['deliveryOrderId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String?,
      carrier: json['carrier'] as String?,
      resi: json['resi'] as String?,
      sourceWarehouseName: json['sourceWarehouseName'] as String?,
      destinationWarehouseName: json['destinationWarehouseName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String?),
      version: _intOrNull(json['version']),
      updatedAt: parseApiDateTime(json['updatedAt'] as String?),
      allowedActions: _stringList(json['allowedActions']),
    );
  }

  static List<LogisticDeliveryOrder> listFromPayload(Object? payload) {
    if (payload is! List) return const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticDeliveryOrder.fromJson)
        .toList(growable: false);
  }

  final String deliveryOrderId;
  final String code;
  final String sourceType;
  final String status;
  final String? statusLabel;
  final String? carrier;
  final String? resi;
  final String? sourceWarehouseName;
  final String? destinationWarehouseName;
  final DateTime? createdAt;
  final int? version;
  final DateTime? updatedAt;
  final List<String> allowedActions;
  Map<String, dynamic> toJson() => _$LogisticDeliveryOrderToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticDeliveryOrderDetail {
  const LogisticDeliveryOrderDetail({
    required this.deliveryOrderId,
    required this.code,
    required this.sourceType,
    required this.status,
    required this.items,
    required this.canSubmit,
    this.statusLabel,
    this.carrier,
    this.resi,
    this.sourceWarehouseName,
    this.destinationWarehouseName,
    this.createdAt,
    this.weight,
    this.shippingCost,
    this.etd,
    this.eta,
    this.notes,
    this.submittedNotes,
    this.evidences = const [],
    this.version,
    this.updatedAt,
    this.allowedActions = const [],
  });

  factory LogisticDeliveryOrderDetail.fromJson(Map<String, dynamic> json) {
    return LogisticDeliveryOrderDetail(
      deliveryOrderId: json['deliveryOrderId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String?,
      canSubmit: json['canSubmit'] as bool? ?? false,
      carrier: json['carrier'] as String?,
      resi: json['resi'] as String?,
      sourceWarehouseName: json['sourceWarehouseName'] as String?,
      destinationWarehouseName: json['destinationWarehouseName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String?),
      weight: json['weight'],
      shippingCost: json['shippingCost'],
      etd: json['etd'] as String?,
      eta: json['eta'] as String?,
      notes: json['notes'] as String?,
      submittedNotes: json['submittedNotes'] as String?,
      evidences: LogisticDeliveryOrderEvidence.listFromPayload(
        json['evidences'],
      ),
      items: LogisticDeliveryOrderItem.listFromPayload(json['items']),
      version: _intOrNull(json['version']),
      updatedAt: parseApiDateTime(json['updatedAt'] as String?),
      allowedActions: _stringList(json['allowedActions']),
    );
  }

  final String deliveryOrderId;
  final String code;
  final String sourceType;
  final String status;
  final String? statusLabel;
  final bool canSubmit;
  final String? carrier;
  final String? resi;
  final String? sourceWarehouseName;
  final String? destinationWarehouseName;
  final DateTime? createdAt;
  final Object? weight;
  final Object? shippingCost;
  final String? etd;
  final String? eta;
  final String? notes;
  final String? submittedNotes;
  final List<LogisticDeliveryOrderEvidence> evidences;
  final List<LogisticDeliveryOrderItem> items;
  final int? version;
  final DateTime? updatedAt;
  final List<String> allowedActions;

  bool allows(String action) => allowedActions.any(
    (value) => value.trim().toLowerCase() == action.toLowerCase(),
  );
  Map<String, dynamic> toJson() => _$LogisticDeliveryOrderDetailToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticDeliveryOrderEvidence {
  const LogisticDeliveryOrderEvidence({
    required this.id,
    required this.fileName,
    required this.url,
  });

  factory LogisticDeliveryOrderEvidence.fromJson(Map<String, dynamic> json) {
    return LogisticDeliveryOrderEvidence(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  static List<LogisticDeliveryOrderEvidence> listFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticDeliveryOrderEvidence.fromJson)
        .where((evidence) => evidence.url.isNotEmpty)
        .toList(growable: false);
  }

  final String id;
  final String fileName;
  final String url;
  Map<String, dynamic> toJson() => _$LogisticDeliveryOrderEvidenceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticDeliveryOrderItem {
  const LogisticDeliveryOrderItem({
    required this.deliveryOrderItemId,
    required this.itemType,
    required this.name,
    required this.code,
    this.serialNumber,
    this.uom,
    this.plannedQuantity,
    this.receivedQuantity,
    this.remainingQuantity,
  });

  factory LogisticDeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return LogisticDeliveryOrderItem(
      deliveryOrderItemId: json['deliveryOrderItemId'] as String? ?? '',
      itemType: json['itemType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      serialNumber: json['serialNumber'] as String?,
      uom: json['uom'] as String?,
      plannedQuantity: json['plannedQuantity'] as num?,
      receivedQuantity: json['receivedQuantity'] as num?,
      remainingQuantity: json['remainingQuantity'] as num?,
    );
  }

  static List<LogisticDeliveryOrderItem> listFromPayload(Object? payload) {
    if (payload is! List) return const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(LogisticDeliveryOrderItem.fromJson)
        .toList(growable: false);
  }

  final String deliveryOrderItemId;
  final String itemType;
  final String name;
  final String code;
  final String? serialNumber;
  final String? uom;
  final num? plannedQuantity;
  final num? receivedQuantity;
  final num? remainingQuantity;
  Map<String, dynamic> toJson() => _$LogisticDeliveryOrderItemToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticReceiveItemInput {
  const LogisticReceiveItemInput({
    required this.deliveryOrderItemId,
    required this.quantityReceived,
  });

  final String deliveryOrderItemId;
  final num quantityReceived;
  Map<String, dynamic> toJson() => _$LogisticReceiveItemInputToJson(this);
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  return value == null ? null : int.tryParse('$value');
}

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];
