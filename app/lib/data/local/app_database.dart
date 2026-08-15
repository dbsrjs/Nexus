import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/message.dart';

part 'app_database.g.dart';

/// 메시지의 전송 상태. **로컬에만 있는 개념**이라 서버 모델에는 없다.
enum SendState {
  /// 서버에 저장된 메시지.
  synced,

  /// 보내는 중(낙관적 삽입). 앱을 껐다 켜도 남아 있어야 재시도할 수 있다.
  pending,

  /// 전송 실패. 사용자가 재시도하거나 버릴 때까지 남는다.
  failed,
}

/// 메시지 캐시.
///
/// 서버 모델을 그대로 펼쳐 담는다. 중첩(author)을 JSON 으로 넣지 않는 이유는,
/// 목록 정렬·필터가 전부 SQL 에서 일어나야 하기 때문이다.
class CachedMessages extends Table {
  /// 서버 id, 또는 아직 보내지 못한 메시지의 로컬 id(`local-…`).
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

  IntColumn get sendState => intEnum<SendState>().withDefault(const Constant(0))();

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
  tables: [CachedMessages, CachedChannels, CachedCategories, CachedSpaces],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'nexus'));

  @override
  int get schemaVersion => 3;

  /// **캐시는 서버에서 다시 받을 수 있다.** 그래서 스키마가 바뀌면 데이터를
  /// 옮기지 않고 통째로 다시 만든다 — 마이그레이션을 한 단계씩 쓰는 값이
  /// 이 데이터에는 없다.
  ///
  /// 이 전략이 없어서 실제로 한 번 깨졌다: 테이블을 추가하고 버전을 올리지
  /// 않으니 기존 파일에 그 테이블이 없어 `no such table` 로 앱이 멈췄다.
  ///
  /// **아직 보내지 못한 메시지는 함께 사라진다.** 지금은 캐시가 하루 이틀치라
  /// 감수하지만, 전송 큐(6-2)가 들어오면 그때는 옮기는 편이 낫다.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await m.createAll();
        },
      );

  // ──────────────────────────────────────────────
  // 메시지
  // ──────────────────────────────────────────────

  /// 채널의 메시지를 **최신순**으로 구독한다.
  ///
  /// UI 는 이 스트림만 본다. REST 응답도 소켓 이벤트도 여기 쓰기만 하면
  /// 화면에 반영된다 — 두 입력원이 같은 코드 경로를 탄다
  /// (docs/앱-설계.md §6).
  Stream<List<Message>> watchChannelMessages(String channelId, {int limit = 100}) {
    final query = (select(cachedMessages)
      ..where((m) => m.channelId.equals(channelId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
      ..limit(limit));

    return query.watch().map((rows) => rows.map(_toMessage).toList(growable: false));
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
  /// **아직 보내지 못한 로컬 메시지는 지우지 않는다.** 그것까지 지우면 오프라인에
  /// 쌓아 둔 전송분이 사라진다.
  Future<void> replaceServerMessages(
    String spaceId,
    String channelId,
    List<Message> messages,
  ) async {
    await transaction(() async {
      await (delete(cachedMessages)
            ..where((m) =>
                m.channelId.equals(channelId) &
                m.sendState.equalsValue(SendState.synced)))
          .go();
      await upsertMessages(spaceId, messages);
    });
  }

  /// 전송 대기·실패 상태로 남아 있는 메시지. 6-2 의 전송 큐가 읽는다.
  Future<List<Message>> pendingMessages(String channelId) async {
    final rows = await (select(cachedMessages)
          ..where((m) =>
              m.channelId.equals(channelId) &
              m.sendState.equalsValue(SendState.synced).not())
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
    return rows.map(_toMessage).toList(growable: false);
  }

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
  Future<void> clearAll() async {
    await transaction(() async {
      await delete(cachedMessages).go();
      await delete(cachedChannels).go();
      await delete(cachedCategories).go();
      await delete(cachedSpaces).go();
    });
  }
}

Message _toMessage(CachedMessage row) => Message(
      id: row.id,
      channelId: row.channelId,
      body: row.body,
      createdAt: row.createdAt,
      editedAt: row.editedAt,
      deletedAt: row.deletedAt,
      author: MessageAuthor(
        id: row.authorId,
        name: row.authorName,
        avatarUrl: row.authorAvatarUrl,
      ),
      pending: row.sendState == SendState.pending,
      failed: row.sendState == SendState.failed,
    );

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
      sendState: Value(
        message.failed
            ? SendState.failed
            : message.pending
                ? SendState.pending
                : SendState.synced,
      ),
    );
