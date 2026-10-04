import 'space.dart';

/// 비공개 채널 명단의 한 줄(16단계). `GET …/channels/:channelId/members`
///
/// 화면이 쓰는 것만 담는다 — 코드 생성이 필요 없는 크기라 평범한 클래스다.
class ChannelMemberView {
  const ChannelMemberView({
    required this.userId,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final SpaceRole role;

  factory ChannelMemberView.fromJson(Map<String, dynamic> json) => ChannelMemberView(
        userId: json['userId'] as String,
        name: (json['name'] as String?) ?? '(이름 없음)',
        avatarUrl: json['avatarUrl'] as String?,
        role: _role(json['role']),
      );
}

/// 한 역할의 채널 권한(16단계 D24). 서버는 손님 · 멤버 두 줄을 늘 준다.
class RolePermission {
  const RolePermission({
    required this.role,
    required this.canView,
    required this.canSend,
    required this.explicit,
  });

  final SpaceRole role;
  final bool canView;
  final bool canSend;

  /// 행이 있는가. 거짓이면 기본값(보기 · 보내기)이다.
  final bool explicit;

  factory RolePermission.fromJson(Map<String, dynamic> json) => RolePermission(
        role: _role(json['role']),
        canView: json['canView'] as bool? ?? true,
        canSend: json['canSend'] as bool? ?? true,
        explicit: json['explicit'] as bool? ?? false,
      );
}

SpaceRole _role(Object? wire) => SpaceRole.values.firstWhere(
      (r) => r.wire == wire,
      orElse: () => SpaceRole.member,
    );
