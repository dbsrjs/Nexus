// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Channel _$ChannelFromJson(Map<String, dynamic> json) => _Channel(
  id: json['id'] as String,
  key: json['key'] as String,
  name: json['name'] as String,
  topic: json['topic'] as String?,
  categoryId: json['categoryId'] as String?,
  isPrivate: json['isPrivate'] as bool? ?? false,
  position: (json['position'] as num?)?.toInt() ?? 0,
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
  mentionCount: (json['mentionCount'] as num?)?.toInt() ?? 0,
  lastReadMessageId: json['lastReadMessageId'] as String?,
  muted: json['muted'] as bool? ?? false,
  canSend: json['canSend'] as bool? ?? true,
  kind: json['kind'] as String? ?? 'text',
  dmUserId: json['dmUserId'] as String?,
  lastMessageAt: json['lastMessageAt'] == null
      ? null
      : DateTime.parse(json['lastMessageAt'] as String),
);

Map<String, dynamic> _$ChannelToJson(_Channel instance) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'name': instance.name,
  'topic': instance.topic,
  'categoryId': instance.categoryId,
  'isPrivate': instance.isPrivate,
  'position': instance.position,
  'unreadCount': instance.unreadCount,
  'mentionCount': instance.mentionCount,
  'lastReadMessageId': instance.lastReadMessageId,
  'muted': instance.muted,
  'canSend': instance.canSend,
  'kind': instance.kind,
  'dmUserId': instance.dmUserId,
  'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
};

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  id: json['id'] as String,
  name: json['name'] as String,
  position: (json['position'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'position': instance.position,
};
