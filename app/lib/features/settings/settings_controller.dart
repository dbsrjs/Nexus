import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../data/api/settings_api.dart';
import '../../domain/models/channel.dart';
import '../../domain/models/user.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';

final settingsApiProvider =
    Provider<SettingsApi>((ref) => SettingsApi(ref.watch(apiClientProvider)));

/// 설정 창의 섹션(14단계 설계 D1). `slug` 는 주소 `/settings/<slug>` 에 쓰인다.
enum SettingsSection {
  account('account', '내 계정'),
  password('password', '비밀번호'),
  notifications('notifications', '알림'),
  appearance('appearance', '화면');

  const SettingsSection(this.slug, this.label);

  final String slug;
  final String label;

  static SettingsSection? parse(String? slug) {
    for (final section in values) {
      if (section.slug == slug) return section;
    }
    return null;
  }
}

/// 설정 창 안의 주소. **들어온 곳(`from`)과 스페이스(`space`)를 끝까지 들고 다닌다** —
/// 섹션을 옮겨도 닫으면 들어오기 전 화면으로 돌아가고, 알림 섹션은 그 스페이스를
/// 먼저 보인다.
String settingsLocation(SettingsSection? section, {String? spaceId, String? from}) {
  return Uri(
    path: section == null ? '/settings' : '/settings/${section.slug}',
    queryParameters: {'space': ?spaceId, 'from': ?from},
  ).toString().replaceAll(RegExp(r'\?$'), '');
}

/// 설정 창에서 고른 스페이스의 채널. 채널 목록과 같은 방식이다 — 캐시를 구독하고
/// 서버는 뒤에서 한 번 갱신한다. 음소거 스위치가 이 캐시를 본다.
final settingsChannelsProvider =
    StreamProvider.family<List<Channel>, String>((ref, spaceId) {
  final repository = ref.watch(workspaceRepositoryProvider);
  Future.microtask(() => repository.refreshChannels(spaceId));
  return repository.watchChannels(spaceId);
});

/// 내 계정이 바뀐 응답을 앱 전체에 반영한다 — 인증 상태 · 오프라인 저장본 · 캐시의
/// 내 작성자 칸. 소켓 `user:updated` 로도 곧 오지만 **응답으로 먼저 고친다** —
/// 저장 버튼을 누른 사람이 이벤트를 기다리지 않게.
Future<void> applyMe(WidgetRef ref, User user) async {
  await ref.read(authControllerProvider.notifier).replaceUser(user);
  await ref.read(appDatabaseProvider).applyUserUpdated(
        userId: user.id,
        name: user.name,
        avatarUrl: user.avatarUrl,
      );
}

/// 설정 창의 실패 문구. 서버 문구를 쓰지 않는다(CLAUDE.md §3 앱 규칙).
String settingsMessageFor(ApiFailure failure, {bool avatar = false, bool password = false}) {
  if (password && failure == ApiFailure.badRequest) return '현재 비밀번호가 맞지 않습니다';
  if (avatar && failure == ApiFailure.badRequest) return '이미지 파일만 올릴 수 있습니다';
  if (avatar && failure == ApiFailure.tooLarge) return '5MB 이하 사진만 올릴 수 있습니다';
  return messageFor(failure);
}
