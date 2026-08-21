import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/repo_browse.dart';

void main() {
  test('커밋 요약을 읽는다', () {
    final c = CommitSummary.fromJson(const {
      'sha': 'abc123def456',
      'message': 'fix: 고친다\n\n본문',
      'authorName': 'dbsrjs',
      'committedAt': '2026-08-21T00:00:00.000Z',
      'changedCount': 2,
    });

    expect(c.sha, 'abc123def456');
    expect(c.changedCount, 2);
  });

  test('짧은 sha 는 앞 7자다', () {
    const c = CommitSummary(sha: 'abc123def456', message: 'x');

    expect(c.shortSha, 'abc123d');
  });

  test('제목은 첫 줄이다 — 목록이 문단이 되면 안 된다', () {
    const c = CommitSummary(sha: 'a', message: 'fix: 고친다\n\n본문이 길다');

    expect(c.title, 'fix: 고친다');
  });

  test('changedCount 가 없으면 null 이다 — 0 과 다르다', () {
    // 브랜치 이력은 파일 수를 모른다. 0 으로 두면 "안 바뀐 커밋"으로 읽힌다.
    const c = CommitSummary(sha: 'a', message: 'x');

    expect(c.changedCount, isNull);
  });

  test('변경 파일의 status 세 값이 서로 다른 문구가 된다', () {
    const added = ChangedFile(path: 'a.ts', status: 'added');
    const removed = ChangedFile(path: 'b.ts', status: 'removed');
    const modified = ChangedFile(path: 'c.ts', status: 'modified');

    final labels = {added.statusLabel, removed.statusLabel, modified.statusLabel};
    expect(labels.length, 3);
  });

  test('커밋 상세는 제목과 본문을 나눈다', () {
    const d = CommitDetail(sha: 'a', message: 'fix: 고친다\n\n왜 고쳤는지');

    expect(d.title, 'fix: 고친다');
    expect(d.bodyText, '왜 고쳤는지');
  });

  test('본문이 없으면 빈 문자열이다', () {
    const d = CommitDetail(sha: 'a', message: 'fix: 고친다');

    expect(d.bodyText, isEmpty);
  });
}
