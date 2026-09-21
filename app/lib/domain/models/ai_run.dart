import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_run.freezed.dart';

// json_serializable 을 쓰지 않는다 — `result` 가 종류(kind)마다 모양이 달라
// 통째로 들지 않고 `markdown` 만 꺼내야 하는데, 그 갈래는 손으로 쓰는 편이
// 짧다(space_member.dart 의 평평하게 펴는 선례와 같은 이유).

/// 서버 `AiRunState` 와 같은 넷이다.
enum AiRunState { queued, running, done, failed }

/// AI 한 번의 실행.
///
/// **`result` 를 통째로 들지 않고 `markdown` 만 꺼낸다.** 13-2·13-3 이
/// 붙으면 종류(kind)마다 `result` 모양이 달라지므로 그때 갈래를 나눈다.
@freezed
abstract class AiRun with _$AiRun {
  const factory AiRun({
    required String runId,
    required String kind,
    required AiRunState state,

    /// 요약 본문. **완료 전에는 null 이다** — 빈 문자열로 지어내지 않는다
    /// (판단 #2: 모르는 값은 0 이 아니라 null).
    String? markdown,
    String? error,
  }) = _AiRun;

  factory AiRun.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    return AiRun(
      runId: json['runId'] as String,
      kind: json['kind'] as String? ?? 'summarize',
      state: _stateOf(json['state'] as String?),
      markdown: result is Map ? result['markdown'] as String? : null,
      error: json['error'] as String?,
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
