// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GithubConnection _$GithubConnectionFromJson(Map<String, dynamic> json) =>
    _GithubConnection(
      provider: json['provider'] as String,
      login: json['login'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
    );

Map<String, dynamic> _$GithubConnectionToJson(_GithubConnection instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'login': instance.login,
      'avatarUrl': instance.avatarUrl,
      'connectedAt': instance.connectedAt.toIso8601String(),
    };
