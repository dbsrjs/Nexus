// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueLabel _$IssueLabelFromJson(Map<String, dynamic> json) => _IssueLabel(
  id: json['id'] as String,
  name: json['name'] as String,
  color: json['color'] as String,
);

Map<String, dynamic> _$IssueLabelToJson(_IssueLabel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
    };

_IssueOrigin _$IssueOriginFromJson(Map<String, dynamic> json) => _IssueOrigin(
  id: json['id'] as String,
  channelId: json['channelId'] as String,
  body: json['body'] as String?,
  authorName: json['authorName'] as String,
  deleted: json['deleted'] as bool? ?? false,
);

Map<String, dynamic> _$IssueOriginToJson(_IssueOrigin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'channelId': instance.channelId,
      'body': instance.body,
      'authorName': instance.authorName,
      'deleted': instance.deleted,
    };

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
  labels:
      (json['labels'] as List<dynamic>?)
          ?.map((e) => IssueLabel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <IssueLabel>[],
  originMessage: json['originMessage'] == null
      ? null
      : IssueOrigin.fromJson(json['originMessage'] as Map<String, dynamic>),
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
  'labels': instance.labels,
  'originMessage': instance.originMessage,
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
