/// AI 패널이 서버에 묻는 것 (13-2 설계 §1 · §6).
///
/// **프롬프트는 여기 없다.** 앱은 지시문 · 프리셋 이름 · 컨텍스트만 보내고
/// 프롬프트는 서버가 조립한다(설계 D2).
library;

/// 패널에 붙은 근거 하나. 화면에서는 칩 하나다.
sealed class AiContext {
  const AiContext();

  /// 칩에 쓰는 이름.
  String get label;
}

/// 채널에서 고른 메시지들.
class MessagesContext extends AiContext {
  const MessagesContext({required this.channelId, required this.messageIds});

  final String channelId;

  /// **시간순**(오래된 것 먼저)으로 넣는다. 서버는 어느 순서든 시간순으로
  /// 읽지만, 이슈 초안의 원문 링크(`firstMessageId`)가 첫 항목을 쓴다 —
  /// 클릭한 순서면 대화의 끝 쪽 메시지가 원문이 된다.
  final List<String> messageIds;

  @override
  String get label => '메시지 ${messageIds.length}개';
}

/// 채널의 최근 대화. 서버가 최근 최상위 메시지 50개를 고른다.
class ChannelContext extends AiContext {
  const ChannelContext({required this.channelId, required this.channelName});

  final String channelId;
  final String channelName;

  @override
  String get label => '#$channelName 최근 대화';
}

/// 저장소 코드. 서버가 지시문으로 검색해 청크를 고른다.
class RepoContext extends AiContext {
  const RepoContext({required this.repoId, required this.repoName});

  final String repoId;
  final String repoName;

  @override
  String get label => repoName;
}

/// 한 대화에서 이어 물을 수 있는 문답 수 — 서버 `MAX_THREAD_TURNS` 와 같다
/// (13-3 설계 D5). 첫 문답을 포함한다.
const maxThreadTurns = 10;

/// 서버의 프롬프트 템플릿 이름. **대화가 있어야 한다**(설계 §1).
enum AiPreset {
  summary('summary'),
  issue('issue');

  const AiPreset(this.wire);
  final String wire;
}

/// 칩 목록에 대한 판정. **패널과 요청이 같은 판정을 쓴다** — 둘이 따로
/// 구현하면 컨텍스트 종류가 늘 때 한쪽만 고쳐져 프리셋 활성화와 실제 요청이
/// 어긋난다.
extension AiContexts on List<AiContext> {
  bool get hasConversation =>
      any((c) => c is MessagesContext || c is ChannelContext);

  bool get hasRepo => any((c) => c is RepoContext);

  String? get repoId {
    for (final c in this) {
      if (c is RepoContext) return c.repoId;
    }
    return null;
  }

  /// 이슈 초안에서 원문으로 돌아가는 링크(9-2b)에 쓴다. 고른 메시지가 없으면 null.
  String? get firstMessageId {
    for (final c in this) {
      if (c is MessagesContext && c.messageIds.isNotEmpty) {
        return c.messageIds.first;
      }
    }
    return null;
  }
}

class AiRequest {
  const AiRequest({this.instruction, this.preset, required this.contexts})
    : parentRunId = null,
      assert((instruction == null) != (preset == null), '지시문과 프리셋 중 하나만');

  /// 이어 묻기 (13-3). 근거는 서버가 사슬의 첫 문답에서 물려받는다 —
  /// `contexts` 는 화면(칩 · 실패 문구 · 인용 링크 · 이슈 원문)을 위해서만
  /// 들고 다니고 보내지 않는다(설계 D2).
  const AiRequest.followUp({
    required String this.instruction,
    required String this.parentRunId,
    required this.contexts,
  }) : preset = null;

  final String? instruction;
  final AiPreset? preset;
  final List<AiContext> contexts;

  /// 이어 물은 앞 문답. 첫 질문이면 null.
  final String? parentRunId;

  bool get hasConversation => contexts.hasConversation;
  bool get hasRepo => contexts.hasRepo;
  String? get repoId => contexts.repoId;
  String? get firstMessageId => contexts.firstMessageId;

  /// `POST /ai/ask` 본문. 대화 컨텍스트는 하나만 붙는다 — 패널이 둘을
  /// 동시에 만들지 않는다(고른 메시지 · 채널 최근 대화 중 하나로 열린다).
  Map<String, dynamic> toJson() {
    if (parentRunId != null) {
      return {'instruction': instruction, 'parentRunId': parentRunId};
    }
    final context = <String, dynamic>{};
    for (final c in contexts) {
      switch (c) {
        case MessagesContext():
          context['channelId'] = c.channelId;
          context['messageIds'] = c.messageIds;
        case ChannelContext():
          context['channelId'] = c.channelId;
        case RepoContext():
          context['repoId'] = c.repoId;
      }
    }
    return {
      if (instruction != null) 'instruction': instruction,
      if (preset != null) 'preset': preset!.wire,
      'context': context,
    };
  }
}
