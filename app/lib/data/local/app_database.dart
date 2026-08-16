import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/message.dart';

part 'app_database.g.dart';

/// 시각을 **UTC 마이크로초 정수**로 저장한다.
///
/// drift 의 `DateTimeColumn` 은 둘 다 문제가 있었다.
/// - 기본값(Unix **초**)은 밀리초를 잘라, 같은 초에 도착한 메시지가 정렬에서
///   동률이 되고 순서가 뒤집혔다.
/// - `storeDateTimeAsText` 는 `toIso8601String()` 을 그대로 쓰는데, Dart 는
///   **마이크로초가 0이면 소수점 3자리, 아니면 6자리**로 자릿수를 바꾸고
///   로컬 시각에는 ` +09:00`, UTC 에는 `Z` 를 붙인다. 문자열 정렬이 곧 시간
///   순서라는 전제가 깨진다 — 캐시(서버 UTC)와 큐(로컬)를 함께 정렬하는
///   이 앱에서는 특히 그렇다.
///
/// 정수로 두면 정렬이 정수 비교라 형식 문제가 아예 없고, 마이크로초까지 남는다.
class _UtcMicros extends TypeConverter<DateTime, int> {
  const _UtcMicros();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMicrosecondsSinceEpoch(fromDb, isUtc: true).toLocal();

  @override
  int toSql(DateTime value) => value.toUtc().microsecondsSinceEpoch;
}

/// 리액션 요약을 JSON 한 칸에 담는다.
///
/// 작성자(author)는 컬럼으로 펼쳐 놓고 이것만 JSON 인 이유는 **쓰임이 다르기
/// 때문이다.** 목록의 정렬·필터는 전부 SQL 에서 일어나야 하지만, 리액션은
/// 정렬 대상이 아니고 항상 서버가 준 요약으로 **통째로 갈아 끼운다**.
/// 부분 갱신이 없으므로 테이블을 나눠 조인할 값이 없다.
class _ReactionsJson extends TypeConverter<List<MessageReaction>, String> {
  const _ReactionsJson();

  @override
  List<MessageReaction> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(MessageReaction.fromJson)
        .toList(growable: false);
  }

  @override
  String toSql(List<MessageReaction> value) =>
      jsonEncode([for (final r in value) r.toJson()]);
}

/// 인용 요약을 JSON 한 칸에 담는다. 리액션과 같은 이유다 —
/// 정렬·필터 대상이 아니고 서버가 준 값으로 통째로 갈아 끼운다.
class _QuotedJson extends TypeConverter<QuotedMessage?, String> {
  const _QuotedJson();

  @override
  QuotedMessage? fromSql(String fromDb) {
    if (fromDb.isEmpty) return null;
    return QuotedMessage.fromJson(
      jsonDecode(fromDb) as Map<String, dynamic>,
    );
  }

  @override
  String toSql(QuotedMessage? value) =>
      value == null ? '' : jsonEncode(value.toJson());
}

/// 멘션 목록을 JSON 한 칸에 담는다. 리액션 · 인용과 같은 이유다.
class _MentionsJson extends TypeConverter<List<MessageMention>, String> {
  const _MentionsJson();

  @override
  List<MessageMention> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    return (jsonDecode(fromDb) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MessageMention.fromJson)
        .toList(growable: false);
  }

  @override
  String toSql(List<MessageMention> value) =>
      value.isEmpty ? '' : jsonEncode([for (final m in value) m.toJson()]);
}

class _AttachmentsJson extends TypeConverter<List<MessageAttachment>, String> {
  const _AttachmentsJson();

  @override
  List<MessageAttachment> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    return (jsonDecode(fromDb) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MessageAttachment.fromJson)
        .toList(growable: false);
  }

  @override
  String toSql(List<MessageAttachment> value) =>
      value.isEmpty ? '' : jsonEncode([for (final a in value) a.toJson()]);
}

