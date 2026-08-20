import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/domain/models/issue.dart';

/// 인메모리 drift 로 실제 DB 동작까지 덮는다. 화면은 여기만 구독하므로
/// 캐시가 틀리면 보드가 통째로 틀린다.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Issue issue(
    String id, {
    IssueStatus status = IssueStatus.backlog,
    String position = '0',
  }) => Issue(
    id: id,
    key: 'NEXUS-$id',
    title: '이슈 $id',
    status: status,
    priority: IssuePriority.mid,
    position: position,
    createdAt: DateTime.utc(2026, 8, 20),
    updatedAt: DateTime.utc(2026, 8, 20),
  );

  test('캐시에 넣은 이슈를 position 순으로 돌려준다', () async {
    await db.replaceIssues('s1', [
      issue('b', position: '2000'),
      issue('a', position: '1000'),
    ]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.map((r) => r.id), ['a', 'b']);
  });

  test('음수 position 이 맨 앞에 온다 — 문자열로 정렬하면 뒤집힌다', () async {
    // 서버는 맨 위로 올릴 때 음수를 준다. '-1000' < '1000' 은 사전순으로도
    // 참이지만 '-1000' < '500' 은 거짓이라, 문자열 정렬은 여기서 깨진다.
    await db.replaceIssues('s1', [
      issue('a', position: '500'),
      issue('b', position: '-1000'),
    ]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.map((r) => r.id), ['b', 'a']);
  });

  test('컬럼 순서가 backlog · doing · review · done 이다', () async {
    await db.replaceIssues('s1', [
      issue('d', status: IssueStatus.done),
      issue('a', status: IssueStatus.backlog),
      issue('r', status: IssueStatus.review),
      issue('g', status: IssueStatus.doing),
    ]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.map((r) => r.id), ['a', 'g', 'r', 'd']);
  });

  test('다른 스페이스의 이슈는 섞이지 않는다', () async {
    await db.replaceIssues('s1', [issue('a')]);
    await db.replaceIssues('s2', [issue('b')]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.map((r) => r.id), ['a']);
  });

  test('갱신은 같은 id 를 덮어쓴다 — 소켓과 REST 가 겹쳐도 중복되지 않는다', () async {
    await db.replaceIssues('s1', [issue('a')]);
    await db.upsertIssue('s1', issue('a', status: IssueStatus.doing));

    final rows = await db.watchIssues('s1').first;

    expect(rows.length, 1);
    expect(rows.single.status, IssueStatus.doing.name);
  });

  test('replaceIssues 는 사라진 이슈를 지운다', () async {
    // 남겨 두면 다른 곳에서 지운 이슈가 이 기기에만 영원히 남는다.
    await db.replaceIssues('s1', [issue('a'), issue('b')]);
    await db.replaceIssues('s1', [issue('a')]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.map((r) => r.id), ['a']);
  });

  test('라벨이 캐시를 왕복한다 — JSON 한 칸에 접어 둔다', () async {
    await db.replaceIssues('s1', [
      issue('a').copyWith(
        labels: const [
          IssueLabel(id: 'l1', name: '버그', color: '#d47d7d'),
          IssueLabel(id: 'l2', name: '잡일', color: '#74b48f'),
        ],
      ),
    ]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.single.labels.map((l) => l.name), ['버그', '잡일']);
    expect(rows.single.labels.first.color, '#d47d7d');
  });

  test('라벨이 없으면 빈 목록이다 — null 이 아니다', () async {
    await db.replaceIssues('s1', [issue('a')]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.single.labels, isEmpty);
  });

  test('대화 → 이슈의 원문 요약이 캐시를 왕복한다', () async {
    await db.replaceIssues('s1', [
      issue('a').copyWith(
        originMessage: const IssueOrigin(
          id: 'm1',
          channelId: 'c1',
          body: '이 논의로 이슈를 만든다',
          authorName: '나',
        ),
      ),
    ]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.single.originMessage?.channelId, 'c1');
    expect(rows.single.originMessage?.deleted, isFalse);
  });

  test('지워진 원문은 본문 없이 링크만 남는다', () async {
    await db.replaceIssues('s1', [
      issue('a').copyWith(
        originMessage: const IssueOrigin(
          id: 'm1',
          channelId: 'c1',
          authorName: '나',
          deleted: true,
        ),
      ),
    ]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.single.originMessage?.id, 'm1');
    expect(rows.single.originMessage?.body, isNull);
    expect(rows.single.originMessage?.deleted, isTrue);
  });

  test('보드에서 만든 이슈는 원문이 없다', () async {
    await db.replaceIssues('s1', [issue('a')]);

    final rows = await db.watchIssues('s1').first;

    expect(rows.single.originMessage, isNull);
  });

  test('deleteIssue 는 그 이슈만 지운다', () async {
    await db.replaceIssues('s1', [issue('a'), issue('b')]);
    await db.deleteIssue('a');

    final rows = await db.watchIssues('s1').first;

    expect(rows.map((r) => r.id), ['b']);
  });
}
