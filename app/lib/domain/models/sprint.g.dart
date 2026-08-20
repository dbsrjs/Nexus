// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sprint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sprint _$SprintFromJson(Map<String, dynamic> json) => _Sprint(
  id: json['id'] as String,
  name: json['name'] as String,
  goal: json['goal'] as String?,
  startsAt: json['startsAt'] == null
      ? null
      : DateTime.parse(json['startsAt'] as String),
  endsAt: json['endsAt'] == null
      ? null
      : DateTime.parse(json['endsAt'] as String),
  state: $enumDecode(_$SprintStateEnumMap, json['state']),
);

Map<String, dynamic> _$SprintToJson(_Sprint instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'goal': instance.goal,
  'startsAt': instance.startsAt?.toIso8601String(),
  'endsAt': instance.endsAt?.toIso8601String(),
  'state': _$SprintStateEnumMap[instance.state]!,
};

const _$SprintStateEnumMap = {
  SprintState.planned: 'planned',
  SprintState.active: 'active',
  SprintState.closed: 'closed',
};

_BurndownDay _$BurndownDayFromJson(Map<String, dynamic> json) => _BurndownDay(
  date: DateTime.parse(json['date'] as String),
  points: (json['points'] as num).toInt(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$BurndownDayToJson(_BurndownDay instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'points': instance.points,
      'count': instance.count,
    };

_BurndownTotal _$BurndownTotalFromJson(Map<String, dynamic> json) =>
    _BurndownTotal(
      points: (json['points'] as num).toInt(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$BurndownTotalToJson(_BurndownTotal instance) =>
    <String, dynamic>{'points': instance.points, 'count': instance.count};

_Burndown _$BurndownFromJson(Map<String, dynamic> json) => _Burndown(
  sprintId: json['sprintId'] as String,
  startsAt: DateTime.parse(json['startsAt'] as String),
  endsAt: DateTime.parse(json['endsAt'] as String),
  total: BurndownTotal.fromJson(json['total'] as Map<String, dynamic>),
  days: (json['days'] as List<dynamic>)
      .map((e) => BurndownDay.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BurndownToJson(_Burndown instance) => <String, dynamic>{
  'sprintId': instance.sprintId,
  'startsAt': instance.startsAt.toIso8601String(),
  'endsAt': instance.endsAt.toIso8601String(),
  'total': instance.total,
  'days': instance.days,
};
