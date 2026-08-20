// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GithubConnection {

 String get provider; String get login; String? get avatarUrl; DateTime get connectedAt;
/// Create a copy of GithubConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GithubConnectionCopyWith<GithubConnection> get copyWith => _$GithubConnectionCopyWithImpl<GithubConnection>(this as GithubConnection, _$identity);

  /// Serializes this GithubConnection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GithubConnection&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.login, login) || other.login == login)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.connectedAt, connectedAt) || other.connectedAt == connectedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,login,avatarUrl,connectedAt);

@override
String toString() {
  return 'GithubConnection(provider: $provider, login: $login, avatarUrl: $avatarUrl, connectedAt: $connectedAt)';
}


}

/// @nodoc
abstract mixin class $GithubConnectionCopyWith<$Res>  {
  factory $GithubConnectionCopyWith(GithubConnection value, $Res Function(GithubConnection) _then) = _$GithubConnectionCopyWithImpl;
@useResult
$Res call({
 String provider, String login, String? avatarUrl, DateTime connectedAt
});




}
/// @nodoc
class _$GithubConnectionCopyWithImpl<$Res>
    implements $GithubConnectionCopyWith<$Res> {
  _$GithubConnectionCopyWithImpl(this._self, this._then);

  final GithubConnection _self;
  final $Res Function(GithubConnection) _then;

/// Create a copy of GithubConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? login = null,Object? avatarUrl = freezed,Object? connectedAt = null,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,connectedAt: null == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GithubConnection].
extension GithubConnectionPatterns on GithubConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GithubConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GithubConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GithubConnection value)  $default,){
final _that = this;
switch (_that) {
case _GithubConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GithubConnection value)?  $default,){
final _that = this;
switch (_that) {
case _GithubConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String login,  String? avatarUrl,  DateTime connectedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GithubConnection() when $default != null:
return $default(_that.provider,_that.login,_that.avatarUrl,_that.connectedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String login,  String? avatarUrl,  DateTime connectedAt)  $default,) {final _that = this;
switch (_that) {
case _GithubConnection():
return $default(_that.provider,_that.login,_that.avatarUrl,_that.connectedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String login,  String? avatarUrl,  DateTime connectedAt)?  $default,) {final _that = this;
switch (_that) {
case _GithubConnection() when $default != null:
return $default(_that.provider,_that.login,_that.avatarUrl,_that.connectedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GithubConnection implements GithubConnection {
  const _GithubConnection({required this.provider, required this.login, this.avatarUrl, required this.connectedAt});
  factory _GithubConnection.fromJson(Map<String, dynamic> json) => _$GithubConnectionFromJson(json);

@override final  String provider;
@override final  String login;
@override final  String? avatarUrl;
@override final  DateTime connectedAt;

/// Create a copy of GithubConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GithubConnectionCopyWith<_GithubConnection> get copyWith => __$GithubConnectionCopyWithImpl<_GithubConnection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GithubConnectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GithubConnection&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.login, login) || other.login == login)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.connectedAt, connectedAt) || other.connectedAt == connectedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,login,avatarUrl,connectedAt);

@override
String toString() {
  return 'GithubConnection(provider: $provider, login: $login, avatarUrl: $avatarUrl, connectedAt: $connectedAt)';
}


}

/// @nodoc
abstract mixin class _$GithubConnectionCopyWith<$Res> implements $GithubConnectionCopyWith<$Res> {
  factory _$GithubConnectionCopyWith(_GithubConnection value, $Res Function(_GithubConnection) _then) = __$GithubConnectionCopyWithImpl;
@override @useResult
$Res call({
 String provider, String login, String? avatarUrl, DateTime connectedAt
});




}
/// @nodoc
class __$GithubConnectionCopyWithImpl<$Res>
    implements _$GithubConnectionCopyWith<$Res> {
  __$GithubConnectionCopyWithImpl(this._self, this._then);

  final _GithubConnection _self;
  final $Res Function(_GithubConnection) _then;

/// Create a copy of GithubConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? login = null,Object? avatarUrl = freezed,Object? connectedAt = null,}) {
  return _then(_GithubConnection(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,connectedAt: null == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
