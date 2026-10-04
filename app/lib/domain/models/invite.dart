import 'space.dart';

/// `GET/POST /api/spaces/:spaceId/invites` 의 한 항목(16단계).
///
/// 화면이 쓰는 것만 담는다. 코드 생성(freezed)이 필요 없는 크기라 평범한 클래스다.
class Invite {
  const Invite({
    required this.id,
    required this.code,
    required this.role,
    required this.useCount,
    this.expiresAt,
    this.maxUses,
    this.createdByName,
  });

  final String id;
  final String code;
  final SpaceRole role;
  final DateTime? expiresAt;

  /// null 이면 무제한.
  final int? maxUses;
  final int useCount;

  /// 만들기 응답에는 없다(목록에만 실린다).
  final String? createdByName;

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
        id: json['id'] as String,
        code: json['code'] as String,
        role: SpaceRole.values.firstWhere(
          (r) => r.wire == json['role'],
          orElse: () => SpaceRole.member,
        ),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String).toUtc(),
        maxUses: json['maxUses'] as int?,
        useCount: (json['useCount'] as int?) ?? 0,
        createdByName:
            (json['createdBy'] as Map<String, dynamic>?)?['name'] as String?,
      );
}
