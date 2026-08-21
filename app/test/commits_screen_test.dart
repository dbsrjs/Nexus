import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/repo_browse.dart';
import 'package:nexus_app/features/repo/commit_detail_screen.dart';
import 'package:nexus_app/features/repo/commits_screen.dart';

void main() {
  testWidgets('커밋 목록이 제목과 짧은 sha 를 보여 준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommitList(
            commits: const [
              CommitSummary(
                sha: 'abc123def456',
                message: 'fix: 고친다\n\n본문',
                authorName: 'dbsrjs',
                changedCount: 2,
              ),
            ],
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('fix: 고친다'), findsOneWidget);
    expect(find.textContaining('abc123d'), findsOneWidget);
    // 본문은 목록에 나오지 않는다 — 목록이 문단이 되면 안 된다.
    expect(find.textContaining('본문'), findsNothing);
  });

  testWidgets('changedCount 를 모르면 파일 수를 말하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommitList(
            commits: const [CommitSummary(sha: 'a1b2c3d', message: 'chore: x')],
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 0 으로 그리면 "안 바뀐 커밋"으로 읽힌다.
    expect(find.textContaining('파일'), findsNothing);
  });

  testWidgets('변경 파일이 상태와 함께 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangedFileList(
            files: const [
              ChangedFile(path: 'a.ts', status: 'added'),
              ChangedFile(path: 'b.ts', status: 'removed'),
            ],
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('a.ts'), findsOneWidget);
    expect(find.text('추가'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
  });
}
