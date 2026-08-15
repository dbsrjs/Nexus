import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/models/message.dart';
import '../api/api_failure.dart';
import '../api/messages_api.dart';
import '../local/app_database.dart';

/// 자동 재시도를 포기하는 시도 횟수.
///
/// 서버 오류(5xx)는 일시적일 수 있어 몇 번은 다시 걸어 보지만, 무한히 반복하면
/// 사용자는 영영 실패를 모른 채 기다린다. 화면에 실패를 보여 주고 판단을 넘긴다.
const _maxAttempts = 3;

/// 메시지의 **단일 진실 공급원은 로컬 DB(drift)** 다 (docs/앱-설계.md §6).
///
/// REST 와 소켓은 로컬 DB 를 갱신하는 두 개의 입력원일 뿐이고, 화면은 언제나
/// drift 를 구독한다. 이렇게 두면 오프라인 표시와 실시간 갱신이 같은 코드
/// 경로를 탄다 — 화면이 "어디서 온 데이터인지" 를 몰라도 된다.
///
/// 6-2 에서 **전송도 같은 규칙**이 됐다. 보내기는 큐에 넣는 일이고, 실제 전송은
/// 뒤에서 일어난다. 화면은 큐에 들어간 순간 이미 그려져 있다.
class MessageRepository {
  MessageRepository({required MessagesApi api, required AppDatabase db})
      : _api = api,
        _db = db;

  final MessagesApi _api;
  final AppDatabase _db;

  /// 큐를 흘려보내는 중인지. **재진입을 막지 않으면 같은 메시지가 두 번 나간다** —
  /// 재연결과 사용자의 전송이 겹치는 순간이 실제로 있다.
  bool _flushing = false;

  /// 화면이 구독하는 스트림. 캐시가 있으면 **즉시** 첫 프레임이 그려진다.
  Stream<List<Message>> watch(String channelId) =>
      _db.watchChannelMessages(channelId);

  /// 서버에서 최신 페이지를 받아 캐시를 맞춘다.
  ///
  /// 실패해도 예외를 밖으로 내보내지 않는다 — **캐시로 이미 화면이 그려져 있으므로**
  /// 목록 전체를 오류 화면으로 바꾸면 오프라인에서 읽을 수 있다는 이점이 사라진다.
  /// 대신 성공 여부를 돌려주어 호출부가 배너 등을 결정하게 한다.
  Future<bool> refresh({
    required String spaceId,
    required String channelId,
  }) async {
    try {
      final page = await _api.list(spaceId: spaceId, channelId: channelId);
      // 서버가 준 것으로 교체한다. 서버에서 지워진 메시지가 캐시에 남지 않게 하려면
      // 병합이 아니라 교체여야 한다. 큐는 다른 테이블이라 영향을 받지 않는다.
      await _db.replaceServerMessages(spaceId, channelId, page.items);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// 위로 스크롤했을 때. 이전 페이지는 **덧붙인다**(교체가 아니다).
  Future<String?> loadOlder({
    required String spaceId,
    required String channelId,
    required String cursor,
  }) async {
    try {
      final page = await _api.list(
        spaceId: spaceId,
        channelId: channelId,
        cursor: cursor,
      );
      await _db.upsertMessages(spaceId, page.items);
      return page.nextCursor;
    } on ApiException {
      return null;
    }
  }

  /// 서버가 브로드캐스트한 메시지. 같은 id 면 덮어써도 결과가 같다(멱등).
  Future<void> applyIncoming(String spaceId, Message message) =>
      _db.upsertMessage(spaceId, message);

  Future<void> applyDeleted(String messageId) =>
      _db.markMessageDeleted(messageId, DateTime.now());

  // ── 전송 큐 ──────────────────────────────────

  /// 보내기 = **큐에 넣기.** 네트워크 상태를 묻지 않는다.
  ///
  /// 온라인이면 곧바로 이어지는 `flush()` 가 가져가고, 오프라인이면 남아 있다가
  /// 재연결 때 나간다. 화면 입장에서는 둘이 구분되지 않는다.
  Future<String> enqueue({
    required String spaceId,
    required String channelId,
    required String body,
    required MessageAuthor author,
  }) async {
    final id = _localId();
    await _db.enqueue(
      OutboxMessagesCompanion.insert(
        id: id,
        spaceId: spaceId,
        channelId: channelId,
        body: body,
        createdAt: DateTime.now(),
        authorId: author.id,
        authorName: author.name,
        authorAvatarUrl: Value(author.avatarUrl),
      ),
    );
    return id;
  }

  /// 큐를 **쓴 순서대로** 흘려보낸다.
  ///
  /// 한 채널에서 하나가 실패하면 그 채널의 나머지는 이번 회차에서 건너뛴다.
  /// 순서를 지키기 위해서다 — 2번이 실패했는데 3번이 나가면 대화가 뒤집힌다.
  /// 다른 채널은 서로 막지 않는다.
  ///
  /// 성공 개수를 돌려준다(호출부가 읽음 처리 등을 결정할 때 쓴다).
  Future<int> flush() async {
    if (_flushing) return 0;
    _flushing = true;

    var sentCount = 0;
    try {
      final queued = await _db.queuedMessages();
      final blocked = <String>{};

      for (final item in queued) {
        // 이미 포기한 항목은 사용자가 재시도를 누를 때까지 두고, 그 뒤 항목도
        // 함께 막는다. 앞을 건너뛰고 보내면 순서가 어긋난다.
        if (item.failed) {
          blocked.add(item.channelId);
          continue;
        }
        if (blocked.contains(item.channelId)) continue;

        try {
          final sent = await _api.send(
            spaceId: item.spaceId,
            channelId: item.channelId,
            body: item.body,
          );
          await _db.settleQueued(item.id, item.spaceId, sent);
          sentCount++;
        } on ApiException catch (e) {
          await _recordFailure(item, e.failure);
          blocked.add(item.channelId);
        }
      }
    } finally {
      _flushing = false;
    }
    return sentCount;
  }

  /// 사용자가 재시도를 눌렀다. 시도 기록을 지우고 다시 흘려보낸다.
  Future<void> retry(String id) async {
    await _db.requeue(id);
    await flush();
  }

  /// 사용자가 버렸다. 큐에서만 지우면 된다 — 서버에는 간 적이 없다.
  Future<void> discard(String id) => _db.removeQueued(id);

  /// 실패를 기록하고 자동 재시도를 계속할지 정한다.
  ///
  /// **네트워크 실패는 실패로 치지 않는다.** 오프라인은 정상 경로이고, 여기서
  /// 시도 횟수를 올리면 지하철에서 몇 정거장만 지나도 전부 실패로 표시된다.
  Future<void> _recordFailure(OutboxMessage item, ApiFailure failure) {
    if (failure == ApiFailure.network) {
      return _db.recordAttempt(
        item.id,
        attempts: item.attempts,
        failed: false,
        lastFailure: failure.name,
      );
    }

    final attempts = item.attempts + 1;
    // 401·404 는 다시 걸어도 결과가 같다. 채널이 사라졌거나 권한을 잃은 것이라
    // 사용자가 판단해야 한다.
    final permanent = failure == ApiFailure.unauthorized ||
        failure == ApiFailure.notFound ||
        attempts >= _maxAttempts;

    return _db.recordAttempt(
      item.id,
      attempts: attempts,
      failed: permanent,
      lastFailure: failure.name,
    );
  }

  static String _localId() =>
      'local-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
}
