// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueAuthor _$IssueAuthorFromJson(Map<String, dynamic> json) => _IssueAuthor(
  id: json['id'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$IssueAuthorToJson(_IssueAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
    };

_Issue _$IssueFromJson(Map<String, dynamic> json) => _Issue(
  id: json['id'] as String,
  key: json['key'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  status: $enumDecode(_$IssueStatusEnumMap, json['status']),
  priority: $enumDecode(_$IssuePriorityEnumMap, json['priority']),
  assignee: json['assignee'] == null
      ? null
      : IssueAuthor.fromJson(json['assignee'] as Map<String, dynamic>),
  sprintId: json['sprintId'] as String?,
  parentId: json['parentId'] as String?,
  storyPoints: (json['storyPoints'] as num?)?.toInt(),
  position: json['position'] as String,
  closedAt: json['closedAt'] == null
      ? null
      : DateTime.parse(json['closedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$IssueToJson(_Issue instance) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'title': instance.title,
  'description': instance.description,
  'status': _$IssueStatusEnumMap[instance.status]!,
  'priority': _$IssuePriorityEnumMap[instance.priority]!,
  'assignee': instance.assignee,
  'sprintId': instance.sprintId,
  'parentId': instance.parentId,
  'storyPoints': instance.storyPoints,
  'position': instance.position,
  'closedAt': instance.closedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$IssueStatusEnumMap = {
  IssueStatus.backlog: 'backlog',
  IssueStatus.doing: 'doing',
  IssueStatus.review: 'review',
  IssueStatus.done: 'done',
};

const _$IssuePriorityEnumMap = {
  IssuePriority.low: 'low',
  IssuePriority.mid: 'mid',
  IssuePriority.high: 'high',
};
