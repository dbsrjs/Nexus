import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'desktop_shell.dart';

DesktopShell createDesktopShell() => Platform.isWindows
    ? WindowsDesktopShell()
    : const UnsupportedDesktopShell();

/// Windows 러너의 `desktop_shell.cpp` 와 짝. 채널 이름 · 메서드 이름이 그쪽과 같아야 한다.
///
/// 러너가 없는 곳(flutter_tester — `app:flow:headless` 와 위젯 테스트)에서는 채널 호출이
/// `MissingPluginException` 으로 끝난다. 그때는 「띄우지 못했다」로 접는다 — 알림 하나 때문에
/// 앱이 멈추면 안 된다.
class WindowsDesktopShell implements DesktopShell {
  WindowsDesktopShell() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationClicked' && call.arguments is String) {
        _clicks.add(call.arguments as String);
      }
    });
  }

  static const _channel = MethodChannel('nexus/desktop');

  final _clicks = StreamController<String>.broadcast();

  @override
  DesktopShellKind get kind => DesktopShellKind.windows;

  /// 트레이 알림은 OS 가 묻지 않는다. 사용자가 Windows 설정에서 끈 것은 앱이 알 수 없다.
  @override
  NotifyPermission get permission => NotifyPermission.granted;

  @override
  Future<NotifyPermission> requestPermission() async => permission;

  @override
  Future<bool> isFocused() async {
    try {
      return await _channel.invokeMethod<bool>('isForeground') ?? true;
    } on Object {
      // 모르면 「보고 있다」 쪽 — 띄우지 않는 것이 잘못 띄우는 것보다 낫다.
      return true;
    }
  }

  @override
  Future<bool> notify({
    required String title,
    required String body,
    required String tag,
    required String payload,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('notify', {
            'title': title,
            'body': body,
            'payload': payload,
          }) ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Stream<String> get clicks => _clicks.stream;

  @override
  Future<void> focus() async {
    try {
      await _channel.invokeMethod<void>('focus');
    } on Object {
      // 창을 못 꺼내도 이동은 한다 — 사용자가 창을 열면 그 화면이다.
    }
  }
}