/// 큐에 담아 둔 첨부 id 목록. 전송할 때 서버로 넘긴다.
class _IdListJson extends TypeConverter<List<String>, String> {
  const _IdListJson();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    return (jsonDecode(fromDb) as List<dynamic>).cast<String>();
  }

  @override
  String toSql(List<String> value) => value.isEmpty ? '' : jsonEncode(value);
}

/// 메시지 캐시. **서버에 있는 것만** 담는다.
///
/// 서버 모델을 그대로 펼쳐 담는다. 중첩(author)을 JSON 으로 넣지 않는 이유는,
/// 목록 정렬·필터가 전부 SQL 에서 일어나야 하기 때문이다.
///
/// 아직 보내지 못한 메시지는 여기 없다 — `OutboxMessages` 로 간다. 그래야
/// 이 테이블을 언제든 버리고 서버에서 다시 받을 수 있다.
class CachedMessages extends Table {
  TextColumn get id => text()();

  TextColumn get spaceId => text()();
  TextColumn get channelId => text()();
  TextColumn get body => text()();
  IntColumn get createdAt => integer().map(const _UtcMicros())();
  IntColumn get editedAt => integer().map(const _UtcMicros()).nullable()();
  IntColumn get deletedAt => integer().map(const _UtcMicros()).nullable()();

  TextColumn get authorId => text()();
  TextColumn get authorName => text()();
  TextColumn get authorAvatarUrl => text().nullable()();

  TextColumn get reactions =>
      text().map(const _ReactionsJson()).withDefault(const Constant('[]'))();

  /// 값이 있으면 스레드 답글이다. **채널 타임라인 조회는 이것이 NULL 인 것만
  /// 본다** — 서버가 그렇게 나누므로 캐시도 같은 규칙이어야 한다.
  TextColumn get parentId => text().nullable()();
  IntColumn get replyCount => integer().withDefault(const Constant(0))();
  IntColumn get lastReplyAt =>
      integer().map(const _UtcMicros()).nullable()();

  /// 답장이면 인용 요약. 빈 문자열이면 답장이 아니다.
  TextColumn get quoted =>
      text().map(const _QuotedJson()).withDefault(const Constant(''))();

  /// 본문의 `<@id>` 를 이름으로 바꾸는 데 쓰는 멘션 목록.
  TextColumn get mentions =>
      text().map(const _MentionsJson()).withDefault(const Constant(''))();

  /// 채널 상단에 고정됐는지.
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  /// 붙은 파일 요약. 바이트는 여기 없다 — 볼 때 서버에서 받는다.
  TextColumn get attachments =>
      text().map(const _AttachmentsJson()).withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 전송 큐. **아직 서버에 닿지 못한 메시지**가 여기 쌓인다.
///
/// 캐시와 나눠 둔 이유는 성격이 다르기 때문이다. 캐시는 지워도 서버에서 다시
/// 받으면 그만이지만, **큐에 있는 것은 사용자가 쓴 유일본이다.** 한 테이블에
/// 두면 캐시 스키마가 바뀔 때마다(통째 재생성) 못 보낸 메시지가 함께 사라진다.
///
/// 그래서 마이그레이션에서 이 테이블만 남긴다. 스키마도 서버 모델을 따르지
/// 않아 잘 바뀌지 않는다 — 보낼 내용과 시도 기록뿐이다.
class OutboxMessages extends Table {
  /// 로컬에서 만든 임시 id(`local-…`). 전송에 성공하면 서버 id 로 대체된다.
  TextColumn get id => text()();

  TextColumn get spaceId => text()();
  TextColumn get channelId => text()();
  TextColumn get body => text()();

  /// 스레드 답글이면 부모 id. 오프라인에서 쓴 답글도 답글로 나가야 한다.
  TextColumn get parentId => text().nullable()();

  /// 답장이면 인용 대상 id. 큐에서도 답장은 답장으로 나가야 한다.
  TextColumn get quotedMessageId => text().nullable()();

