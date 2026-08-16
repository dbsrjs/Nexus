import 'package:freezed_annotation/freezed_annotation.dart';

part 'space_member.freezed.dart';

// json_serializable 을 쓰지 않는다 — 서버가 `user` 를 중첩해 주는데 화면은
// 평평한 모양을 원해서, 변환을 손으로 쓰는 편이 짧다.

/// `GET /api/spaces/:spaceId/members` 의 한 항목.
///
/// 서버는 `SpaceMember` 행에 `user` 를 중첩해 준다. 화면이 쓰는 것은 사실상
/// 사용자 쪽이라 여기서 평평하게 편다.
@freezed
abstract class SpaceMemberProfile with _$SpaceMemberProfile {
  const factory SpaceMemberProfile({
    required String userId,
    required String name,
    String? avatarUrl,
    String? nickname,
  }) = _SpaceMemberProfile;

  const SpaceMemberProfile._();

  factory SpaceMemberProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return SpaceMemberProfile(
      userId: json['userId'] as String,
      name: (user?['name'] as String?) ?? '(이름 없음)',
      avatarUrl: user?['avatarUrl'] as String?,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'avatarUrl': avatarUrl,
        'nickname': nickname,
      };

  /// 스페이스에서 부르는 이름. 별명이 있으면 그것이 우선이다.
  String get displayName => nickname?.isNotEmpty == true ? nickname! : name;
}
