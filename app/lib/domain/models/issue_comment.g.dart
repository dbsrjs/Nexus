// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueComment _$IssueCommentFromJson(Map<String, dynamic> json) =>
    _IssueComment(
      id: json['id'] as String,
      issueId: json['issueId'] as String,
      body: json['body'] as String,
      author: IssueAuthor.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$IssueCommentToJson(_IssueComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'issueId': instance.issueId,
      'body': instance.body,
      'author': instance.author,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
