import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../ui/theme.dart';
import 'nexus_avatar.dart';

/// 사람 아바타(14단계). 사진이 있으면 사진, 없거나 못 받으면 **지금의 이니셜**이다.
///
/// 사진 주소(`/users/<id>/avatar?v=…`)는 첨부처럼 서버가 권한을 보므로 인증
/// 헤더를 붙인다. 주소에 버전이 있어 사진이 바뀌면 다른 주소가 되고, 이미지
/// 캐시가 옛 사진을 붙들지 않는다.
///
/// **실패해도 자리가 비지 않는다** — 로딩 중 · 오류 모두 이니셜을 그린다.
/// 스페이스 아이콘은 여전히 `NexusAvatar` 를 쓴다(사진이 없다).
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.size = 40,
  });

  final String userId;
  final String name;

  /// 서버가 준 경로 그대로. null 이면 사진이 없다.
  final String? avatarUrl;

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = NexusAvatar(seed: userId, label: name, size: size);
    final path = avatarUrl;
    if (path == null) return initials;

    final client = ref.watch(apiClientProvider);
    final token = client.accessToken;
    // 투명한 사진(로고 등)도 동그라미로 읽히게 뒤에 바탕을 깐다.
    return ClipOval(
      child: ColoredBox(
        color: NxTheme.of(context).colors.bgElevated,
        child: Image.network(
          '${client.dio.options.baseUrl}$path',
          headers: token == null ? null : {'authorization': 'Bearer $token'},
          width: size,
          height: size,
          fit: BoxFit.cover,
          // 256px 원본을 작은 자리에 그대로 풀지 않는다 — 목록에 아바타가 많다.
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : initials,
          errorBuilder: (context, error, stack) => initials,
        ),
      ),
    );
  }
}
