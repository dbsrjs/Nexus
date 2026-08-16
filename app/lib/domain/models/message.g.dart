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

_QuotedMessage _$QuotedMessageFromJson(Map<String, dynamic> json) =>
    _QuotedMessage(
      id: json['id'] as String,
      body: json['body'] as String,
      authorName: json['authorName'] as String,
      deleted: json['deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$QuotedMessageToJson(_QuotedMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'authorName': instance.authorName,
      'deleted': instance.deleted,
    };

_MessageMention _$MessageMentionFromJson(Map<String, dynamic> json) =>
    _MessageMention(
      type: json['type'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$MessageMentionToJson(_MessageMention instance) =>
    <String, dynamic>{
      'type': instance.type,
      'userId': instance.userId,
      'name': instance.name,
    };

_MessageAttachment _$MessageAttachmentFromJson(Map<String, dynamic> json) =>
    _MessageAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      mime: json['mime'] as String?,
      sizeBytes: json['sizeBytes'] == null
          ? 0
          : _sizeFromJson(json['sizeBytes']),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageAttachmentToJson(_MessageAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mime': instance.mime,
      'sizeBytes': instance.sizeBytes,
      'width': instance.width,
      'height': instance.height,
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
  mentions:
      (json['mentions'] as List<dynamic>?)
          ?.map((e) => MessageMention.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MessageMention>[],
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MessageAttachment>[],
  pinned: json['pinned'] as bool? ?? false,
  quoted: json['quoted'] == null
      ? null
      : QuotedMessage.fromJson(json['quoted'] as Map<String, dynamic>),
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
  'mentions': instance.mentions,
  'attachments': instance.attachments,
  'pinned': instance.pinned,
  'quoted': instance.quoted,
  'pending': instance.pending,
  'failed': instance.failed,
};
