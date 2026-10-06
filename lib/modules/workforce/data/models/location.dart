import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class WorkforceLocation {
  const WorkforceLocation({
    required this.id,
    required this.type,
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String type;
  final String code;
  final String name;
  final String latitude;
  final String longitude;

  factory WorkforceLocation.fromJson(Map<String, dynamic> json) {
    return WorkforceLocation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$WorkforceLocationToJson(this);
}
