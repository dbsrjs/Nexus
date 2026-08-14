// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Space _$SpaceFromJson(Map<String, dynamic> json) => _Space(
  id: json['id'] as String,
  slug: json['slug'] as String,
  name: json['name'] as String,
  role: $enumDecode(_$SpaceRoleEnumMap, json['role']),
  iconUrl: json['iconUrl'] as String?,
  ownerId: json['ownerId'] as String?,
);

Map<String, dynamic> _$SpaceToJson(_Space instance) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'name': instance.name,
  'role': _$SpaceRoleEnumMap[instance.role]!,
  'iconUrl': instance.iconUrl,
  'ownerId': instance.ownerId,
};

const _$SpaceRoleEnumMap = {
  SpaceRole.guest: 'guest',
  SpaceRole.member: 'member',
  SpaceRole.admin: 'admin',
  SpaceRole.owner: 'owner',
};
