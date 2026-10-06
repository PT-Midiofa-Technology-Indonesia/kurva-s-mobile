// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logistic_operation_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$LogisticOperationPayloadV1ToJson(
  LogisticOperationPayloadV1 instance,
) => <String, dynamic>{
  'type': instance.type,
  'deliveryOrderId': instance.deliveryOrderId,
  'expectedVersion': instance.expectedVersion,
  'clientOccurredAt': instance.clientOccurredAt.toIso8601String(),
  'notes': instance.notes,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
