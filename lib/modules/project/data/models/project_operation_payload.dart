import 'package:json_annotation/json_annotation.dart';

part 'project_operation_payload.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectTaskDonePayload {
  const ProjectTaskDonePayload({
    required this.projectId,
    required this.taskId,
    required this.expectedVersion,
    required this.clientOccurredAt,
    this.note = '',
    this.completedVolume,
  });

  static const schemaVersion = 1;
  final String projectId;
  final String taskId;
  final String note;
  @JsonKey(includeIfNull: false)
  final double? completedVolume;
  final int expectedVersion;
  final DateTime clientOccurredAt;

  Map<String, Object?> toJson() {
    final json = _$ProjectTaskDonePayloadToJson(this);
    json['schemaVersion'] = schemaVersion;
    json['clientOccurredAt'] = clientOccurredAt.toUtc().toIso8601String();
    if (expectedVersion <= 0) json.remove('expectedVersion');
    return json;
  }

  factory ProjectTaskDonePayload.fromJson(Map<String, dynamic> json) {
    _requireVersion(json);
    return ProjectTaskDonePayload(
      projectId: json['projectId'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      note: json['note'] as String? ?? '',
      completedVolume: (json['completedVolume'] as num?)?.toDouble(),
      expectedVersion: _int(json['expectedVersion']),
      clientOccurredAt: DateTime.parse(
        json['clientOccurredAt'] as String,
      ).toUtc(),
    );
  }
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectQcDecisionPayload {
  const ProjectQcDecisionPayload({
    required this.projectId,
    required this.qcTaskId,
    required this.decision,
    required this.note,
    required this.expectedVersion,
    required this.clientOccurredAt,
  }) : assert(decision == 'pass' || decision == 'fail');

  static const schemaVersion = 1;
  final String projectId;
  final String qcTaskId;
  final String decision;
  final String note;
  final int expectedVersion;
  final DateTime clientOccurredAt;

  Map<String, Object?> toJson() {
    final json = _$ProjectQcDecisionPayloadToJson(this);
    json['schemaVersion'] = schemaVersion;
    json['clientOccurredAt'] = clientOccurredAt.toUtc().toIso8601String();
    if (expectedVersion <= 0) json.remove('expectedVersion');
    return json;
  }

  factory ProjectQcDecisionPayload.fromJson(Map<String, dynamic> json) {
    _requireVersion(json);
    final decision = json['decision'] as String? ?? '';
    if (decision != 'pass' && decision != 'fail') {
      throw const FormatException('Keputusan QC harus pass atau fail.');
    }
    return ProjectQcDecisionPayload(
      projectId: json['projectId'] as String? ?? '',
      qcTaskId: json['qcTaskId'] as String? ?? '',
      decision: decision,
      note: json['note'] as String? ?? '',
      expectedVersion: _int(json['expectedVersion']),
      clientOccurredAt: DateTime.parse(
        json['clientOccurredAt'] as String,
      ).toUtc(),
    );
  }
}

void _requireVersion(Map<String, dynamic> json) {
  if (_int(json['schemaVersion']) != 1) {
    throw const FormatException('Versi payload project tidak didukung.');
  }
}

int _int(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;
