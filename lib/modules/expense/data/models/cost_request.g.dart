// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$CostRequestListResultToJson(
  CostRequestListResult instance,
) => <String, dynamic>{
  'costRequests': instance.costRequests.map((e) => e.toJson()).toList(),
  'meta': instance.meta.toJson(),
  'links': instance.links.toJson(),
};

Map<String, dynamic> _$CostRequestToJson(CostRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'reason': instance.reason,
      'requestType': instance.requestType,
      'project': instance.project?.toJson(),
      'totalAmount': instance.totalAmount,
      'dueDate': instance.dueDate,
      'paymentMethod': instance.paymentMethod,
      'status': instance.status,
      'statusLabel': instance.statusLabel,
      'canSubmit': instance.canSubmit,
      'rejectionReason': instance.rejectionReason,
      'notes': instance.notes,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'submittedAt': instance.submittedAt,
    };

Map<String, dynamic> _$CostRequestProjectToJson(CostRequestProject instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

Map<String, dynamic> _$CostRequestItemToJson(CostRequestItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receiptNumber': instance.receiptNumber,
      'description': instance.description,
      'amount': instance.amount,
      'notes': instance.notes,
      'proofs': instance.proofs.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$CostRequestProofToJson(CostRequestProof instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'url': instance.url,
    };

Map<String, dynamic> _$CostRequestPaginationMetaToJson(
  CostRequestPaginationMeta instance,
) => <String, dynamic>{
  'currentPage': instance.currentPage,
  'perPage': instance.perPage,
  'total': instance.total,
  'lastPage': instance.lastPage,
  'from': instance.from,
  'to': instance.to,
};

Map<String, dynamic> _$CostRequestPaginationLinksToJson(
  CostRequestPaginationLinks instance,
) => <String, dynamic>{
  'first': instance.first,
  'last': instance.last,
  'prev': instance.prev,
  'next': instance.next,
};
