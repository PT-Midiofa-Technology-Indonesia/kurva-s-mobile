import 'package:json_annotation/json_annotation.dart';

import 'logistic_models.dart';

part 'logistic_operation_payload.g.dart';

class LogisticReceiveCommand {
  const LogisticReceiveCommand({
    required this.deliveryOrderId,
    required this.expectedVersion,
    required this.items,
    this.notes = '',
    this.photoPaths = const [],
  });

  final String deliveryOrderId;
  final int expectedVersion;
  final List<LogisticReceiveItemInput> items;
  final String notes;
  final List<String> photoPaths;
}

class LogisticIssueCommand {
  const LogisticIssueCommand({
    required this.deliveryOrderId,
    required this.expectedVersion,
    this.notes = '',
    this.photoPaths = const [],
  });

  final String deliveryOrderId;
  final int expectedVersion;
  final String notes;
  final List<String> photoPaths;
}

class LogisticReportCommand {
  const LogisticReportCommand({
    required this.resourceId,
    this.notes = '',
    this.photoPaths = const [],
  });

  final String resourceId;
  final String notes;
  final List<String> photoPaths;
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogisticOperationPayloadV1 {
  const LogisticOperationPayloadV1({
    required this.type,
    required this.deliveryOrderId,
    required this.expectedVersion,
    required this.clientOccurredAt,
    this.notes = '',
    this.items = const [],
  });

  static const schemaVersion = 1;
  final String type;
  final String deliveryOrderId;
  final int expectedVersion;
  final DateTime clientOccurredAt;
  final String notes;
  final List<LogisticReceiveItemInput> items;

  Map<String, Object?> toJson() {
    final json = _$LogisticOperationPayloadV1ToJson(this);
    json['clientOccurredAt'] = clientOccurredAt.toUtc().toIso8601String();
    json['payloadVersion'] = schemaVersion;
    if (expectedVersion <= 0) json.remove('expectedVersion');
    if (items.isEmpty) json.remove('items');
    return json;
  }

  factory LogisticOperationPayloadV1.fromJson(Map<String, dynamic> json) {
    if (_asInt(json['payloadVersion']) != schemaVersion) {
      throw const FormatException('Versi payload logistic tidak didukung.');
    }
    final rawItems = json['items'];
    return LogisticOperationPayloadV1(
      type: json['type'] as String? ?? '',
      deliveryOrderId: json['deliveryOrderId'] as String? ?? '',
      expectedVersion: _asInt(json['expectedVersion']),
      clientOccurredAt: DateTime.parse(
        json['clientOccurredAt'] as String,
      ).toUtc(),
      notes: json['notes'] as String? ?? '',
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map((item) {
                  return LogisticReceiveItemInput(
                    deliveryOrderItemId:
                        item['deliveryOrderItemId'] as String? ?? '',
                    quantityReceived: item['quantityReceived'] as num? ?? 0,
                  );
                })
                .toList(growable: false)
          : const [],
    );
  }
}

int _asInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;
