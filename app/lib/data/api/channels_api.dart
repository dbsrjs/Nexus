import 'package:dio/dio.dart';

import '../../domain/models/channel.dart';
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
