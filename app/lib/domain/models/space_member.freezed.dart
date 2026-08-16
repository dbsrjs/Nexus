// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'space_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpaceMemberProfile {

 String get userId; String get name; String? get avatarUrl; String? get nickname;
/// Create a copy of SpaceMemberProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceMemberProfileCopyWith<SpaceMemberProfile> get copyWith => _$SpaceMemberProfileCopyWithImpl<SpaceMemberProfile>(this as SpaceMemberProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpaceMemberProfile&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.nickname, nickname) || other.nickname == nickname));
}


@override
int get hashCode => Object.hash(runtimeType,userId,name,avatarUrl,nickname);

@override
String toString() {
  return 'SpaceMemberProfile(userId: $userId, name: $name, avatarUrl: $avatarUrl, nickname: $nickname)';
}


}

/// @nodoc
abstract mixin class $SpaceMemberProfileCopyWith<$Res>  {
  factory $SpaceMemberProfileCopyWith(SpaceMemberProfile value, $Res Function(SpaceMemberProfile) _then) = _$SpaceMemberProfileCopyWithImpl;
@useResult
$Res call({
 String userId, String name, String? avatarUrl, String? nickname
});




}
/// @nodoc
class _$SpaceMemberProfileCopyWithImpl<$Res>
    implements $SpaceMemberProfileCopyWith<$Res> {
  _$SpaceMemberProfileCopyWithImpl(this._self, this._then);

  final SpaceMemberProfile _self;
  final $Res Function(SpaceMemberProfile) _then;

/// Create a copy of SpaceMemberProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,Object? avatarUrl = freezed,Object? nickname = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SpaceMemberProfile].
extension SpaceMemberProfilePatterns on SpaceMemberProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpaceMemberProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpaceMemberProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpaceMemberProfile value)  $default,){
final _that = this;
switch (_that) {
case _SpaceMemberProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpaceMemberProfile value)?  $default,){
final _that = this;
switch (_that) {
case _SpaceMemberProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String name,  String? avatarUrl,  String? nickname)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpaceMemberProfile() when $default != null:
return $default(_that.userId,_that.name,_that.avatarUrl,_that.nickname);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String name,  String? avatarUrl,  String? nickname)  $default,) {final _that = this;
switch (_that) {
case _SpaceMemberProfile():
return $default(_that.userId,_that.name,_that.avatarUrl,_that.nickname);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String name,  String? avatarUrl,  String? nickname)?  $default,) {final _that = this;
switch (_that) {
case _SpaceMemberProfile() when $default != null:
return $default(_that.userId,_that.name,_that.avatarUrl,_that.nickname);case _:
  return null;

}
}

}

/// @nodoc


class _SpaceMemberProfile extends SpaceMemberProfile {
  const _SpaceMemberProfile({required this.userId, required this.name, this.avatarUrl, this.nickname}): super._();
  

@override final  String userId;
@override final  String name;
@override final  String? avatarUrl;
@override final  String? nickname;

/// Create a copy of SpaceMemberProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceMemberProfileCopyWith<_SpaceMemberProfile> get copyWith => __$SpaceMemberProfileCopyWithImpl<_SpaceMemberProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpaceMemberProfile&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.nickname, nickname) || other.nickname == nickname));
}


@override
int get hashCode => Object.hash(runtimeType,userId,name,avatarUrl,nickname);

@override
String toString() {
  return 'SpaceMemberProfile(userId: $userId, name: $name, avatarUrl: $avatarUrl, nickname: $nickname)';
}


}

/// @nodoc
abstract mixin class _$SpaceMemberProfileCopyWith<$Res> implements $SpaceMemberProfileCopyWith<$Res> {
  factory _$SpaceMemberProfileCopyWith(_SpaceMemberProfile value, $Res Function(_SpaceMemberProfile) _then) = __$SpaceMemberProfileCopyWithImpl;
@override @useResult
$Res call({
 String userId, String name, String? avatarUrl, String? nickname
});




}
/// @nodoc
class __$SpaceMemberProfileCopyWithImpl<$Res>
    implements _$SpaceMemberProfileCopyWith<$Res> {
  __$SpaceMemberProfileCopyWithImpl(this._self, this._then);

  final _SpaceMemberProfile _self;
  final $Res Function(_SpaceMemberProfile) _then;

/// Create a copy of SpaceMemberProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,Object? avatarUrl = freezed,Object? nickname = freezed,}) {
  return _then(_SpaceMemberProfile(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
