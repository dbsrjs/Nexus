// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageAuthor _$MessageAuthorFromJson(Map<String, dynamic> json) =>
    _MessageAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$MessageAuthorToJson(_MessageAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
    };

_MessageReaction _$MessageReactionFromJson(Map<String, dynamic> json) =>
    _MessageReaction(
      emoji: json['emoji'] as String,
      count: (json['count'] as num).toInt(),
      mine: json['mine'] as bool? ?? false,
    );

Map<String, dynamic> _$MessageReactionToJson(_MessageReaction instance) =>
    <String, dynamic>{
      'emoji': instance.emoji,
      'count': instance.count,
      'mine': instance.mine,
    };

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  channelId: json['channelId'] as String,
  body: json['body'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  author: MessageAuthor.fromJson(json['author'] as Map<String, dynamic>),
  editedAt: json['editedAt'] == null
      ? null
      : DateTime.parse(json['editedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  reactions:
      (json['reactions'] as List<dynamic>?)
          ?.map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MessageReaction>[],
  parentId: json['parentId'] as String?,
  replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
  lastReplyAt: json['lastReplyAt'] == null
      ? null
      : DateTime.parse(json['lastReplyAt'] as String),
  pending: json['pending'] as bool? ?? false,
  failed: json['failed'] as bool? ?? false,
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'channelId': instance.channelId,
  'body': instance.body,
  'createdAt': instance.createdAt.toIso8601String(),
  'author': instance.author,
  'editedAt': instance.editedAt?.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'reactions': instance.reactions,
  'parentId': instance.parentId,
  'replyCount': instance.replyCount,
  'lastReplyAt': instance.lastReplyAt?.toIso8601String(),
  'pending': instance.pending,
  'failed': instance.failed,
};
