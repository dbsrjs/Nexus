import 'package:dio/dio.dart';

import '../../domain/models/channel.dart';
import '../../domain/models/channel_access.dart';
import '../../domain/models/space.dart';
import 'api_client.dart';
import 'api_failure.dart';

class ChannelsApi {
  ChannelsApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces/:spaceId/channels — 내가 볼 수 있는 채널만.
  ///
  /// 비공개 채널은 채널 멤버가 아니면 아예 목록에 없다. 안 읽은 수도 서버가
  /// 계산해서 함께 준다 (docs/백엔드-설계.md §6 채널 가시성).
  Future<List<Channel>> list(String spaceId) async {
    try {
      final res =
          await _client.dio.get<List<dynamic>>('/spaces/$spaceId/channels');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Channel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// GET /api/spaces/:spaceId/categories
  Future<List<Category>> listCategories(String spaceId) async {
    try {
      final res =
          await _client.dio.get<List<dynamic>>('/spaces/$spaceId/categories');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  // ── 16단계 — 채널 만들기 · 고치기 · 비공개 명단 · 권한 ──────────

  /// POST /api/spaces/:spaceId/channels (admin+). 만든 사람은 그 채널의 멤버가 된다.
  Future<Channel> create(
    String spaceId, {
    required String name,
    String? topic,
    String? categoryId,
    bool isPrivate = false,
  }) =>
      _guard(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/spaces/$spaceId/channels',
          data: {
            'name': name,
            'topic': ?topic,
            'categoryId': ?categoryId,
            'isPrivate': isPrivate,
          },
        );
        return Channel.fromJson(res.data!);
      });

  /// POST /api/spaces/:spaceId/dms — 그 사람과의 DM 을 연다(17단계 D3). 있으면 그것, 없으면
  /// 만든다. 응답은 채널 목록 한 줄과 같은 모양이다.
  Future<Channel> openDm(String spaceId, String userId) => _guard(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/spaces/$spaceId/dms',
          data: {'userId': userId},
        );
        return Channel.fromJson(res.data!);
      });

  /// PATCH /api/spaces/:spaceId/channels/:channelId (admin+). 준 값만 바꾼다.
  Future<void> update(
    String spaceId,
    String channelId, {
    String? name,
    String? topic,
    bool? isPrivate,
  }) =>
      _guard(() => _client.dio.patch<void>(
            '/spaces/$spaceId/channels/$channelId',
            data: {'name': ?name, 'topic': ?topic, 'isPrivate': ?isPrivate},
          ));

  /// GET …/members — 비공개 채널의 명단. 공개 채널은 400.
  Future<List<ChannelMemberView>> members(String spaceId, String channelId) =>
      _guard(() async {
        final res = await _client.dio
            .get<List<dynamic>>('/spaces/$spaceId/channels/$channelId/members');
        return (res.data ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ChannelMemberView.fromJson)
            .toList(growable: false);
      });

  /// POST …/members { userIds } — 멱등. 스페이스 멤버가 아닌 id 가 섞이면 404.
  Future<List<ChannelMemberView>> addMembers(
    String spaceId,
    String channelId,
    List<String> userIds,
  ) =>
      _guard(() async {
        final res = await _client.dio.post<List<dynamic>>(
          '/spaces/$spaceId/channels/$channelId/members',
          data: {'userIds': userIds},
        );
        return (res.data ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ChannelMemberView.fromJson)
            .toList(growable: false);
      });

  /// DELETE …/members/:userId — 본인이면 나가기. 마지막 한 명은 409.
  Future<void> removeMember(String spaceId, String channelId, String userId) =>
      _guard(() => _client.dio
          .delete<void>('/spaces/$spaceId/channels/$channelId/members/$userId'));

  /// GET …/permissions (admin+) — 손님 · 멤버 두 줄.
  Future<List<RolePermission>> permissions(String spaceId, String channelId) =>
      _guard(() async {
        final res = await _client.dio.get<List<dynamic>>(
          '/spaces/$spaceId/channels/$channelId/permissions',
        );
        return (res.data ?? const [])
            .cast<Map<String, dynamic>>()
            .map(RolePermission.fromJson)
            .toList(growable: false);
      });

  /// PUT …/permissions/:role { canView, canSend } (admin+)
  Future<void> setPermission(
    String spaceId,
    String channelId,
    SpaceRole role, {
    required bool canView,
    required bool canSend,
  }) =>
      _guard(() => _client.dio.put<void>(
            '/spaces/$spaceId/channels/$channelId/permissions/${role.wire}',
            data: {'canView': canView, 'canSend': canSend},
          ));

  /// DELETE …/permissions/:role (admin+) — 기본값으로.
  Future<void> resetPermission(String spaceId, String channelId, SpaceRole role) =>
      _guard(() => _client.dio.delete<void>(
            '/spaces/$spaceId/channels/$channelId/permissions/${role.wire}',
          ));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// POST /api/spaces/:spaceId/channels/:channelId/read
  ///
  /// 기준 시각은 서버가 그 메시지의 created_at 으로 잡는다 — 기기 시계가
  /// 틀어져 있어도 읽음 위치가 어긋나지 않는다. 뒤로 되돌지도 않는다.
  Future<void> markRead({
    required String spaceId,
    required String channelId,
    required String lastReadMessageId,
  }) async {
    try {
      await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/channels/$channelId/read',
        data: {'lastReadMessageId': lastReadMessageId},
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
