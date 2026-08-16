import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/models/attachment_item.dart';
import '../../domain/models/message.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 첨부 업로드 · 다운로드 (server/src/attachments).
///
/// **서명 URL 이 없다.** 서버가 바이트를 직접 흘려보내므로 주소가 하나뿐이고,
/// 스토리지 구현이 바뀌어도 앱은 그대로다. 대신 이미지 하나를 보는 데에도
/// 인증 헤더가 필요하다 — [authHeaders] 를 함께 넘겨야 한다.
class AttachmentsApi {
  AttachmentsApi(this._client);

  final ApiClient _client;

  /// 파일 하나를 올린다. **아직 어느 메시지에도 붙지 않은 상태로 끝난다.**
  ///
  /// 메시지를 보낼 때 받은 id 를 `attachmentIds` 로 넘기면 연결된다.
  /// 연결되지 못한 첨부는 서버가 24시간 뒤 정리한다.
  ///
  /// [onProgress] 는 0.0~1.0. 큰 파일에서 아무 표시가 없으면 멈춘 것으로 보인다.
  Future<MessageAttachment> upload({
    required String spaceId,
    required String channelId,
    required String filename,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/channels/$channelId/attachments',
        data: form,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          // total 이 -1 로 오는 경우가 있다(길이를 모를 때). 그때는 알리지 않는다.
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      return MessageAttachment.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// GET /api/spaces/:spaceId/attachments — 스페이스의 파일 목록.
  ///
  /// **볼 수 있는 채널의 것만** 서버가 준다. 아직 메시지에 연결되지 않은 것은
  /// 빠진다 — 남에게는 존재하지 않는 파일이고 24시간 뒤 사라질 수도 있다.
  Future<List<AttachmentItem>> listForSpace({
    required String spaceId,
    String? channelId,
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/attachments',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
          'channelId': ?channelId,
        },
      );
      return (res.data!['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(AttachmentItem.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// 첨부 바이트를 받는 주소.
  ///
  /// `Image.network` 등에 넘길 때는 [authHeaders] 를 함께 줘야 한다 —
  /// 이 주소도 다른 API 와 똑같이 `SpaceGuard` 를 지난다.
  ///
  /// [thumb] 면 미리보기용 축소본을 받는다. **없으면 서버가 원본으로 떨어뜨린다**
  /// — 파생본이 없다고 화면이 비지 않는다.
  String urlFor({
    required String spaceId,
    required String attachmentId,
    bool thumb = false,
  }) {
    final base =
        '${_client.dio.options.baseUrl}/spaces/$spaceId/attachments/$attachmentId';
    return thumb ? '$base?variant=thumb' : base;
  }

  /// 위 주소에 붙일 헤더. 토큰이 없으면 빈 맵이다.
  Map<String, String> get authHeaders {
    final token = _client.accessToken;
    return token == null ? const {} : {'authorization': 'Bearer $token'};
  }
}
