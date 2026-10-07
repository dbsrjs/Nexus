import '../../features/ai/ai_request.dart';
import 'ai_run.dart';

// 지난 AI 대화(19). **freezed 를 쓰지 않는다** — 화면이 읽기만 하고 복사 · 비교할
// 일이 없다. `result` 모양은 `AiRun.fromJson` 이 이미 안다(서버가 사슬의 각 턴을
// `GET .../ai/runs/:runId` 와 같은 모양으로 준다).

/// 목록의 한 줄 — 사슬 하나(뿌리 문답 단위, 19 설계 D2).
class AiThreadSummary {
  const AiThreadSummary({
    required this.rootRunId,
    required this.kind,
    required this.question,
    required this.preset,
    required this.turnCount,
    required this.lastAt,
    required this.preview,
    this.channelId,
    this.messageCount,
    this.repoId,
  });

  final String rootRunId;
  final String kind;

  /// 뿌리의 지시문. 프리셋으로 시작한 대화면 null.
  final String? question;
  final AiPreset? preset;
  final int turnCount;

  /// 끝 문답이 끝난 시각(UTC). 목록이 이 순서다.
  final DateTime lastAt;

  /// 끝 답 원문(마크다운) 앞부분. 평문화는 화면이 한다.
  final String preview;

  /// 근거는 id 만 온다 — 이름은 화면이 이미 가진 목록에서 찾는다(설계 D10).
  final String? channelId;
  final int? messageCount;
  final String? repoId;

  String get title => question ?? aiPresetLabel(preset);

  factory AiThreadSummary.fromJson(Map<String, dynamic> json) {
    final context = json['context'] is Map ? json['context'] as Map : const {};
    return AiThreadSummary(
      rootRunId: json['rootRunId'] as String,
      kind: json['kind'] as String? ?? 'ask',
      question: json['question'] as String?,
      preset: aiPresetOf(json['preset'] as String?),
      turnCount: (json['turnCount'] as num).toInt(),
      lastAt: DateTime.parse(json['lastAt'] as String).toUtc(),
      preview: json['preview'] as String? ?? '',
      channelId: context['channelId'] as String?,
      messageCount: (context['messageCount'] as num?)?.toInt(),
      repoId: context['repoId'] as String?,
    );
  }
}

class AiThreadPage {
  const AiThreadPage({required this.items, required this.nextCursor});

  final List<AiThreadSummary> items;

  /// 다음 페이지를 부를 기준(뿌리 runId). 끝이면 null.
  final String? nextCursor;

  factory AiThreadPage.fromJson(Map<String, dynamic> json) => AiThreadPage(
    items: [
      for (final item in json['items'] as List? ?? const [])
        AiThreadSummary.fromJson(item as Map<String, dynamic>),
    ],
    nextCursor: json['nextCursor'] as String?,
  );
}

/// 다시 연 사슬의 문답 하나 — 화면 문구로 쓴 질문과 그 답.
class AiThreadTurn {
  const AiThreadTurn({required this.question, required this.run});

  final String question;
  final AiRun run;
}

/// 다시 연 사슬 — 뿌리부터 끝까지와, 칩을 되살릴 근거(설계 D11).
class AiThread {
  const AiThread({
    required this.rootRunId,
    required this.turns,
    this.channelId,
    this.messageIds,
    this.repoId,
  });

  final String rootRunId;
  final List<AiThreadTurn> turns;
  final String? channelId;
  final List<String>? messageIds;
  final String? repoId;

  factory AiThread.fromJson(Map<String, dynamic> json) {
    final context = json['context'] is Map ? json['context'] as Map : const {};
    final ids = context['messageIds'];
    return AiThread(
      rootRunId: json['rootRunId'] as String,
      channelId: context['channelId'] as String?,
      messageIds: ids is List ? [for (final id in ids) id as String] : null,
      repoId: context['repoId'] as String?,
      turns: [
        for (final raw in json['turns'] as List? ?? const [])
          if (raw is Map<String, dynamic>)
            AiThreadTurn(
              question:
                  raw['instruction'] as String? ??
                  aiPresetLabel(aiPresetOf(raw['preset'] as String?)),
              run: AiRun.fromJson(raw),
            ),
      ],
    );
  }
}
