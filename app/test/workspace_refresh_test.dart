import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/channels_api.dart';
import 'package:nexus_app/data/api/spaces_api.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/data/repositories/workspace_repository.dart';

import 'support/fake_http.dart';

/// 스페이스 · 채널 · 카테고리 새로고침(workspace_repository.dart).
///
/// 앱 규칙 둘을 본다 — **`refresh*` 는 실패를 던지지 않고 `false`**, 그리고 **실패가
/// 캐시를 빈 값으로 덮어쓰지 않는다.** 오프라인은 오류가 아니라 정상 경로라, 덮어쓰면
/// 서버가 꺼진 순간 스페이스 선택 화면부터 비어 캐시된 대화에 닿을 길이 없다.
/// 카테고리만 REST 로 남겼다가 오프라인 뒤 «기타»에 묶여 실제로 겪었다(CLAUDE.md §3).
///
/// 가짜 서버는 HTTP 층에 끼운다 — `guardApi` 가 Dio 실패를 바꾸는 것까지 실제 경로로 탄다.
void main() {
  late AppDatabase db;
  var online = true;
  var spaces = <Map<String, Object?>>[];
  var channels = <Map<String, Object?>>[];
  var categories = <Map<String, Object?>>[];

  late WorkspaceRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    online = true;
    spaces = [
      {'id': 's1', 'slug': 'one', 'name': '하나', 'role': 'member'},
    ];
    channels = [
      {'id': 'c1', 'key': 'general', 'name': '일반'},
      {'id': 'c2', 'key': 'secret', 'name': '비밀', 'isPrivate': true},
    ];
    categories = [
      {'id': 'k1', 'name': '팀'},
    ];

    final http = FakeHttpAdapter((r) async {
      if (!online) return (status: 503, body: null);
      return switch (r.path) {
        '/spaces' => (status: 200, body: spaces),
        '/spaces/s1/channels' => (status: 200, body: channels),
        '/spaces/s1/categories' => (status: 200, body: categories),
        _ => (status: 404, body: null),
      };
    });
    final client = await fakeApiClient(http);
    repo = WorkspaceRepository(
      spacesApi: SpacesApi(client),
      channelsApi: ChannelsApi(client),
      db: db,
    );
  });
  tearDown(() => db.close());

  Future<void> refreshAll() async {
    expect(await repo.refreshSpaces(), isTrue);
    expect(await repo.refreshChannels('s1'), isTrue);
    expect(await repo.refreshCategories('s1'), isTrue);
  }

  test('새로고침이 캐시를 채운다', () async {
    await refreshAll();

    expect((await repo.watchSpaces().first).map((s) => s.name), ['하나']);
    expect(
      (await repo.watchChannels('s1').first).map((c) => c.id),
      unorderedEquals(['c1', 'c2']),
    );
    expect((await repo.watchCategories('s1').first).map((c) => c.name), ['팀']);
  });

  test('★ 서버에 못 닿으면 던지지 않고 false 이고, 캐시는 그대로 남는다', () async {
    await refreshAll();
    online = false;

    expect(await repo.refreshSpaces(), isFalse);
    expect(await repo.refreshChannels('s1'), isFalse);
    expect(await repo.refreshCategories('s1'), isFalse);

    expect(await repo.watchSpaces().first, hasLength(1));
    expect(await repo.watchChannels('s1').first, hasLength(2));
    expect(await repo.watchCategories('s1').first, hasLength(1));
  });

  test('★ 채널은 병합이 아니라 교체다 - 권한이 회수된 채널이 남으면 눌렀을 때 404', () async {
    await refreshAll();
    channels = [channels.first];

    expect(await repo.refreshChannels('s1'), isTrue);
    expect((await repo.watchChannels('s1').first).map((c) => c.id), ['c1']);
  });

  test('나간 스페이스는 목록에서 빠진다', () async {
    await refreshAll();
    spaces = [];

    expect(await repo.refreshSpaces(), isTrue);
    expect(await repo.watchSpaces().first, isEmpty);
  });
}
