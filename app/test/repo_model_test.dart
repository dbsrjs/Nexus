import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/repo.dart';

void main() {
  test('GithubRepo 를 서버 응답에서 읽는다', () {
    final repo = GithubRepo.fromJson(const {
      'id': 9001,
      'fullName': 'octocat/hello-world',
      'private': false,
      'defaultBranch': 'main',
      'pushedAt': '2026-08-20T00:00:00.000Z',
      'canWebhook': true,
    });

    expect(repo.id, 9001);
    expect(repo.fullName, 'octocat/hello-world');
    expect(repo.canWebhook, isTrue);
  });

  test('훅 id 가 없으면 웹훅이 안 걸린 것이다', () {
    const failed = SpaceRepo(
      id: 'r1',
      name: 'hello-world',
      fullPath: 'octocat/hello-world',
      linkedChannelId: null,
      webhookExternalId: null,
    );
    const ok = SpaceRepo(
      id: 'r2',
      name: 'hello-world',
      fullPath: 'octocat/hello-world',
      linkedChannelId: 'c1',
      webhookExternalId: '700',
    );

    // 화면이 "다시 걸기"를 띄우는 근거다.
    expect(failed.webhookActive, isFalse);
    expect(ok.webhookActive, isTrue);
  });
}
