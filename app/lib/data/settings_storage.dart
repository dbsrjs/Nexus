import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 테마 설정 값. Material 의 `ThemePreference` 를 쓰지 않으려고 따로 둔다(15단계) —
/// 앱 뼈대가 `MaterialApp` 인 동안은 `main.dart` 가 바꿔 넘긴다.
enum ThemePreference { system, light, dark }

/// 화면 설정 보관 — 테마 · 이 기기의 데스크톱 알림.
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
  static const _desktopNotifyKey = 'nexus.desktopNotifications';
  static const _lastSpaceKey = 'nexus.lastSpace';
  static const _lastChannelKey = 'nexus.lastChannel';

  /// 저장된 테마. 없거나 읽지 못하면 **시스템을 따른다**.
  ///
  /// 실패를 던지지 않는 것이 중요하다 — 이 값을 못 읽는다고 앱이 안 켜지면
  /// 안 된다. 웹처럼 안전 저장소가 없는 곳에서도 그냥 기본값으로 뜬다.
  Future<ThemePreference> readThemePreference() async {
    try {
      return _decode(await _storage.read(key: _themeKey));
    } catch (_) {
      return ThemePreference.system;
    }
  }

  Future<void> writeThemePreference(ThemePreference mode) async {
    try {
      await _storage.write(key: _themeKey, value: _encode(mode));
    } catch (_) {
      // 저장에 실패해도 이번 실행에는 이미 반영돼 있다. 다음에 켤 때
      // 시스템 값으로 돌아갈 뿐이라 사용자를 막을 이유가 없다.
    }
  }

  /// 이 기기에서 OS 알림을 띄울지(«마지막»). **기기마다 다른 값이라 서버에 두지 않는다** —
  /// 회사 PC 에서는 끄고 집 PC 에서는 켜는 것이 자연스럽다. 없거나 못 읽으면 켠다:
  /// 웹은 브라우저 허락이 따로 있어 켜 두어도 허락 전에는 뜨지 않는다.
  Future<bool> readDesktopNotifications() async {
    try {
      return await _storage.read(key: _desktopNotifyKey) != 'off';
    } catch (_) {
      return true;
    }
  }

  Future<void> writeDesktopNotifications(bool enabled) async {
    try {
      await _storage.write(
        key: _desktopNotifyKey,
        value: enabled ? 'on' : 'off',
      );
    } catch (_) {
      // 테마와 같다 — 이번 실행에는 반영돼 있고, 다음 실행에 기본값으로 돌아갈 뿐이다.
    }
  }

  /// 마지막으로 들어간 스페이스 · 그 스페이스에서 마지막으로 본 채널(2026-10-10 UI/UX 검토).
  ///
  /// 앱을 켤 때마다 스페이스 고르기 → 「채널을 선택하세요」 빈 본문을 두 번 지나던 것을 줄인다.
  /// 기기마다 다른 값이라(이 PC 에서 보던 곳) 서버에 두지 않는다. 못 읽으면 null — 그때는
  /// 첫 스페이스 · 첫 채널로 간다. 로그아웃해도 지우지 않는다: 같은 사람이 다시 들어올 때 쓰고,
  /// 다른 사람이면 그 스페이스의 멤버가 아니라 고르기 목록에 없어 쓰이지 않는다.
  Future<String?> readLastSpace() => _readOrNull(_lastSpaceKey);

  Future<void> writeLastSpace(String spaceId) =>
      _writeQuietly(_lastSpaceKey, spaceId);

  Future<String?> readLastChannel(String spaceId) =>
      _readOrNull('$_lastChannelKey.$spaceId');

  Future<void> writeLastChannel(String spaceId, String channelId) =>
      _writeQuietly('$_lastChannelKey.$spaceId', channelId);

  Future<String?> _readOrNull(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeQuietly(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // 기억하지 못해도 다음에 첫 채널로 갈 뿐이다.
    }
  }

  /// `ThemePreference.name` 을 그대로 쓰지 않고 직접 적는다. enum 의 이름이 바뀌면
  /// 저장된 값이 조용히 안 읽히는데, 그것을 컴파일 시점에 잡을 방법이 없다.
  static String _encode(ThemePreference mode) => switch (mode) {
    ThemePreference.system => 'system',
    ThemePreference.light => 'light',
    ThemePreference.dark => 'dark',
  };

  static ThemePreference _decode(String? raw) => switch (raw) {
    'light' => ThemePreference.light,
    'dark' => ThemePreference.dark,
    _ => ThemePreference.system,
  };
}
