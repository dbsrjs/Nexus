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
