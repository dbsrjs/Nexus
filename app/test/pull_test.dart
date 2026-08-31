import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/pull.dart';

void main() {
  test('머지된 PR 은 merged 로 읽힌다', () {
    final pull = PullSummary.fromJson({
      'number': 12,
      'title': 't',
      'state': 'merged',
      'mergedAt': '2026-08-02T00:00:00Z',
    });
    expect(pull.state, PullState.merged);
  });

  test('리뷰가 없으면 null 이다 — pending 이 아니다', () {
    final detail = PullDetail.fromJson({
      'number': 12,
      'title': 't',
      'state': 'open',
      'review': null,
    });
    expect(detail.review, isNull);
  });

  test('changes_requested 를 읽는다', () {
    final detail = PullDetail.fromJson({
      'number': 12,
      'title': 't',
      'state': 'open',
      'review': 'changes_requested',
    });
    expect(detail.review, PullReviewState.changesRequested);
  });

  test('변경량은 모르면 null 이다 — 0 이 아니다', () {
    final detail = PullDetail.fromJson({
      'number': 12,
      'title': 't',
      'state': 'open',
    });
    expect(detail.additions, isNull);
  });

  test('renamed 는 이전 경로를 갖는다', () {
    final file = PullChangedFile.fromJson({
      'path': 'new.ts',
      'status': 'renamed',
      'previousPath': 'old.ts',
    });
    expect(file.previousPath, 'old.ts');
  });
}
