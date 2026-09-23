import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_run.freezed.dart';

// json_serializable 을 쓰지 않는다 — `result` 가 종류(kind)마다 모양이 달라
// 통째로 들지 않고 필요한 칸만 꺼내는데, 그 갈래는 손으로 쓰는 편이
// 짧다(space_member.dart 의 평평하게 펴는 선례와 같은 이유).

/// 서버 `AiRunState` 와 같은 넷이다.
enum AiRunState { queued, running, done, failed }

/// 답이 근거로 삼은 코드 한 조각. **서버가 검색 결과에서 채운다** — LLM 이
/// 지어낸 경로가 아니다(13-2 설계 §2). `n` 은 답 본문의 `[n]` 과 같은 번호다.
@freezed
abstract class AiCitation with _$AiCitation {
  const factory AiCitation({
    required int n,
    required String path,
    required int startLine,
    required int endLine,
    required String commitSha,
  }) = _AiCitation;

  const AiCitation._();

  /// 화면에 쓰는 `경로:시작-끝`.
  String get location => '$path:$startLine-$endLine';
}

/// AI 한 번의 실행.
///
/// 종류마다 결과가 다르다 — 요약 · 자유 질문은 `markdown`, 이슈 초안
/// (`draft_issue`)은 `title` · `description`. 인용은 셋 모두에 있다.
@freezed
abstract class AiRun with _$AiRun {
  const factory AiRun({
    required String runId,
    required String kind,
    required AiRunState state,

    /// 요약 · 자유 질문 본문. **완료 전에는 null 이다** — 빈 문자열로 지어내지
    /// 않는다(판단 #2: 모르는 값은 0 이 아니라 null).
    String? markdown,

    /// 이슈 초안의 제목 · 본문. 그 밖의 종류에서는 null 이다.
    String? title,
    String? description,
    @Default(<AiCitation>[]) List<AiCitation> citations,
    String? error,

    /// 주 모델 대신 **전환 모델**이 답했는지. 무료 한도(하루 20회)를 넘거나
    /// 주 모델이 붐비면 서버가 가벼운 모델로 답한다 — 화면이 한 줄로 알린다.
    @Default(false) bool fallback,
  }) = _AiRun;

  const AiRun._();

  bool get isIssueDraft => kind == 'draft_issue';

  factory AiRun.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final map = result is Map ? result : const {};
    final rawCites = map['citations'];
    return AiRun(
      runId: json['runId'] as String,
      kind: json['kind'] as String? ?? 'summarize',
      state: _stateOf(json['state'] as String?),
      markdown: map['markdown'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      citations: rawCites is List
          ? [
              for (final c in rawCites)
                if (c is Map)
                  AiCitation(
                    n: (c['n'] as num).toInt(),
                    path: c['path'] as String,
                    startLine: (c['startLine'] as num).toInt(),
                    endLine: (c['endLine'] as num).toInt(),
                    commitSha: c['commitSha'] as String,
                  ),
            ]
          : const [],
      error: json['error'] as String?,
      fallback: json['fallback'] == true,
    );
  }
}

/// **모르는 값은 queued 로 떨어진다.** 서버가 상태를 하나 더 늘려도 앱이
/// 죽지 않는다 — 기다리는 쪽이 안전한 기본값이다.
AiRunState _stateOf(String? raw) => switch (raw) {
  'running' => AiRunState.running,
  'done' => AiRunState.done,
  'failed' => AiRunState.failed,
  _ => AiRunState.queued,
};
