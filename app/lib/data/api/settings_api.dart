import 'package:dio/dio.dart';

import '../../domain/models/auth_tokens.dart';
import '../../domain/models/user.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 설정 창이 부르는 것들(14단계). 실패는 전부 [ApiException] 으로 올린다 —
/// 화면이 종류만 보고 자기 문구를 쓴다.
class SettingsApi {
  SettingsApi(this._client);

  final ApiClient _client;

  /// PATCH /api/me { name }
  Future<User> updateName(String name) => _guard(() async {
        final res = await _client.dio.patch<Map<String, dynamic>>(
          '/me',
          data: {'name': name},
        );
        return User.fromJson(res.data!);
      });

  /// PUT /api/me/avatar — multipart `file`. 가공(256 · WebP)은 서버가 한다.
  Future<User> uploadAvatar({required List<int> bytes, required String filename}) =>
      _guard(() async {
        final form = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: filename),
        });
        final res = await _client.dio.put<Map<String, dynamic>>('/me/avatar', data: form);
        return User.fromJson(res.data!);
      });

  /// DELETE /api/me/avatar
  Future<User> removeAvatar() => _guard(() async {
        final res = await _client.dio.delete<Map<String, dynamic>>('/me/avatar');
        return User.fromJson(res.data!);
      });

  /// POST /api/auth/password. **새 토큰 쌍을 곧바로 저장한다** — 서버가 옛
  /// 세션을 전부 끊었으므로 들고 있던 리프레시 토큰은 이미 죽었다.
  ///
  /// 틀린 현재 비밀번호는 400(`badRequest`)으로 온다. 401 이 아니어서 인터셉터가
  /// 리프레시로 오인하지 않는다(설계 D12).
  Future<void> changePassword({required String current, required String next}) =>
      _guard(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/auth/password',
          data: {'currentPassword': current, 'newPassword': next, 'client': 'native'},
        );
        await _client.setTokens(AuthTokens.fromJson(res.data!));
      });

  /// PUT /api/spaces/:spaceId/channels/:channelId/mute { muted }
  Future<bool> setMuted({
    required String spaceId,
    required String channelId,
    required bool muted,
  }) =>
      _guard(() async {
        final res = await _client.dio.put<Map<String, dynamic>>(
          '/spaces/$spaceId/channels/$channelId/mute',
          data: {'muted': muted},
        );
        return res.data?['muted'] == true;
      });

  /// 사진 주소(`/users/…`)를 부를 수 있는 전체 주소로. 주소를 만드는 곳을
  /// 늘리지 않으려고 dio 의 baseUrl(= `Env.apiRoot`)을 그대로 쓴다.
  String avatarUrl(String path) => '${_client.dio.options.baseUrl}$path';

  /// 사진을 받을 때 붙일 헤더. 첨부와 같이 서버가 권한을 본다.
  Map<String, String> get authHeaders {
    final token = _client.accessToken;
    return token == null ? const {} : {'authorization': 'Bearer $token'};
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
