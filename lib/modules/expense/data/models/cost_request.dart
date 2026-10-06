import 'package:json_annotation/json_annotation.dart';

part 'cost_request.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class CostRequestListResult {
  const CostRequestListResult({
    required this.costRequests,
    required this.meta,
    required this.links,
  });

  final List<CostRequest> costRequests;
  final CostRequestPaginationMeta meta;
  final CostRequestPaginationLinks links;

  factory CostRequestListResult.fromJson(Map<String, dynamic> json) {
    return CostRequestListResult(
      costRequests: _objectList(json['data'], CostRequest.fromJson),
      meta: CostRequestPaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
      links: CostRequestPaginationLinks.fromJson(
        json['links'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => _$CostRequestListResultToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class CostRequest {
  const CostRequest({
    required this.id,
    required this.code,
    required this.reason,
    required this.requestType,
    required this.project,
    required this.totalAmount,
    required this.dueDate,
    required this.paymentMethod,
    required this.status,
    required this.statusLabel,
    required this.canSubmit,
    required this.rejectionReason,
    required this.notes,
    required this.items,
    required this.submittedAt,
  });

  final String id;
  final String code;
  final String reason;
  final String requestType;
  final CostRequestProject? project;
  final String totalAmount;
  final String? dueDate;
  final String? paymentMethod;
  final String status;
  final String statusLabel;
  final bool canSubmit;
  final String? rejectionReason;
  final String? notes;
  final List<CostRequestItem> items;
  final String? submittedAt;

  factory CostRequest.fromJson(Map<String, dynamic> json) {
    return CostRequest(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      requestType: json['requestType'] as String? ?? '',
      project: json['project'] is Map<String, dynamic>
          ? CostRequestProject.fromJson(json['project'] as Map<String, dynamic>)
          : null,
      totalAmount: json['totalAmount']?.toString() ?? '0',
      dueDate: json['dueDate'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String? ?? '',
      canSubmit: json['canSubmit'] as bool? ?? false,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
      items: _objectList(json['items'], CostRequestItem.fromJson),
      submittedAt: json['submittedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$CostRequestToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class CostRequestProject {
  const CostRequestProject({required this.id, required this.name});

  final String id;
  final String name;

  factory CostRequestProject.fromJson(Map<String, dynamic> json) {
    return CostRequestProject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$CostRequestProjectToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class CostRequestItem {
  const CostRequestItem({
    required this.id,
    required this.receiptNumber,
    required this.description,
    required this.amount,
    required this.notes,
    required this.proofs,
  });

  final String id;
  final String receiptNumber;
  final String description;
  final String amount;
  final String? notes;
  final List<CostRequestProof> proofs;

  factory CostRequestItem.fromJson(Map<String, dynamic> json) {
    return CostRequestItem(
      id: json['id'] as String? ?? '',
      receiptNumber: json['receiptNumber'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: json['amount']?.toString() ?? '0',
      notes: json['notes'] as String?,
      proofs: _objectList(json['proofs'], CostRequestProof.fromJson),
    );
  }

  Map<String, dynamic> toJson() => _$CostRequestItemToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class CostRequestProof {
  const CostRequestProof({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.url,
  });

  final String id;
  final String fileName;
  final int fileSize;
  final String url;

  factory CostRequestProof.fromJson(Map<String, dynamic> json) {
    return CostRequestProof(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: _asInt(json['fileSize']),
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$CostRequestProofToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class CostRequestPaginationMeta {
  const CostRequestPaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int from;
  final int to;

  factory CostRequestPaginationMeta.fromJson(Map<String, dynamic> json) {
    return CostRequestPaginationMeta(
      currentPage: _asInt(json['currentPage']),
      perPage: _asInt(json['perPage']),
      total: _asInt(json['total']),
      lastPage: _asInt(json['lastPage']),
      from: _asInt(json['from']),
      to: _asInt(json['to']),
    );
  }

  Map<String, dynamic> toJson() => _$CostRequestPaginationMetaToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class CostRequestPaginationLinks {
  const CostRequestPaginationLinks({
    required this.first,
    required this.last,
    required this.prev,
    required this.next,
  });

  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  factory CostRequestPaginationLinks.fromJson(Map<String, dynamic> json) {
    return CostRequestPaginationLinks(
      first: json['first'] as String?,
      last: json['last'] as String?,
      prev: json['prev'] as String?,
      next: json['next'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$CostRequestPaginationLinksToJson(this);
}

List<T> _objectList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(mapper)
      .toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
