import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_redirect.dart';
import '../../core/router.dart';
import '../../data/socket/socket_event.dart';
import '../notifications/notifications_controller.dart';
import '../realtime/socket_controller.dart';
import '../settings/theme_controller.dart';
import '../space/members_controller.dart';
import 'desktop_shell.dart';

/// 이 기기에서 OS 알림을 띄울지 — 설정 창 「알림」의 「이 기기」 스위치.
///
/// 저장소 읽기가 비동기라 **처음 값은 false** 다. 켜는 쪽으로 틀리면 끈 사람에게 알림이
/// 한 번 새고, 끄는 쪽으로 틀리면 앱을 켠 직후 한순간의 알림 하나를 놓칠 뿐이다.
class DesktopNotifyEnabled extends Notifier<bool> {
  @override
  bool build() {
    ref.read(settingsStorageProvider).readDesktopNotifications().then((value) {
      if (ref.mounted && !_touched) state = value;
    });
    return false;
  }

  // 읽기가 끝나기 전에 사용자가 바꿨으면 늦게 온 저장값이 덮지 않게 한다.
  bool _touched = false;

  void set(bool enabled) {
    _touched = true;
    if (state == enabled) return;
    state = enabled;
    ref.read(settingsStorageProvider).writeDesktopNotifications(enabled);
  }
}

final desktopNotifyEnabledProvider =
    NotifierProvider<DesktopNotifyEnabled, bool>(DesktopNotifyEnabled.new);

/// 알림을 누르면 갈 곳으로 옮기는 일. 테스트가 라우터 없이 덮어쓴다.
final desktopNavigateProvider = Provider<void Function(String location)>(
  (ref) =>
      (location) => ref.read(routerProvider).go(location),
);

/// 새 알림(`notification:new`)을 OS 알림으로 띄우고, 누르면 그 자리로 데려간다.
///
/// **무엇을 알릴지는 서버가 이미 정했다**(종류별 스위치 · 음소거 · 볼 수 있는 채널, 18단계).
/// 여기서 더 거르는 것은 이 기기의 사정뿐이다 — 스위치 · 권한 · 지금 보고 있나.
/// 소켓은 사용자 룸으로 오므로 **지금 열린 스페이스가 아닌 곳의 알림도** 띄운다.
///
/// `main.dart` 가 뿌리에서 붙든다 — 화면 어디에 있든 받아야 한다.
final osNotificationsProvider = Provider<void>((ref) {
  final shell = ref.watch(desktopShellProvider);

  final clicks = shell.clicks.listen((payload) {
    // 알림에 실린 값을 그대로 믿지 않는다 — 앱 안 주소만(딥링크와 같은 규칙).
    final location = safeReturnPath(payload);
    if (location == null) return;
    unawaited(shell.focus());
    ref.read(desktopNavigateProvider)(location);
  });
  ref.onDispose(clicks.cancel);

  ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
    final event = next.value;
    if (event is! NotificationNew) return;
    unawaited(
      showOsNotification(
        shell: shell,
        enabled: ref.read(desktopNotifyEnabledProvider),
        spaceId: event.spaceId,
        item: event.notification,
        names: ref.read(memberNamesProvider),
      ),
    );
  });
});

/// 하나를 띄울지 정하고 띄운다. 띄웠으면 true — 테스트가 갈래마다 본다.
///
/// [names] 는 지금 스페이스의 이름표다. 다른 스페이스의 알림이면 본문 속 멘션이 이름으로
/// 바뀌지 않을 수 있다(알림함도 같다) — 머리 문구의 보낸 사람 이름은 알림에 실려 온다.
Future<bool> showOsNotification({
  required DesktopShell shell,
  required bool enabled,
  required String spaceId,
  required NotificationItem item,
  required Map<String, String> names,
}) async {
  if (!enabled || item.read) return false;
  if (shell.permission != NotifyPermission.granted) return false;
  // 보고 있으면 띄우지 않는다 — 알림함 뱃지 · 채널 표시가 이미 알린다.
  if (await shell.isFocused()) return false;
  return shell.notify(
    title: notificationHeadline(item),
    body: notificationPreview(item, names),
    // 한 채널의 알림은 하나만 남긴다(웹). 열 개가 쌓여도 누를 곳은 같다.
    tag: item.channelId,
    payload: notificationTarget(spaceId, item),
  );
}
