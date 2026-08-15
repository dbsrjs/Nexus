import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/message.dart';

part 'app_database.g.dart';

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
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  TextColumn get authorId => text()();
  TextColumn get authorName => text()();
  TextColumn get authorAvatarUrl => text().nullable()();

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

  /// 사용자가 **쓴** 시각. 서버 도착 시각이 아니다. 큐는 이 순서로 나간다.
  DateTimeColumn get createdAt => dateTime()();

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

  /// **시각을 초가 아니라 밀리초까지 보존한다.**
  ///
  /// drift 의 기본값은 Unix **초**라 밀리초가 잘린다. 그래서 같은 초에 도착한
  /// 메시지 둘이 정렬에서 동률이 되고 순서가 불안정해진다 — 오프라인에 쌓아 둔
  /// 메시지를 한꺼번에 내보낼 때 실제로 뒤집혔다(서버 기록은 .192 · .397 로
  /// 멀쩡했는데 화면만 뒤집혔다).
  ///
  /// 텍스트(ISO-8601 UTC)로 저장하면 밀리초가 남고, 문자열 정렬 순서가 곧
  /// 시간 순서라 `ORDER BY` 도 그대로 쓸 수 있다.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  int get schemaVersion => 5;

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

          // 5 에서 시각 저장 형식을 정수(초) → 텍스트(ISO-8601)로 바꿨다.
          // 캐시는 방금 다시 만들었으니 상관없지만, **큐는 남겨 두므로**
          // 옛 형식으로 저장된 행을 직접 옮겨 준다. 이미 잘린 밀리초는
          // 되살릴 수 없어 .000 으로 둔다 — 큐의 순서는 밀리초가 아니라
          // 삽입 순서로 정하므로 영향이 없다.
          if (from < 5) {
            await customStatement(
              "UPDATE outbox_messages "
              "SET created_at = strftime('%Y-%m-%dT%H:%M:%S.000Z', created_at, 'unixepoch') "
              "WHERE typeof(created_at) = 'integer'",
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
    return customSelect(
      '''
      SELECT id, channel_id, body, created_at, edited_at, deleted_at,
             author_id, author_name, author_avatar_url, 0 AS queued, 0 AS failed
        FROM cached_messages
       WHERE channel_id = ?1
      UNION ALL
      SELECT id, channel_id, body, created_at, NULL, NULL,
             author_id, author_name, author_avatar_url, 1 AS queued, failed
        FROM outbox_messages
       WHERE channel_id = ?1
       ORDER BY created_at DESC, id DESC
       LIMIT ?2
      ''',
      variables: [Variable<String>(channelId), Variable<int>(limit)],
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

  /// 서버가 소프트 삭제한 메시지. 행은 남기고 본문만 비운다 — 서버와 같은 규칙이다.
  Future<void> markMessageDeleted(String id, DateTime at) =>
      (update(cachedMessages)..where((m) => m.id.equals(id))).write(
        CachedMessagesCompanion(body: const Value(''), deletedAt: Value(at)),
      );

  /// 채널의 서버 메시지를 통째로 교체한다(catch-up).
  ///
  /// 전송 큐는 다른 테이블이라 **자동으로 살아남는다.** 예전에는 이 테이블에
  /// 로컬 메시지가 섞여 있어 지울 대상을 골라내야 했다.
  Future<void> replaceServerMessages(
    String spaceId,
    String channelId,
    List<Message> messages,
  ) async {
    await transaction(() async {
      await (delete(cachedMessages)..where((m) => m.channelId.equals(channelId)))
          .go();
      await upsertMessages(spaceId, messages);
    });
  }

  // ──────────────────────────────────────────────
  // 전송 큐
  // ──────────────────────────────────────────────

  /// 큐 전체를 **쓴 순서대로**. 재연결 시 이 순서로 흘려보낸다.
  ///
  /// id 로 한 번 더 정렬하는 이유는 같은 시각에 두 개가 들어왔을 때 순서가
  /// 흔들리지 않게 하기 위해서다. 로컬 id 는 `local-<마이크로초>-<난수>` 라
  /// 문자열 정렬이 곧 작성 순서다.
  Future<List<OutboxMessage>> queuedMessages() => (select(outboxMessages)
        ..orderBy([
          (o) => OrderingTerm.asc(o.createdAt),
          (o) => OrderingTerm.asc(o.id),
        ]))
      .get();

  Future<void> enqueue(OutboxMessagesCompanion entry) =>
      into(outboxMessages).insert(entry);

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

  return Message(
    id: row.read<String>('id'),
    channelId: row.read<String>('channel_id'),
    body: row.read<String>('body'),
    createdAt: row.read<DateTime>('created_at'),
    editedAt: row.readNullable<DateTime>('edited_at'),
    deletedAt: row.readNullable<DateTime>('deleted_at'),
    author: MessageAuthor(
      id: row.read<String>('author_id'),
      name: row.read<String>('author_name'),
      avatarUrl: row.readNullable<String>('author_avatar_url'),
    ),
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
    );
