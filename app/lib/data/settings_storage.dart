import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 화면 설정 보관. 지금은 테마 하나뿐이다.
///
/// **비밀이 아닌 값을 안전 저장소에 둔다.** 어색한 것을 안다. 그래도 이렇게
/// 한 이유는 **새 의존성을 들이지 않는 유일한 길**이어서다 — 이 프로젝트는
/// 차트 라이브러리 · 신택스 하이라이터 · 마크다운 패키지를 모두 직접 만들어
/// 거절해 왔다(`의존성은 늘리기는 쉽고 걷어내기는 어렵다`). 값 하나 때문에
/// `shared_preferences` 를 더하지 않는다.
///
/// 대가는 속도인데, **읽기는 앱 시작에 한 번뿐이라** 문제가 되지 않는다.
/// 쓰기는 사용자가 테마를 바꿀 때만 일어난다.
///
/// [AuthStorage] 와 같은 저장소를 쓰지만 클래스를 나눈 이유는 수명이 달라서다 —
/// 로그아웃은 토큰을 지우지만 테마 취향까지 지우지는 않는다.
class SettingsStorage {
  SettingsStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _themeKey = 'nexus.themeMode';

  /// 저장된 테마. 없거나 읽지 못하면 **시스템을 따른다**.
  ///
  /// 실패를 던지지 않는 것이 중요하다 — 이 값을 못 읽는다고 앱이 안 켜지면
  /// 안 된다. 웹처럼 안전 저장소가 없는 곳에서도 그냥 기본값으로 뜬다.
  Future<ThemeMode> readThemeMode() async {
    try {
      return _decode(await _storage.read(key: _themeKey));
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    try {
      await _storage.write(key: _themeKey, value: _encode(mode));
    } catch (_) {
      // 저장에 실패해도 이번 실행에는 이미 반영돼 있다. 다음에 켤 때
      // 시스템 값으로 돌아갈 뿐이라 사용자를 막을 이유가 없다.
    }
  }

  /// `ThemeMode.name` 을 그대로 쓰지 않고 직접 적는다. enum 의 이름이 바뀌면
  /// 저장된 값이 조용히 안 읽히는데, 그것을 컴파일 시점에 잡을 방법이 없다.
  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
