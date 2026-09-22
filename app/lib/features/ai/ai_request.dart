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

  /// 고른 순서가 아니라 무엇을 골랐는지만 뜻한다 — 서버가 시간순으로 읽는다.
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

/// 서버의 프롬프트 템플릿 이름. **대화가 있어야 한다**(설계 §1).
enum AiPreset {
  summary('summary'),
  issue('issue');

  const AiPreset(this.wire);
  final String wire;
}

class AiRequest {
  const AiRequest({this.instruction, this.preset, required this.contexts})
    : assert((instruction == null) != (preset == null), '지시문과 프리셋 중 하나만');

  final String? instruction;
  final AiPreset? preset;
  final List<AiContext> contexts;

  bool get hasConversation =>
      contexts.any((c) => c is MessagesContext || c is ChannelContext);

  bool get hasRepo => contexts.any((c) => c is RepoContext);

  /// 이슈 초안에서 원문으로 돌아가는 링크(9-2b)에 쓴다. 고른 메시지가 없으면 null.
  String? get firstMessageId {
    for (final c in contexts) {
      if (c is MessagesContext && c.messageIds.isNotEmpty) {
        return c.messageIds.first;
      }
    }
    return null;
  }

  /// `POST /ai/ask` 본문. 대화 컨텍스트는 하나만 붙는다 — 패널이 둘을
  /// 동시에 만들지 않는다(고른 메시지 · 채널 최근 대화 중 하나로 열린다).
  Map<String, dynamic> toJson() {
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
