// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_browse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RepoBranch _$RepoBranchFromJson(Map<String, dynamic> json) => _RepoBranch(
  name: json['name'] as String,
  protected: json['protected'] as bool? ?? false,
);

Map<String, dynamic> _$RepoBranchToJson(_RepoBranch instance) =>
    <String, dynamic>{'name': instance.name, 'protected': instance.protected};

_TreeEntry _$TreeEntryFromJson(Map<String, dynamic> json) => _TreeEntry(
  name: json['name'] as String,
  path: json['path'] as String,
  type: json['type'] as String,
  size: (json['size'] as num?)?.toInt(),
);

Map<String, dynamic> _$TreeEntryToJson(_TreeEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'type': instance.type,
      'size': instance.size,
    };

_BlobView _$BlobViewFromJson(Map<String, dynamic> json) => _BlobView(
  path: json['path'] as String,
  size: (json['size'] as num).toInt(),
  content: json['content'] as String?,
  omitted: json['omitted'] as String?,
);

Map<String, dynamic> _$BlobViewToJson(_BlobView instance) => <String, dynamic>{
  'path': instance.path,
  'size': instance.size,
  'content': instance.content,
  'omitted': instance.omitted,
};

_CommitSummary _$CommitSummaryFromJson(Map<String, dynamic> json) =>
    _CommitSummary(
      sha: json['sha'] as String,
      message: json['message'] as String,
      authorName: json['authorName'] as String?,
      committedAt: json['committedAt'] == null
          ? null
          : DateTime.parse(json['committedAt'] as String),
      changedCount: (json['changedCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CommitSummaryToJson(_CommitSummary instance) =>
    <String, dynamic>{
      'sha': instance.sha,
      'message': instance.message,
      'authorName': instance.authorName,
      'committedAt': instance.committedAt?.toIso8601String(),
      'changedCount': instance.changedCount,
    };

_ChangedFile _$ChangedFileFromJson(Map<String, dynamic> json) => _ChangedFile(
  path: json['path'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$ChangedFileToJson(_ChangedFile instance) =>
    <String, dynamic>{'path': instance.path, 'status': instance.status};

_CommitDetail _$CommitDetailFromJson(Map<String, dynamic> json) =>
    _CommitDetail(
      sha: json['sha'] as String,
      message: json['message'] as String,
      authorName: json['authorName'] as String?,
      committedAt: json['committedAt'] == null
          ? null
          : DateTime.parse(json['committedAt'] as String),
      files:
          (json['files'] as List<dynamic>?)
              ?.map((e) => ChangedFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChangedFile>[],
    );

Map<String, dynamic> _$CommitDetailToJson(_CommitDetail instance) =>
    <String, dynamic>{
      'sha': instance.sha,
      'message': instance.message,
      'authorName': instance.authorName,
      'committedAt': instance.committedAt?.toIso8601String(),
      'files': instance.files,
    };

_RepoEventView _$RepoEventViewFromJson(Map<String, dynamic> json) =>
    _RepoEventView(
      kind: json['kind'] as String,
      repoId: json['repoId'] as String,
      repoFullPath: json['repoFullPath'] as String?,
      ref: json['ref'] as String?,
      number: (json['number'] as num?)?.toInt(),
      commits:
          (json['commits'] as List<dynamic>?)
              ?.map((e) => CommitSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CommitSummary>[],
    );

Map<String, dynamic> _$RepoEventViewToJson(_RepoEventView instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'repoId': instance.repoId,
      'repoFullPath': instance.repoFullPath,
      'ref': instance.ref,
      'number': instance.number,
      'commits': instance.commits,
    };
