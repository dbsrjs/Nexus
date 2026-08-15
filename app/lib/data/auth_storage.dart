import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/models/auth_tokens.dart';
import '../domain/models/user.dart';

/// 토큰 보관. 플랫폼의 안전 저장소를 쓴다 — Windows 는 wincred,
/// Android 는 Keystore, iOS·macOS 는 Keychain (docs/앱-설계.md §7).
///
/// 웹은 안전한 저장소가 없어 다른 전략(refresh 는 HttpOnly 쿠키)이 필요하다.
/// 웹 빌드를 실제로 쓸 때 분기를 붙인다.
class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'nexus.accessToken';
  static const _refreshKey = 'nexus.refreshToken';
  static const _userKey = 'nexus.user';

  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    if (access == null || access.isEmpty) return null;
    return AuthTokens(
      accessToken: access,
      refreshToken: await _storage.read(key: _refreshKey),
    );
  }

  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    // 리프레시 토큰이 없는 응답(웹 경로)에서 기존 값을 지우지 않는다.
    // 서버가 쿠키로 관리하는 경우이기 때문이다.
    if (tokens.refreshToken != null) {
      await _storage.write(key: _refreshKey, value: tokens.refreshToken);
    }
  }

  /// 마지막으로 확인된 내 계정.
  ///
  /// **오프라인으로 앱을 켤 때 쓴다.** 서버에 못 닿으면 `/me` 로 확인할 수 없는데,
  /// 그렇다고 로그인 화면으로 보내면 캐시된 대화를 읽을 방법이 없다
  /// (docs/앱-설계.md §6 — 오프라인에서 캐시된 채널 읽기 가능).
  Future<void> writeUser(User user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<User?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 모델이 바뀌어 옛 형식이 남아 있을 수 있다. 그때는 없는 셈 친다.
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}
