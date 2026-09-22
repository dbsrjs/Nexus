import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/ai/ai_request.dart';

void main() {
  group('AiRequest.toJson', () {
    test('고른 메시지 + 저장소 + 지시문', () {
      const req = AiRequest(
        instruction: '세 줄로',
        contexts: [
          MessagesContext(channelId: 'c1', messageIds: ['m1', 'm2']),
          RepoContext(repoId: 'r1', repoName: 'nexus'),
        ],
      );
      expect(req.toJson(), {
        'instruction': '세 줄로',
        'context': {
          'channelId': 'c1',
          'messageIds': ['m1', 'm2'],
          'repoId': 'r1',
        },
      });
      expect(req.hasConversation, isTrue);
      expect(req.hasRepo, isTrue);
      expect(req.firstMessageId, 'm1');
    });

    test('채널 최근 대화 + 프리셋 — messageIds 를 보내지 않는다', () {
      const req = AiRequest(
        preset: AiPreset.issue,
        contexts: [ChannelContext(channelId: 'c1', channelName: 'dev')],
      );
      expect(req.toJson(), {
        'preset': 'issue',
        'context': {'channelId': 'c1'},
      });
      expect(req.firstMessageId, isNull);
    });

    test('저장소만이면 대화가 없다 — 프리셋을 막는 근거다', () {
      const req = AiRequest(
        instruction: 'q',
        contexts: [RepoContext(repoId: 'r1', repoName: 'nexus')],
      );
      expect(req.hasConversation, isFalse);
    });

    test('칩 이름', () {
      expect(const MessagesContext(channelId: 'c', messageIds: ['a', 'b']).label, '메시지 2개');
      expect(const ChannelContext(channelId: 'c', channelName: 'dev').label, '#dev 최근 대화');
    });
  });
}
