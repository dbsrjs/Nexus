import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'desktop_shell.dart';

DesktopShell createDesktopShell() => WebDesktopShell();

/// 브라우저 `Notification`. `package:web` 를 들이지 않고 쓰는 것만 직접 선언한다.
///
/// **보안 컨텍스트(https · localhost)에서만 있다.** 배포는 터널 뒤 https 라 된다.
class WebDesktopShell implements DesktopShell {
  final _clicks = StreamController<String>.broadcast();

  bool get _available =>
      globalContext.has('Notification') && _window.isSecureContext;

  @override
  DesktopShellKind get kind =>
      _available ? DesktopShellKind.web : DesktopShellKind.none;

  @override
  NotifyPermission get permission {
    if (!_available) return NotifyPermission.unsupported;
    return _decode(_Notification.permission);
  }

  @override
  Future<NotifyPermission> requestPermission() async {
    if (!_available) return NotifyPermission.unsupported;
    try {
      final answer = await _Notification.requestPermission().toDart;
      return _decode(answer.toDart);
    } on Object {
      return permission;
    }
  }

  @override
  Future<bool> isFocused() async =>
      _document.visibilityState == 'visible' && _document.hasFocus();

  @override
  Future<bool> notify({
    required String title,
    required String body,
    required String tag,
    required String payload,
  }) async {
    if (permission != NotifyPermission.granted) return false;
    try {
      final shown = _Notification(
        title,
        _NotificationOptions(body: body, tag: tag, icon: 'icons/Icon-192.png'),
      );
      shown.onclick = ((JSObject _) {
        _clicks.add(payload);
        shown.close();
      }).toJS;
      return true;
    } on Object {
      // 일부 브라우저(Android Chrome)는 생성자를 막고 서비스 워커로만 띄우게 한다.
      return false;
    }
  }

  @override
  Stream<String> get clicks => _clicks.stream;

  @override
  Future<void> focus() async => _window.focus();

  static NotifyPermission _decode(String raw) => switch (raw) {
    'granted' => NotifyPermission.granted,
    'denied' => NotifyPermission.denied,
    _ => NotifyPermission.notYet,
  };
}

@JS('Notification')
extension type _Notification._(JSObject _) implements JSObject {
  external factory _Notification(String title, _NotificationOptions options);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
  external set onclick(JSFunction? handler);
  external void close();
}

extension type _NotificationOptions._(JSObject _) implements JSObject {
  external factory _NotificationOptions({String body, String tag, String icon});
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external String get visibilityState;
  external bool hasFocus();
}

@JS('window')
external _Window get _window;

extension type _Window._(JSObject _) implements JSObject {
  external bool get isSecureContext;
  external void focus();
}