  /// 인용 요약. 큐에 있는 동안 화면에 인용문을 그리려면 필요하다 —
  /// 서버에 닿기 전에는 원본을 서버에서 받아올 수 없다.
  TextColumn get quoted =>
      text().map(const _QuotedJson()).withDefault(const Constant(''))();

  /// 붙일 첨부의 id. **파일 자체는 큐에 없다** — 이미 서버에 올라가 있다.
  ///
  /// 업로드는 온라인에서만 되지만, 한 번 올라가면 그 뒤 오프라인이 되어도
  /// 이 메시지는 큐에서 기다렸다 나갈 수 있다. 다만 **24시간 안에 나가야
  /// 한다** — 그 전에 연결되지 못한 첨부는 서버가 고아로 보고 지운다.
  TextColumn get attachmentIds =>
      text().map(const _IdListJson()).withDefault(const Constant(''))();

  /// 첨부 요약. 큐에 있는 동안 화면에 파일 이름을 그리려면 필요하다 —
  /// 인용 요약을 함께 담아 두는 것과 같은 이유다.
  TextColumn get attachments =>
      text().map(const _AttachmentsJson()).withDefault(const Constant(''))();

  /// 사용자가 **쓴** 시각. 서버 도착 시각이 아니다.
  IntColumn get createdAt => integer().map(const _UtcMicros())();

  /// 큐에 들어온 순서. **전송 순서는 시각이 아니라 이 값이 정한다.**
  ///
  /// 시각으로 정렬하면 안 되는 이유: Windows 의 `DateTime.now()` 는 밀리초
  /// 해상도라, 연속으로 보낸 메시지 여러 건이 **완전히 같은 값**을 갖는다.
  /// 그러면 순서가 tie-break 에 맡겨지고 실제로 뒤집혔다(테스트가 15회 중
  /// 5회 실패했다). 삽입 순서는 저장해 두어야 확실하다.
  IntColumn get seq => integer().withDefault(const Constant(0))();

  // 화면에 그리려면 작성자가 필요하다. 지금은 늘 '나'지만, 목록 조회가
  // 캐시와 같은 모양이어야 한 쿼리로 합칠 수 있다.
  TextColumn get authorId => text()();
  TextColumn get authorName => text()();
  TextColumn get authorAvatarUrl => text().nullable()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// 자동 재시도를 포기한 상태. 사용자가 재시도하거나 버릴 때까지 남는다.
  /// **조용히 지우지 않는다** — 사라지면 사용자는 보냈다고 믿는다.
  BoolColumn get failed => boolean().withDefault(const Constant(false))();

