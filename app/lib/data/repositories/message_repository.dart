import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/models/message.dart';
import '../api/api_failure.dart';
import '../api/messages_api.dart';
import '../local/app_database.dart';
import '../socket/socket_event.dart';

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

  /// 한 스레드의 답글. 부모는 채널 캐시에 이미 있으므로 따로 구독한다.
  Stream<List<Message>> watchThread(String parentId) =>
      _db.watchThreadReplies(parentId);

  /// 스레드 답글을 서버에서 받아 캐시를 맞춘다.
  ///
  /// 부모도 함께 저장한다 — 채널을 거치지 않고 스레드로 바로 들어온 경우
  /// (딥링크 · 알림) 부모가 캐시에 없을 수 있다.
  Future<bool> refreshThread({
    required String spaceId,
    required String parentId,
  }) async {
    try {
      final page = await _api.listReplies(spaceId: spaceId, messageId: parentId);
      await _db.upsertMessage(spaceId, page.parent);
      await _db.replaceThreadReplies(spaceId, parentId, page.items);
      return true;
    } on ApiException {
      return false;
    }
  }

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

  /// 답글이 달렸을 때 부모의 요약만 갱신한다.
  Future<void> applyThreadSummary(
    String parentId, {
    required int replyCount,
    DateTime? lastReplyAt,
  }) =>
      _db.setThreadSummary(
        parentId,
        replyCount: replyCount,
        lastReplyAt: lastReplyAt,
      );

  // ── 핀 ──────────────────────────────────────

  /// 고정 · 해제. 리액션과 같이 **낙관적**이다 - 누르는 즉시 반영하고
  /// 실패하면 되돌린다.
  Future<void> setPinned({
    required String spaceId,
    required String messageId,
    required bool pinned,
  }) async {
    await _db.setPinned(messageId, pinned);
    try {
      await _api.setPinned(
        spaceId: spaceId,
        messageId: messageId,
        pinned: pinned,
      );
    } on ApiException {
      await _db.setPinned(messageId, !pinned);
    }
  }

  /// 소켓이 알려 준 고정 상태.
  Future<void> applyPinChanged(String messageId, bool pinned) =>
      _db.setPinned(messageId, pinned);

  /// 채널의 고정 목록. 캐시를 거치지 않고 서버에서 바로 받는다 -
  /// 시트를 열 때만 필요하고, 없다고 대화를 읽는 데 지장이 없다.
  Future<List<Message>> pinnedMessages({
    required String spaceId,
    required String channelId,
  }) async {
    try {
      return await _api.listPinned(spaceId: spaceId, channelId: channelId);
    } on ApiException {
      return const [];
    }
  }

  // ── 리액션 ───────────────────────────────────

  /// 이모지를 켜고 끈다. **먼저 캐시를 고치고 서버에 알린다.**
  ///
  /// 리액션은 누르자마자 반응해야 하는 조작이라 왕복을 기다리지 않는다.
  /// 실패하면 서버가 준 값으로 되돌린다 — 메시지 전송과 달리 큐에 쌓지 않는
  /// 이유는, 리액션은 **지금 이 순간의 반응**이라 나중에 몰아 보낼 값이
  /// 아니기 때문이다. 실패하면 조용히 원래대로 돌아가는 편이 낫다.
  Future<void> toggleReaction({
    required String spaceId,
    required String messageId,
    required String emoji,
    required bool add,
  }) async {
    final before = await _db.reactionsOf(messageId);
    await _db.setReactions(messageId, _applyLocally(before, emoji, add: add));

    try {
      final settled = add
          ? await _api.addReaction(
              spaceId: spaceId, messageId: messageId, emoji: emoji)
          : await _api.removeReaction(
              spaceId: spaceId, messageId: messageId, emoji: emoji);
      await _db.setReactions(messageId, settled);
    } on ApiException {
      await _db.setReactions(messageId, before);
    }
  }

  /// 소켓이 알려 준 변화. `(emoji, userId)` 쌍을 **내 기준으로** 접는다.
  Future<void> applyReactionChanged(
    String messageId,
    List<ReactionEntry> entries,
    String myUserId,
  ) =>
      _db.setReactions(messageId, foldReactions(entries, myUserId));

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
    String? parentId,
    String? quotedMessageId,
    QuotedMessage? quoted,
    List<MessageAttachment> attachments = const [],
  }) async {
    final id = _localId();
    await _db.enqueue(
      OutboxMessagesCompanion.insert(
        id: id,
        spaceId: spaceId,
        channelId: channelId,
        body: body,
        parentId: Value(parentId),
        quotedMessageId: Value(quotedMessageId),
        // 요약도 함께 넣는다 — 큐에 있는 동안에는 서버에서 원본을 받아올 수
        // 없으므로, 이 값이 없으면 인용문이 빈 채로 보인다.
        quoted: Value(quoted),
        // 첨부는 **이미 서버에 올라가 있다.** 큐가 들고 있는 것은 id 와,
        // 큐에 있는 동안 파일 이름을 그리기 위한 요약뿐이다.
        attachmentIds: Value([for (final a in attachments) a.id]),
        attachments: Value(attachments),
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
            parentId: item.parentId,
            quotedMessageId: item.quotedMessageId,
            attachmentIds: item.attachmentIds,
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

/// 낙관적 토글. 서버 응답이 오기 전 화면에 보일 값을 만든다.
///
/// **순서를 유지한다** — 개수 순으로 재정렬하면 남이 리액션을 달 때마다 버튼이
/// 움직여 누르기 어려워진다. 서버의 요약 규칙과 같은 원칙이다.
List<MessageReaction> _applyLocally(
  List<MessageReaction> current,
  String emoji, {
  required bool add,
}) {
  final result = <MessageReaction>[];
  var found = false;

  for (final reaction in current) {
    if (reaction.emoji != emoji) {
      result.add(reaction);
      continue;
    }
    found = true;

    if (add) {
      // 이미 내가 누른 상태면 그대로 둔다(멱등).
      result.add(reaction.mine
          ? reaction
          : reaction.copyWith(count: reaction.count + 1, mine: true));
    } else if (reaction.mine && reaction.count > 1) {
      result.add(reaction.copyWith(count: reaction.count - 1, mine: false));
    } else if (!reaction.mine) {
      result.add(reaction);
    }
    // 내가 마지막 한 명이었으면 항목 자체가 사라진다.
  }

  if (add && !found) {
    result.add(MessageReaction(emoji: emoji, count: 1, mine: true));
  }
  return result;
}

/// `(emoji, userId)` 쌍 → 이모지별 요약. 서버의 fold 와 같은 규칙이다.
///
/// 앱에도 같은 계산이 필요한 이유: 소켓 브로드캐스트에는 `mine` 이 실려 오지
/// 않는다(받는 사람마다 답이 다르다). 내 userId 로 여기서 접는다.
List<MessageReaction> foldReactions(
  List<ReactionEntry> entries,
  String myUserId,
) {
  final order = <String>[];
  final counts = <String, int>{};
  final mine = <String, bool>{};

  for (final entry in entries) {
    if (!counts.containsKey(entry.emoji)) {
      order.add(entry.emoji);
      counts[entry.emoji] = 0;
      mine[entry.emoji] = false;
    }
    counts[entry.emoji] = counts[entry.emoji]! + 1;
    if (entry.userId == myUserId) mine[entry.emoji] = true;
  }

  return [
    for (final emoji in order)
      MessageReaction(
        emoji: emoji,
        count: counts[emoji]!,
        mine: mine[emoji]!,
      ),
  ];
}
