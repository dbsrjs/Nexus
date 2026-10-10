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

/// 스레드 한 장. 답글 목록에 **부모가 함께 온다** — 화면이 부모부터 그린다.
class ThreadPage {
  const ThreadPage({
    required this.parent,
    required this.items,
    this.nextCursor,
  });

  final Message parent;
  final List<Message> items;
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
    return guardApi(() async {
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
    });
  }

  /// GET /api/spaces/:spaceId/messages/:messageId/replies
  Future<ThreadPage> listReplies({
    required String spaceId,
    required String messageId,
    String? cursor,
    int limit = 50,
  }) async {
    return guardApi(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/messages/$messageId/replies',
        queryParameters: {'limit': limit, 'cursor': ?cursor},
      );
      final body = res.data!;
      return ThreadPage(
        parent: Message.fromJson(body['parent'] as Map<String, dynamic>),
        items: (body['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Message.fromJson)
            .toList(growable: false),
        nextCursor: body['nextCursor'] as String?,
      );
    });
  }

  /// PATCH /api/spaces/:spaceId/messages/:id — 본인 메시지만(아니면 403). 본문은 `<@id>` 형식.
  ///
  /// **응답에는 리액션 · 멘션이 없다**(서버가 작성자만 붙인다) — 캐시에 통째로 덮지 말 것.
  Future<Message> edit({
    required String spaceId,
    required String messageId,
    required String body,
  }) async {
    return guardApi(() async {
      final res = await _client.dio.patch<Map<String, dynamic>>(
        '/spaces/$spaceId/messages/$messageId',
        data: {'body': body},
      );
      return Message.fromJson(res.data!);
    });
  }

  /// DELETE /api/spaces/:spaceId/messages/:id — 소프트 삭제. 작성자 또는 admin 이상. 멱등.
  Future<void> remove({
    required String spaceId,
    required String messageId,
  }) async {
    return guardApi(() async {
      await _client.dio.delete<void>('/spaces/$spaceId/messages/$messageId');
    });
  }

  /// 고정 · 해제. **멱등이다** - 이미 그 상태여도 같은 결과가 온다.
  Future<Message> setPinned({
    required String spaceId,
    required String messageId,
    required bool pinned,
  }) async {
    return guardApi(() async {
      final path = '/spaces/$spaceId/messages/$messageId/pin';
      final res = pinned
          ? await _client.dio.post<Map<String, dynamic>>(path)
          : await _client.dio.delete<Map<String, dynamic>>(path);
      return Message.fromJson(res.data!);
    });
  }

  /// GET /api/spaces/:spaceId/channels/:channelId/pins
  Future<List<Message>> listPinned({
    required String spaceId,
    required String channelId,
  }) async {
    return guardApi(() async {
      final res = await _client.dio.get<List<dynamic>>(
        '/spaces/$spaceId/channels/$channelId/pins',
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Message.fromJson)
          .toList(growable: false);
    });
  }

  /// POST /api/spaces/:spaceId/messages/:messageId/reactions
  ///
  /// **멱등이다.** 이미 누른 것을 다시 눌러도 서버가 같은 요약을 돌려준다.
  Future<List<MessageReaction>> addReaction({
    required String spaceId,
    required String messageId,
    required String emoji,
  }) async {
    return guardApi(() async {
      final res = await _client.dio.post<List<dynamic>>(
        '/spaces/$spaceId/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
      return _parseReactions(res.data);
    });
  }

  /// DELETE /api/spaces/:spaceId/messages/:messageId/reactions/:emoji
  ///
  /// 이모지를 경로에 싣는다 — DELETE 본문은 프록시·클라이언트에 따라 조용히
  /// 버려진다. 서버가 인코딩된 값을 받으므로 여기서 감싸 준다.
  Future<List<MessageReaction>> removeReaction({
    required String spaceId,
    required String messageId,
    required String emoji,
  }) async {
    return guardApi(() async {
      final res = await _client.dio.delete<List<dynamic>>(
        '/spaces/$spaceId/messages/$messageId/reactions/'
        '${Uri.encodeComponent(emoji)}',
      );
      return _parseReactions(res.data);
    });
  }

  static List<MessageReaction> _parseReactions(List<dynamic>? data) =>
      (data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(MessageReaction.fromJson)
          .toList(growable: false);

  /// POST /api/spaces/:spaceId/channels/:channelId/messages
  ///
  /// `parentId` 를 주면 스레드 답글이다 — 전송 경로는 채널 메시지와 하나다.
  Future<Message> send({
    required String spaceId,
    required String channelId,
    required String body,
    String? parentId,
    String? quotedMessageId,
    List<String> attachmentIds = const [],
  }) async {
    return guardApi(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/channels/$channelId/messages',
        data: {
          'body': body,
          'parentId': ?parentId,
          'quotedMessageId': ?quotedMessageId,
          if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
        },
      );
      return Message.fromJson(res.data!);
    });
  }
}
