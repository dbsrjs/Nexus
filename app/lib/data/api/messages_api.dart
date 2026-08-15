import 'package:dio/dio.dart';

import '../../domain/models/message.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 커서 페이지네이션 한 장.
class MessagePage {
  const MessagePage({required this.items, this.nextCursor});

  /// **최신순**이다. 채팅 화면은 reverse ListView 로 그리므로 이 순서가 맞다.
  final List<Message> items;

  /// null 이면 더 없다.
  final String? nextCursor;
}

class MessagesApi {
  MessagesApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces/:spaceId/channels/:channelId/messages
  ///
  /// 스레드 답글(parentId != null)은 서버가 빼고 준다 — 채널 타임라인에
  /// 섞이지 않는다 (docs/백엔드-설계.md §3).
  Future<MessagePage> list({
    required String spaceId,
    required String channelId,
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/channels/$channelId/messages',
        queryParameters: {'limit': limit, 'cursor': ?cursor},
      );
      final body = res.data!;
      return MessagePage(
        items: (body['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Message.fromJson)
            .toList(growable: false),
        nextCursor: body['nextCursor'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// POST /api/spaces/:spaceId/channels/:channelId/messages
  Future<Message> send({
    required String spaceId,
    required String channelId,
    required String body,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/channels/$channelId/messages',
        data: {'body': body},
      );
      return Message.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
