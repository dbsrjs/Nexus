import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/invite.dart';
import '../../domain/models/space.dart';
import '../space/members_controller.dart';

/// 스페이스 설정 창의 섹션(16단계 설계 D5). `slug` 는 주소 `/s/:spaceId/settings/<slug>` 에 쓰인다.
enum SpaceSettingsSection {
  general('general', '일반'),
  members('members', '멤버'),
  invites('invites', '초대');

  const SpaceSettingsSection(this.slug, this.label);

  final String slug;
  final String label;

  /// 볼 수 있는 섹션만(설계 §3). 일반 · 초대는 admin+ 가 고치는 곳이라 그 밖에는 감춘다.
  static List<SpaceSettingsSection> visibleFor(SpaceRole role) =>
      role.atLeast(SpaceRole.admin) ? values : const [members];

  static SpaceSettingsSection? parse(String? slug) {
    for (final section in values) {
      if (section.slug == slug) return section;
    }
    return null;
  }
}

String spaceSettingsLocation(String spaceId, SpaceSettingsSection? section) =>
    section == null
        ? '/s/$spaceId/settings'
        : '/s/$spaceId/settings/${section.slug}';

/// 쓸 수 있는 초대(admin+). 캐시하지 않는다 — 설정 창을 열 때만 본다.
final invitesProvider = FutureProvider.family<List<Invite>, String>(
  (ref, spaceId) => ref.watch(invitesApiProvider).list(spaceId),
);

/// provider 의 실패를 화면 문구로. `ApiException` 이 아니면 서버 오류로 친다 —
/// 서버 문구를 화면에 쓰지 않는다(CLAUDE.md §3 앱 규칙).
String errorMessageOf(Object? error) => messageFor(
      error is ApiException ? error.failure : ApiFailure.server,
    );
