import 'package:json_annotation/json_annotation.dart';

part 'auth_session.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final String accessTokenExpiresAt;
  final String refreshToken;
  final String refreshTokenExpiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      accessTokenExpiresAt: json['accessTokenExpiresAt'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      refreshTokenExpiresAt: json['refreshTokenExpiresAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$AuthSessionToJson(this);
}
