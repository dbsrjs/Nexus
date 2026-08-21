// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GithubRepo {

 int get id; String get fullName; bool get private; String? get defaultBranch; DateTime? get pushedAt;/// 훅을 걸 권한. **false 면 고를 수 없게 그린다** — 눌러 봐야 403 이다.
 bool get canWebhook;
/// Create a copy of GithubRepo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GithubRepoCopyWith<GithubRepo> get copyWith => _$GithubRepoCopyWithImpl<GithubRepo>(this as GithubRepo, _$identity);

  /// Serializes this GithubRepo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GithubRepo&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.private, private) || other.private == private)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.pushedAt, pushedAt) || other.pushedAt == pushedAt)&&(identical(other.canWebhook, canWebhook) || other.canWebhook == canWebhook));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,private,defaultBranch,pushedAt,canWebhook);

@override
String toString() {
  return 'GithubRepo(id: $id, fullName: $fullName, private: $private, defaultBranch: $defaultBranch, pushedAt: $pushedAt, canWebhook: $canWebhook)';
}


}

/// @nodoc
abstract mixin class $GithubRepoCopyWith<$Res>  {
  factory $GithubRepoCopyWith(GithubRepo value, $Res Function(GithubRepo) _then) = _$GithubRepoCopyWithImpl;
@useResult
$Res call({
 int id, String fullName, bool private, String? defaultBranch, DateTime? pushedAt, bool canWebhook
});




}
/// @nodoc
class _$GithubRepoCopyWithImpl<$Res>
    implements $GithubRepoCopyWith<$Res> {
  _$GithubRepoCopyWithImpl(this._self, this._then);

  final GithubRepo _self;
  final $Res Function(GithubRepo) _then;

/// Create a copy of GithubRepo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? private = null,Object? defaultBranch = freezed,Object? pushedAt = freezed,Object? canWebhook = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: freezed == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String?,pushedAt: freezed == pushedAt ? _self.pushedAt : pushedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canWebhook: null == canWebhook ? _self.canWebhook : canWebhook // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GithubRepo].
extension GithubRepoPatterns on GithubRepo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GithubRepo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GithubRepo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GithubRepo value)  $default,){
final _that = this;
switch (_that) {
case _GithubRepo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GithubRepo value)?  $default,){
final _that = this;
switch (_that) {
case _GithubRepo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String fullName,  bool private,  String? defaultBranch,  DateTime? pushedAt,  bool canWebhook)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GithubRepo() when $default != null:
return $default(_that.id,_that.fullName,_that.private,_that.defaultBranch,_that.pushedAt,_that.canWebhook);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String fullName,  bool private,  String? defaultBranch,  DateTime? pushedAt,  bool canWebhook)  $default,) {final _that = this;
switch (_that) {
case _GithubRepo():
return $default(_that.id,_that.fullName,_that.private,_that.defaultBranch,_that.pushedAt,_that.canWebhook);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String fullName,  bool private,  String? defaultBranch,  DateTime? pushedAt,  bool canWebhook)?  $default,) {final _that = this;
switch (_that) {
case _GithubRepo() when $default != null:
return $default(_that.id,_that.fullName,_that.private,_that.defaultBranch,_that.pushedAt,_that.canWebhook);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GithubRepo implements GithubRepo {
  const _GithubRepo({required this.id, required this.fullName, this.private = false, this.defaultBranch, this.pushedAt, this.canWebhook = false});
  factory _GithubRepo.fromJson(Map<String, dynamic> json) => _$GithubRepoFromJson(json);

@override final  int id;
@override final  String fullName;
@override@JsonKey() final  bool private;
@override final  String? defaultBranch;
@override final  DateTime? pushedAt;
/// 훅을 걸 권한. **false 면 고를 수 없게 그린다** — 눌러 봐야 403 이다.
@override@JsonKey() final  bool canWebhook;

/// Create a copy of GithubRepo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GithubRepoCopyWith<_GithubRepo> get copyWith => __$GithubRepoCopyWithImpl<_GithubRepo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GithubRepoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GithubRepo&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.private, private) || other.private == private)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.pushedAt, pushedAt) || other.pushedAt == pushedAt)&&(identical(other.canWebhook, canWebhook) || other.canWebhook == canWebhook));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,private,defaultBranch,pushedAt,canWebhook);

@override
String toString() {
  return 'GithubRepo(id: $id, fullName: $fullName, private: $private, defaultBranch: $defaultBranch, pushedAt: $pushedAt, canWebhook: $canWebhook)';
}


}

/// @nodoc
abstract mixin class _$GithubRepoCopyWith<$Res> implements $GithubRepoCopyWith<$Res> {
  factory _$GithubRepoCopyWith(_GithubRepo value, $Res Function(_GithubRepo) _then) = __$GithubRepoCopyWithImpl;
@override @useResult
$Res call({
 int id, String fullName, bool private, String? defaultBranch, DateTime? pushedAt, bool canWebhook
});




}
/// @nodoc
class __$GithubRepoCopyWithImpl<$Res>
    implements _$GithubRepoCopyWith<$Res> {
  __$GithubRepoCopyWithImpl(this._self, this._then);

  final _GithubRepo _self;
  final $Res Function(_GithubRepo) _then;

/// Create a copy of GithubRepo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? private = null,Object? defaultBranch = freezed,Object? pushedAt = freezed,Object? canWebhook = null,}) {
  return _then(_GithubRepo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: freezed == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String?,pushedAt: freezed == pushedAt ? _self.pushedAt : pushedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canWebhook: null == canWebhook ? _self.canWebhook : canWebhook // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SpaceRepo {

 String get id; String get name; String get fullPath; String? get linkedChannelId;/// GitHub 이 준 훅 id. **없으면 훅이 안 걸린 것**이다 — 등록에 실패했거나
/// 수동으로 붙인 행이다.
 String? get webhookExternalId;
/// Create a copy of SpaceRepo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceRepoCopyWith<SpaceRepo> get copyWith => _$SpaceRepoCopyWithImpl<SpaceRepo>(this as SpaceRepo, _$identity);

  /// Serializes this SpaceRepo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpaceRepo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullPath, fullPath) || other.fullPath == fullPath)&&(identical(other.linkedChannelId, linkedChannelId) || other.linkedChannelId == linkedChannelId)&&(identical(other.webhookExternalId, webhookExternalId) || other.webhookExternalId == webhookExternalId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fullPath,linkedChannelId,webhookExternalId);

@override
String toString() {
  return 'SpaceRepo(id: $id, name: $name, fullPath: $fullPath, linkedChannelId: $linkedChannelId, webhookExternalId: $webhookExternalId)';
}


}

/// @nodoc
abstract mixin class $SpaceRepoCopyWith<$Res>  {
  factory $SpaceRepoCopyWith(SpaceRepo value, $Res Function(SpaceRepo) _then) = _$SpaceRepoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String fullPath, String? linkedChannelId, String? webhookExternalId
});




}
/// @nodoc
class _$SpaceRepoCopyWithImpl<$Res>
    implements $SpaceRepoCopyWith<$Res> {
  _$SpaceRepoCopyWithImpl(this._self, this._then);

  final SpaceRepo _self;
  final $Res Function(SpaceRepo) _then;

/// Create a copy of SpaceRepo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fullPath = null,Object? linkedChannelId = freezed,Object? webhookExternalId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullPath: null == fullPath ? _self.fullPath : fullPath // ignore: cast_nullable_to_non_nullable
as String,linkedChannelId: freezed == linkedChannelId ? _self.linkedChannelId : linkedChannelId // ignore: cast_nullable_to_non_nullable
as String?,webhookExternalId: freezed == webhookExternalId ? _self.webhookExternalId : webhookExternalId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SpaceRepo].
extension SpaceRepoPatterns on SpaceRepo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpaceRepo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpaceRepo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpaceRepo value)  $default,){
final _that = this;
switch (_that) {
case _SpaceRepo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpaceRepo value)?  $default,){
final _that = this;
switch (_that) {
case _SpaceRepo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String fullPath,  String? linkedChannelId,  String? webhookExternalId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpaceRepo() when $default != null:
return $default(_that.id,_that.name,_that.fullPath,_that.linkedChannelId,_that.webhookExternalId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String fullPath,  String? linkedChannelId,  String? webhookExternalId)  $default,) {final _that = this;
switch (_that) {
case _SpaceRepo():
return $default(_that.id,_that.name,_that.fullPath,_that.linkedChannelId,_that.webhookExternalId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String fullPath,  String? linkedChannelId,  String? webhookExternalId)?  $default,) {final _that = this;
switch (_that) {
case _SpaceRepo() when $default != null:
return $default(_that.id,_that.name,_that.fullPath,_that.linkedChannelId,_that.webhookExternalId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpaceRepo extends SpaceRepo {
  const _SpaceRepo({required this.id, required this.name, required this.fullPath, this.linkedChannelId, this.webhookExternalId}): super._();
  factory _SpaceRepo.fromJson(Map<String, dynamic> json) => _$SpaceRepoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String fullPath;
@override final  String? linkedChannelId;
/// GitHub 이 준 훅 id. **없으면 훅이 안 걸린 것**이다 — 등록에 실패했거나
/// 수동으로 붙인 행이다.
@override final  String? webhookExternalId;

/// Create a copy of SpaceRepo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceRepoCopyWith<_SpaceRepo> get copyWith => __$SpaceRepoCopyWithImpl<_SpaceRepo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpaceRepoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpaceRepo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullPath, fullPath) || other.fullPath == fullPath)&&(identical(other.linkedChannelId, linkedChannelId) || other.linkedChannelId == linkedChannelId)&&(identical(other.webhookExternalId, webhookExternalId) || other.webhookExternalId == webhookExternalId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fullPath,linkedChannelId,webhookExternalId);

@override
String toString() {
  return 'SpaceRepo(id: $id, name: $name, fullPath: $fullPath, linkedChannelId: $linkedChannelId, webhookExternalId: $webhookExternalId)';
}


}

/// @nodoc
abstract mixin class _$SpaceRepoCopyWith<$Res> implements $SpaceRepoCopyWith<$Res> {
  factory _$SpaceRepoCopyWith(_SpaceRepo value, $Res Function(_SpaceRepo) _then) = __$SpaceRepoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String fullPath, String? linkedChannelId, String? webhookExternalId
});




}
/// @nodoc
class __$SpaceRepoCopyWithImpl<$Res>
    implements _$SpaceRepoCopyWith<$Res> {
  __$SpaceRepoCopyWithImpl(this._self, this._then);

  final _SpaceRepo _self;
  final $Res Function(_SpaceRepo) _then;

/// Create a copy of SpaceRepo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fullPath = null,Object? linkedChannelId = freezed,Object? webhookExternalId = freezed,}) {
  return _then(_SpaceRepo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullPath: null == fullPath ? _self.fullPath : fullPath // ignore: cast_nullable_to_non_nullable
as String,linkedChannelId: freezed == linkedChannelId ? _self.linkedChannelId : linkedChannelId // ignore: cast_nullable_to_non_nullable
as String?,webhookExternalId: freezed == webhookExternalId ? _self.webhookExternalId : webhookExternalId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
