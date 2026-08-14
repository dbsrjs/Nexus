import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

/// 로그인 · 리프레시 응답의 토큰 부분.
///
/// `refreshToken` 이 nullable 인 이유: 서버는 `client: 'web'` 으로 요청하면
/// 리프레시 토큰을 `HttpOnly` 쿠키로만 내려보내고 바디에서 뺀다
/// (server/src/auth/auth.controller.ts 의 deliverTokens). 이 앱은 네이티브라
/// 항상 바디로 받지만, 웹 빌드를 붙일 때 이 필드가 비는 경로가 생긴다.
@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    String? refreshToken,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}
