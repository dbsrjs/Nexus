// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GithubRepo _$GithubRepoFromJson(Map<String, dynamic> json) => _GithubRepo(
  id: (json['id'] as num).toInt(),
  fullName: json['fullName'] as String,
  private: json['private'] as bool? ?? false,
  defaultBranch: json['defaultBranch'] as String?,
  pushedAt: json['pushedAt'] == null
      ? null
      : DateTime.parse(json['pushedAt'] as String),
  canWebhook: json['canWebhook'] as bool? ?? false,
);

Map<String, dynamic> _$GithubRepoToJson(_GithubRepo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'private': instance.private,
      'defaultBranch': instance.defaultBranch,
      'pushedAt': instance.pushedAt?.toIso8601String(),
      'canWebhook': instance.canWebhook,
    };

_SpaceRepo _$SpaceRepoFromJson(Map<String, dynamic> json) => _SpaceRepo(
  id: json['id'] as String,
  name: json['name'] as String,
  fullPath: json['fullPath'] as String,
  linkedChannelId: json['linkedChannelId'] as String?,
  webhookExternalId: json['webhookExternalId'] as String?,
);

Map<String, dynamic> _$SpaceRepoToJson(_SpaceRepo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'fullPath': instance.fullPath,
      'linkedChannelId': instance.linkedChannelId,
      'webhookExternalId': instance.webhookExternalId,
    };
