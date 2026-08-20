import 'package:freezed_annotation/freezed_annotation.dart';

part 'sprint.freezed.dart';
part 'sprint.g.dart';

/// `planned → active → closed` **한 방향**이다. 닫은 것을 되살리면 번다운이
/// 두 기간을 섞어 읽을 수 없게 된다 — 되돌릴 일이 생기면 새로 만든다.
enum SprintState { planned, active, closed }

/// 화면에 보이는 순서. **enum 선언 순서와 다르다** — 지금 하는 일이 맨 위에
/// 있어야 한다. `.index` 를 그대로 쓰면 도는 스프린트가 계획 뒤로 밀린다.
int sprintStateRank(SprintState state) => switch (state) {
  SprintState.active => 0,
  SprintState.planned => 1,
  SprintState.closed => 2,
};

/// 기간을 정해 할 일을 묶는 단위. **스페이스당 `active` 는 하나**다.
///
/// `sprintId` 가 비어 있는 이슈의 집합이 곧 백로그라, 백로그 목록은 따로 없다.
@freezed
abstract class Sprint with _$Sprint {
  const factory Sprint({
    required String id,
    required String name,
    String? goal,

    /// 계획 단계에서는 날짜가 아직 없을 수 있다. 없으면 번다운을 그릴 수 없다.
    DateTime? startsAt,
    DateTime? endsAt,
    required SprintState state,
  }) = _Sprint;

  factory Sprint.fromJson(Map<String, dynamic> json) => _$SprintFromJson(json);
}

/// 번다운의 하루. 그날 **끝** 시점에 남아 있던 양이다.
@freezed
abstract class BurndownDay with _$BurndownDay {
  const factory BurndownDay({
    required DateTime date,
    required int points,
    required int count,
  }) = _BurndownDay;

  factory BurndownDay.fromJson(Map<String, dynamic> json) =>
      _$BurndownDayFromJson(json);
}

@freezed
abstract class BurndownTotal with _$BurndownTotal {
  const factory BurndownTotal({required int points, required int count}) =
      _BurndownTotal;

  factory BurndownTotal.fromJson(Map<String, dynamic> json) =>
      _$BurndownTotalFromJson(json);
}

/// 번다운 한 벌.
///
/// **이상선은 여기 없다.** 시작 총량에서 균등하게 내려오는 직선이라 화면이
/// 두 점으로 그린다 — 서버가 날짜마다 보내면 같은 값을 두 번 담는 셈이다.
@freezed
abstract class Burndown with _$Burndown {
  const factory Burndown({
    required String sprintId,
    required DateTime startsAt,
    required DateTime endsAt,
    required BurndownTotal total,
    required List<BurndownDay> days,
  }) = _Burndown;

  factory Burndown.fromJson(Map<String, dynamic> json) =>
      _$BurndownFromJson(json);
}