  /// 마지막 실패 종류(`ApiFailure` 의 이름). 진단용이며 화면 문구는 앱이 정한다.
  TextColumn get lastFailure => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 채널 캐시. 오프라인에서도 채널 목록이 보여야 한다.
class CachedChannels extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  TextColumn get key => text()();
  TextColumn get name => text()();
  TextColumn get topic => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// 안 읽은 **멘션** 수. 안 읽은 수와 따로 센다.
  IntColumn get mentionCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 카테고리 캐시.
///
/// 처음에는 캐시하지 않았다 — "채널 묶음의 제목일 뿐이라 없으면 '기타'로
/// 모이면 된다"고 봤다. 그 판단이 **실기기에서 버그로 드러났다**: 오프라인에서
/// 한 번 빈 목록을 받으면 서버가 돌아와도 채널이 계속 '기타'에 묶여 있었다.
/// 채널은 캐시를 구독하는데 카테고리만 REST 를 한 번 부르고 끝이라, 그 경계에
/// 회복되지 않는 지점이 생긴 것이다.
///
/// **화면 하나가 두 개의 진실 공급원을 보면 이런 틈이 생긴다.** 그래서 캐시로
/// 옮긴다 — 테이블 하나를 아끼는 값보다 이쪽이 크다.
class CachedCategories extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 스페이스 캐시. 오프라인으로 앱을 켜면 여기서 목록을 그린다 —
/// 첫 화면부터 막히면 대화 캐시까지 도달할 수 없다.
class CachedSpaces extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get iconUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CachedMessages,
    CachedChannels,
    CachedCategories,
    CachedSpaces,
    OutboxMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'nexus'));

  @override
  int get schemaVersion => 12;

  /// **캐시는 서버에서 다시 받을 수 있다.** 그래서 스키마가 바뀌면 데이터를
  /// 옮기지 않고 통째로 다시 만든다 — 마이그레이션을 한 단계씩 쓰는 값이
  /// 이 데이터에는 없다.
  ///
  /// 이 전략이 없어서 실제로 한 번 깨졌다: 테이블을 추가하고 버전을 올리지
  /// 않으니 기존 파일에 그 테이블이 없어 `no such table` 로 앱이 멈췄다.
  ///
  /// **다만 전송 큐는 건드리지 않는다.** 캐시는 버려도 되지만 큐에 있는 것은
  /// 사용자가 쓴 유일본이다. 이 구분이 두 테이블을 나눈 이유다.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          for (final table in _rebuildableCaches) {
            await m.deleteTable(table.actualTableName);
          }
          // 이미 있는 테이블은 건너뛴다(큐가 여기 해당한다).
          await m.createAll();

          // 시각 저장 형식이 두 번 바뀌었다(초 → 텍스트 → UTC 마이크로초).
          // 캐시는 방금 다시 만들었으니 상관없지만 **큐는 남겨 두므로**
          // 옛 형식으로 저장된 행을 직접 옮긴다.
          // 8 에서 큐에 스레드 답글이, 9 에서 답장이 들어올 수 있게 됐다.
          // 캐시와 달리 큐는 남겨 두므로 컬럼을 직접 붙인다.
          if (from < 8) {
            await m.addColumn(outboxMessages, outboxMessages.parentId);
          }
          if (from < 9) {
            await m.addColumn(outboxMessages, outboxMessages.quotedMessageId);
            await m.addColumn(outboxMessages, outboxMessages.quoted);
          }
          if (from < 12) {
            await m.addColumn(outboxMessages, outboxMessages.attachmentIds);
            await m.addColumn(outboxMessages, outboxMessages.attachments);
          }

          if (from < 6) {
            // 순번 컬럼이 없던 시절의 행에는 삽입 순서(rowid)를 넣어 준다.
            await m.addColumn(outboxMessages, outboxMessages.seq);
            await customStatement(
              'UPDATE outbox_messages SET seq = rowid WHERE seq = 0',
            );

            // 5 에서 쓰던 ISO-8601 텍스트.
            await customStatement(
              "UPDATE outbox_messages "
              "SET created_at = CAST(strftime('%s', created_at) AS INTEGER) * 1000000 "
              "WHERE typeof(created_at) = 'text'",
            );
            // 4 이하에서 쓰던 Unix 초. 마이크로초 값(~1.7e15)과는 자릿수로
            // 구분된다 — 초는 ~1.7e9 다.
            await customStatement(
              'UPDATE outbox_messages SET created_at = created_at * 1000000 '
              "WHERE typeof(created_at) = 'integer' AND created_at < 100000000000",
            );
          }
        },
      );

  /// 스키마가 바뀌면 통째로 다시 만드는 테이블. **큐는 여기 없다.**
  List<TableInfo<Table, dynamic>> get _rebuildableCaches =>
      [cachedMessages, cachedChannels, cachedCategories, cachedSpaces];

  // ──────────────────────────────────────────────
  // 메시지
  // ──────────────────────────────────────────────

  /// 채널의 메시지를 **최신순**으로 구독한다. 캐시와 전송 큐를 합쳐서 준다.
  ///
  /// UI 는 이 스트림만 본다. REST 응답도 소켓 이벤트도 여기 쓰기만 하면
  /// 화면에 반영된다 — 두 입력원이 같은 코드 경로를 탄다
  /// (docs/앱-설계.md §6).
  ///
  /// **두 테이블을 SQL 에서 합치는 이유**: 스트림 두 개를 Dart 에서 결합하면
  /// 정렬·개수 제한을 메모리에서 다시 해야 하고, 한쪽만 갱신됐을 때 순서가
  /// 잠깐 어긋난다. `readsFrom` 을 주면 어느 쪽이 바뀌어도 이 스트림이 다시 흐른다.
  Stream<List<Message>> watchChannelMessages(String channelId, {int limit = 100}) {
    return _watchMessages(
      channelId: channelId,
      // 채널 타임라인은 **최상위만** 본다. 답글은 스레드 화면에만 나온다.
      cachedWhere: 'parent_id IS NULL',
      outboxWhere: 'parent_id IS NULL',
      limit: limit,
    );
  }

  /// 한 스레드의 답글. 부모는 포함하지 않는다 — 화면이 따로 그린다.
  Stream<List<Message>> watchThreadReplies(String parentId, {int limit = 200}) {
    return _watchMessages(
      channelId: null,
      cachedWhere: 'parent_id = ?1',
      outboxWhere: 'parent_id = ?1',
      key: parentId,
      limit: limit,
    );
  }

  /// 캐시와 큐를 합쳐 읽는 공통 경로. 조건만 갈아 끼운다.
  Stream<List<Message>> _watchMessages({
    required String? channelId,
    required String cachedWhere,
    required String outboxWhere,
    required int limit,
    String? key,
  }) {
    final match = channelId ?? key!;
    return customSelect(
      '''
      SELECT id, channel_id, body, created_at, edited_at, deleted_at,
             author_id, author_name, author_avatar_url, reactions, quoted, mentions,
             pinned, attachments,
             parent_id, reply_count, last_reply_at,
             0 AS queued, 0 AS failed, 0 AS seq
        FROM cached_messages
       WHERE ${channelId != null ? 'channel_id = ?1' : cachedWhere}
         ${channelId != null ? 'AND $cachedWhere' : ''}
      UNION ALL
      SELECT id, channel_id, body, created_at, NULL, NULL,
             author_id, author_name, author_avatar_url, '[]' AS reactions, quoted,
             '' AS mentions, 0 AS pinned, attachments,
             parent_id, 0 AS reply_count, NULL AS last_reply_at,
             1 AS queued, failed, seq
        FROM outbox_messages
       WHERE ${channelId != null ? 'channel_id = ?1' : outboxWhere}
         ${channelId != null ? 'AND $outboxWhere' : ''}
       ORDER BY created_at DESC, seq DESC
       LIMIT ?2
      ''',
      variables: [Variable<String>(match), Variable<int>(limit)],
      readsFrom: {cachedMessages, outboxMessages},
    ).watch().map(
          (rows) => rows.map(_rowToMessage).toList(growable: false),
        );
  }

  Future<void> upsertMessages(String spaceId, List<Message> messages) async {
    if (messages.isEmpty) return;
    await batch((b) {
      for (final message in messages) {
        b.insert(
          cachedMessages,
          _toRow(spaceId, message),
          onConflict: DoUpdate((_) => _toRow(spaceId, message)),
        );
      }
    });
  }

  Future<void> upsertMessage(String spaceId, Message message) =>
      upsertMessages(spaceId, [message]);

  Future<void> deleteMessage(String id) =>
      (delete(cachedMessages)..where((m) => m.id.equals(id))).go();

  /// 리액션만 갈아 끼운다.
  ///
  /// 메시지 행 전체를 다시 쓰지 않는 이유: 소켓으로 오는 리액션 이벤트에는
  /// 본문·작성자가 없다. 통째로 upsert 하면 그 값들을 잃는다.
  ///
  /// 캐시에 없는 메시지면 아무 일도 하지 않는다 — 아직 받지 못한 메시지의
  /// 리액션은 다음 새로고침 때 함께 온다.
  /// 메시지 하나를 구독한다. 스레드 화면이 부모를 그릴 때 쓴다 —
  /// 답글이 달리면 `replyCount` 가 바뀌므로 한 번 읽고 마는 대신 구독한다.
  Stream<Message?> watchMessage(String id) => customSelect(
        '''
        SELECT id, channel_id, body, created_at, edited_at, deleted_at,
               author_id, author_name, author_avatar_url, reactions, quoted, mentions,
             pinned, attachments,
               parent_id, reply_count, last_reply_at,
               0 AS queued, 0 AS failed, 0 AS seq
          FROM cached_messages
         WHERE id = ?1
        ''',
        variables: [Variable<String>(id)],
        readsFrom: {cachedMessages},
      ).watch().map((rows) => rows.isEmpty ? null : _rowToMessage(rows.first));

  /// 답글이 달렸을 때 부모의 요약만 고친다. 본문·작성자는 건드리지 않는다.
  Future<void> setThreadSummary(
    String messageId, {
    required int replyCount,
    DateTime? lastReplyAt,
  }) =>
      (update(cachedMessages)..where((m) => m.id.equals(messageId))).write(
        CachedMessagesCompanion(
          replyCount: Value(replyCount),
          lastReplyAt: Value(lastReplyAt),
        ),
      );

  /// 고정 상태만 갈아 끼운다. 소켓 이벤트에는 본문이 없다.
  Future<void> setPinned(String messageId, bool pinned) =>
      (update(cachedMessages)..where((m) => m.id.equals(messageId)))
          .write(CachedMessagesCompanion(pinned: Value(pinned)));

  /// 지금 캐시에 있는 리액션. 낙관적 토글이 실패했을 때 되돌릴 값이다.
  Future<List<MessageReaction>> reactionsOf(String messageId) async {
    final row = await (select(cachedMessages)
          ..where((m) => m.id.equals(messageId)))
        .getSingleOrNull();
    return row?.reactions ?? const [];
  }

  Future<void> setReactions(String messageId, List<MessageReaction> reactions) =>
      (update(cachedMessages)..where((m) => m.id.equals(messageId)))
          .write(CachedMessagesCompanion(reactions: Value(reactions)));

  /// 서버가 소프트 삭제한 메시지. 행은 남기고 본문만 비운다 — 서버와 같은 규칙이다.
  Future<void> markMessageDeleted(String id, DateTime at) =>
      (update(cachedMessages)..where((m) => m.id.equals(id))).write(
        CachedMessagesCompanion(body: const Value(''), deletedAt: Value(at)),
      );

  /// 채널의 서버 메시지를 통째로 교체한다(catch-up).
  ///
  /// 전송 큐는 다른 테이블이라 **자동으로 살아남는다.** 예전에는 이 테이블에
  /// 로컬 메시지가 섞여 있어 지울 대상을 골라내야 했다.
  ///
  /// **최상위만 지운다.** 답글은 이 응답에 들어 있지 않으므로(서버가 타임라인을
  /// `parent_id IS NULL` 로 자른다) 함께 지우면 열어 둔 스레드가 빈다.
  Future<void> replaceServerMessages(
    String spaceId,
    String channelId,
    List<Message> messages,
  ) async {
    await transaction(() async {
      await (delete(cachedMessages)
            ..where((m) => m.channelId.equals(channelId) & m.parentId.isNull()))
          .go();
      await upsertMessages(spaceId, messages);
    });
  }

  /// 한 스레드의 답글을 통째로 교체한다. 부모 행은 건드리지 않는다.
  Future<void> replaceThreadReplies(
    String spaceId,
    String parentId,
    List<Message> replies,
  ) async {
    await transaction(() async {
      await (delete(cachedMessages)..where((m) => m.parentId.equals(parentId)))
          .go();
      await upsertMessages(spaceId, replies);
    });
  }

  // ──────────────────────────────────────────────
  // 전송 큐
  // ──────────────────────────────────────────────

  /// 큐 전체를 **넣은 순서대로**. 재연결 시 이 순서로 흘려보낸다.
  Future<List<OutboxMessage>> queuedMessages() =>
      (select(outboxMessages)..orderBy([(o) => OrderingTerm.asc(o.seq)])).get();

  /// 큐에 넣는다. 순번은 **여기서만** 매긴다.
  ///
  /// `MAX(seq) + 1` 을 읽고 쓰는 사이에 다른 삽입이 끼면 번호가 겹치므로
  /// 한 트랜잭션으로 묶는다.
  Future<void> enqueue(OutboxMessagesCompanion entry) async {
    await transaction(() async {
      final row = await customSelect(
        'SELECT COALESCE(MAX(seq), 0) AS next FROM outbox_messages',
        readsFrom: {outboxMessages},
      ).getSingle();
      await into(outboxMessages).insert(
        entry.copyWith(seq: Value(row.read<int>('next') + 1)),
      );
    });
  }

  /// 전송 성공. **큐에서 빼는 것과 캐시에 넣는 것은 한 트랜잭션이어야 한다** —
  /// 사이에서 끊기면 메시지가 화면에서 사라지거나 두 번 보인다.
  Future<void> settleQueued(String localId, String spaceId, Message sent) async {
    await transaction(() async {
      await (delete(outboxMessages)..where((o) => o.id.equals(localId))).go();
      await upsertMessages(spaceId, [sent]);
    });
  }

  Future<void> removeQueued(String id) =>
      (delete(outboxMessages)..where((o) => o.id.equals(id))).go();

  Future<void> recordAttempt(
    String id, {
    required int attempts,
    required bool failed,
    String? lastFailure,
  }) =>
      (update(outboxMessages)..where((o) => o.id.equals(id))).write(
        OutboxMessagesCompanion(
          attempts: Value(attempts),
          failed: Value(failed),
          lastFailure: Value(lastFailure),
        ),
      );

  /// 사용자가 재시도를 눌렀다. 시도 기록을 지우고 다시 대기 상태로 만든다.
  Future<void> requeue(String id) =>
      (update(outboxMessages)..where((o) => o.id.equals(id))).write(
        const OutboxMessagesCompanion(
          attempts: Value(0),
          failed: Value(false),
          lastFailure: Value(null),
        ),
      );

  // ──────────────────────────────────────────────
  // 채널
  // ──────────────────────────────────────────────

  Stream<List<CachedChannel>> watchChannels(String spaceId) =>
      (select(cachedChannels)
            ..where((c) => c.spaceId.equals(spaceId))
            ..orderBy([
              (c) => OrderingTerm.asc(c.position),
              (c) => OrderingTerm.asc(c.name),
            ]))
          .watch();

  /// 스페이스의 채널 목록을 통째로 교체한다.
  ///
  /// 병합이 아니라 교체인 이유: **볼 수 없게 된 채널은 사라져야 한다.**
  /// 권한이 회수됐는데 캐시에 남아 있으면 클릭했을 때 404 가 난다.
  Future<void> replaceChannels(
    String spaceId,
    List<CachedChannelsCompanion> channels,
  ) async {
    await transaction(() async {
      await (delete(cachedChannels)..where((c) => c.spaceId.equals(spaceId))).go();
      await batch((b) => b.insertAll(cachedChannels, channels));
    });
  }

  Future<void> setUnread(String channelId, int count) =>
      (update(cachedChannels)..where((c) => c.id.equals(channelId)))
          .write(CachedChannelsCompanion(unreadCount: Value(count)));

  // ──────────────────────────────────────────────
  // 카테고리
  // ──────────────────────────────────────────────

  Stream<List<CachedCategory>> watchCategories(String spaceId) =>
      (select(cachedCategories)
            ..where((c) => c.spaceId.equals(spaceId))
            ..orderBy([
              (c) => OrderingTerm.asc(c.position),
              (c) => OrderingTerm.asc(c.name),
            ]))
          .watch();

  /// 채널과 같은 이유로 병합이 아니라 교체다 — 지워진 카테고리가 남으면
  /// 빈 그룹이 화면에 계속 뜬다.
  Future<void> replaceCategories(
    String spaceId,
    List<CachedCategoriesCompanion> categories,
  ) async {
    await transaction(() async {
      await (delete(cachedCategories)..where((c) => c.spaceId.equals(spaceId)))
          .go();
      await batch((b) => b.insertAll(cachedCategories, categories));
    });
  }

  // ──────────────────────────────────────────────
  // 스페이스
  // ──────────────────────────────────────────────

  Stream<List<CachedSpace>> watchSpaces() =>
      (select(cachedSpaces)..orderBy([(s) => OrderingTerm.asc(s.name)])).watch();

  Future<void> replaceSpaces(List<CachedSpacesCompanion> spaces) async {
    await transaction(() async {
      await delete(cachedSpaces).go();
      await batch((b) => b.insertAll(cachedSpaces, spaces));
    });
  }

  /// 로그아웃 시. 다른 계정의 대화가 남아 있으면 안 된다.
  ///
  /// **큐도 함께 비운다.** 마이그레이션과 달리 여기서는 지우는 것이 맞다 —
  /// 남겨 두면 다음에 로그인한 사람의 이름으로 나갈 수 있다.
  Future<void> clearAll() async {
    await transaction(() async {
      await delete(cachedMessages).go();
      await delete(cachedChannels).go();
      await delete(cachedCategories).go();
      await delete(cachedSpaces).go();
      await delete(outboxMessages).go();
    });
  }
}

