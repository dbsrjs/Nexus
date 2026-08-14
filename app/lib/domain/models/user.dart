import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// 서버의 `publicUserSelect` 투영과 같은 모양이다
/// (server/src/users/users.service.ts). `passwordHash` 는 서버가 절대
/// 내보내지 않으므로 여기에도 없다.
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    String? avatarUrl,
    String? globalStatus,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
