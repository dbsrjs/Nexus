// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pull.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PullSummary _$PullSummaryFromJson(Map<String, dynamic> json) => _PullSummary(
  number: (json['number'] as num).toInt(),
  title: json['title'] as String,
  state: $enumDecode(_$PullStateEnumMap, json['state']),
  draft: json['draft'] as bool? ?? false,
  authorLogin: json['authorLogin'] as String?,
  authorAvatarUrl: json['authorAvatarUrl'] as String?,
  sourceBranch: json['sourceBranch'] as String?,
  headSha: json['headSha'] as String?,
  targetBranch: json['targetBranch'] as String?,
  htmlUrl: json['htmlUrl'] as String?,
  openedAt: json['openedAt'] as String?,
  mergedAt: json['mergedAt'] as String?,
  closedAt: json['closedAt'] as String?,
);

Map<String, dynamic> _$PullSummaryToJson(_PullSummary instance) =>
    <String, dynamic>{
      'number': instance.number,
      'title': instance.title,
      'state': _$PullStateEnumMap[instance.state]!,
      'draft': instance.draft,
      'authorLogin': instance.authorLogin,
      'authorAvatarUrl': instance.authorAvatarUrl,
      'sourceBranch': instance.sourceBranch,
      'headSha': instance.headSha,
      'targetBranch': instance.targetBranch,
      'htmlUrl': instance.htmlUrl,
      'openedAt': instance.openedAt,
      'mergedAt': instance.mergedAt,
      'closedAt': instance.closedAt,
    };

const _$PullStateEnumMap = {
  PullState.open: 'open',
  PullState.merged: 'merged',
  PullState.closed: 'closed',
};

_PullDetail _$PullDetailFromJson(Map<String, dynamic> json) => _PullDetail(
  number: (json['number'] as num).toInt(),
  title: json['title'] as String,
  state: $enumDecode(_$PullStateEnumMap, json['state']),
  draft: json['draft'] as bool? ?? false,
  body: json['body'] as String?,
  authorLogin: json['authorLogin'] as String?,
  authorAvatarUrl: json['authorAvatarUrl'] as String?,
  sourceBranch: json['sourceBranch'] as String?,
  headSha: json['headSha'] as String?,
  targetBranch: json['targetBranch'] as String?,
  htmlUrl: json['htmlUrl'] as String?,
  openedAt: json['openedAt'] as String?,
  mergedAt: json['mergedAt'] as String?,
  closedAt: json['closedAt'] as String?,
  additions: (json['additions'] as num?)?.toInt(),
  deletions: (json['deletions'] as num?)?.toInt(),
  changedFiles: (json['changedFiles'] as num?)?.toInt(),
  review: $enumDecodeNullable(_$PullReviewStateEnumMap, json['review']),
);

Map<String, dynamic> _$PullDetailToJson(_PullDetail instance) =>
    <String, dynamic>{
      'number': instance.number,
      'title': instance.title,
      'state': _$PullStateEnumMap[instance.state]!,
      'draft': instance.draft,
      'body': instance.body,
      'authorLogin': instance.authorLogin,
      'authorAvatarUrl': instance.authorAvatarUrl,
      'sourceBranch': instance.sourceBranch,
      'headSha': instance.headSha,
      'targetBranch': instance.targetBranch,
      'htmlUrl': instance.htmlUrl,
      'openedAt': instance.openedAt,
      'mergedAt': instance.mergedAt,
      'closedAt': instance.closedAt,
      'additions': instance.additions,
      'deletions': instance.deletions,
      'changedFiles': instance.changedFiles,
      'review': _$PullReviewStateEnumMap[instance.review],
    };

const _$PullReviewStateEnumMap = {
  PullReviewState.approved: 'approved',
  PullReviewState.changesRequested: 'changes_requested',
};

_PullChangedFile _$PullChangedFileFromJson(Map<String, dynamic> json) =>
    _PullChangedFile(
      path: json['path'] as String,
      status: json['status'] as String,
      additions: (json['additions'] as num?)?.toInt() ?? 0,
      deletions: (json['deletions'] as num?)?.toInt() ?? 0,
      previousPath: json['previousPath'] as String?,
    );

Map<String, dynamic> _$PullChangedFileToJson(_PullChangedFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'status': instance.status,
      'additions': instance.additions,
      'deletions': instance.deletions,
      'previousPath': instance.previousPath,
    };