/// 캐시와 큐를 합친 UNION 결과 한 줄 → 화면 모델.
///
/// `queued` · `failed` 는 큐에서만 1 이 된다. 컬럼 이름을 직접 읽으므로
/// `watchChannelMessages` 의 SELECT 목록과 짝이 맞아야 한다.
Message _rowToMessage(QueryRow row) {
  final queued = row.read<int>('queued') == 1;
  final failed = row.read<int>('failed') == 1;

  // 시각 컬럼은 정수(UTC 마이크로초)다 — customSelect 는 컨버터를 지나지 않아
  // 여기서 직접 되돌린다.
  const micros = _UtcMicros();
  DateTime? at(String column) {
    final value = row.readNullable<int>(column);
    return value == null ? null : micros.fromSql(value);
  }

  return Message(
    id: row.read<String>('id'),
    channelId: row.read<String>('channel_id'),
    body: row.read<String>('body'),
    createdAt: at('created_at')!,
    editedAt: at('edited_at'),
    deletedAt: at('deleted_at'),
    author: MessageAuthor(
      id: row.read<String>('author_id'),
      name: row.read<String>('author_name'),
      avatarUrl: row.readNullable<String>('author_avatar_url'),
    ),
    reactions: const _ReactionsJson().fromSql(row.read<String>('reactions')),
    parentId: row.readNullable<String>('parent_id'),
    replyCount: row.read<int>('reply_count'),
    lastReplyAt: at('last_reply_at'),
    quoted: const _QuotedJson().fromSql(row.read<String>('quoted')),
    mentions: const _MentionsJson().fromSql(row.read<String>('mentions')),
    attachments:
        const _AttachmentsJson().fromSql(row.read<String>('attachments')),
    pinned: row.read<int>('pinned') == 1,
    // 큐에 있으면서 아직 포기하지 않은 것이 '보내는 중'이다.
    pending: queued && !failed,
    failed: failed,
  );
}

CachedMessagesCompanion _toRow(String spaceId, Message message) =>
    CachedMessagesCompanion.insert(
      id: message.id,
      spaceId: spaceId,
      channelId: message.channelId,
      body: message.body,
      createdAt: message.createdAt,
      editedAt: Value(message.editedAt),
      deletedAt: Value(message.deletedAt),
      authorId: message.author.id,
      authorName: message.author.name,
      authorAvatarUrl: Value(message.author.avatarUrl),
      reactions: Value(message.reactions),
      parentId: Value(message.parentId),
      replyCount: Value(message.replyCount),
      lastReplyAt: Value(message.lastReplyAt),
      quoted: Value(message.quoted),
      mentions: Value(message.mentions),
      attachments: Value(message.attachments),
      pinned: Value(message.pinned),
    );
