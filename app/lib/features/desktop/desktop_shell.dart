import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop_shell_io.dart'
    if (dart.library.js_interop) 'desktop_shell_web.dart'
    as platform;

/// 이 기기가 어떤 알림 길을 가졌나. 설정 창의 설명 문구가 갈린다.
enum DesktopShellKind { windows, web, none }

/// OS 알림 권한. Windows 는 늘 [granted](트레이 알림은 묻지 않는다), 웹은 브라우저가 정한다.
enum NotifyPermission { granted, notYet, denied, unsupported }

/// OS 와 닿는 곳(«마지막» 데스크톱 · 웹 알림 + 트레이) — 알림 띄우기 · 앞에 있나 · 창 꺼내기.
///
/// 플랫폼마다 구현이 하나씩이다: Windows 는 러너의 `desktop_shell.cpp`(트레이 아이콘의
/// 풍선 → 토스트), 웹은 브라우저 `Notification`. 나머지(Android · iOS)는 [none] —
/// 모바일 푸시(FCM)는 이 단계에서 뺐다(보스 결정, 2026-10-09).
///
/// 패키지를 들이지 않는다 — Windows 는 Shell_NotifyIcon, 웹은 `dart:js_interop` 으로
/// 충분하다(CLAUDE.md §3-8).
abstract class DesktopShell {
  DesktopShellKind get kind;

  NotifyPermission get permission;

  /// 웹에서만 브라우저에 묻는다. **사용자가 누른 직후에 불러야 한다** — 브라우저는
  /// 클릭 없이 묻는 요청을 조용히 거절한다.
  Future<NotifyPermission> requestPermission();

  /// 사용자가 지금 이 앱을 보고 있나. 보고 있으면 OS 알림을 띄우지 않는다 —
  /// 알림함 뱃지와 채널 표시가 이미 알린다.
  Future<bool> isFocused();

  /// 띄웠으면 true. [tag] 가 같은 알림은 옛것을 덮는다(웹 — 한 채널에 하나).
  /// [payload] 는 누르면 [clicks] 로 돌아온다(갈 주소).
  Future<bool> notify({
    required String title,
    required String body,
    required String tag,
    required String payload,
  });

  /// 사용자가 누른 알림의 [notify] payload.
  Stream<String> get clicks;

  /// 창을 앞으로 꺼낸다(트레이에 숨어 있으면 다시 보인다).
  Future<void> focus();
}

/// 데스크톱 · 웹이 아닌 곳. 아무것도 띄우지 않는다.
class UnsupportedDesktopShell implements DesktopShell {
  const UnsupportedDesktopShell();

  @override
  DesktopShellKind get kind => DesktopShellKind.none;

  @override
  NotifyPermission get permission => NotifyPermission.unsupported;

  @override
  Future<NotifyPermission> requestPermission() async =>
      NotifyPermission.unsupported;

  @override
  Future<bool> isFocused() async => true;

  @override
  Future<bool> notify({
    required String title,
    required String body,
    required String tag,
    required String payload,
  }) async => false;

  @override
  Stream<String> get clicks => const Stream.empty();

  @override
  Future<void> focus() async {}
}

/// 테스트는 가짜로 덮어쓴다.
final desktopShellProvider = Provider<DesktopShell>(
  (ref) => platform.createDesktopShell(),
);
