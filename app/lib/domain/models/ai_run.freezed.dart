// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiRun {

 String get runId; String get kind; AiRunState get state;/// 요약 본문. **완료 전에는 null 이다** — 빈 문자열로 지어내지 않는다
/// (판단 #2: 모르는 값은 0 이 아니라 null).
 String? get markdown; String? get error;
/// Create a copy of AiRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiRunCopyWith<AiRun> get copyWith => _$AiRunCopyWithImpl<AiRun>(this as AiRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.state, state) || other.state == state)&&(identical(other.markdown, markdown) || other.markdown == markdown)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,runId,kind,state,markdown,error);

@override
String toString() {
  return 'AiRun(runId: $runId, kind: $kind, state: $state, markdown: $markdown, error: $error)';
}


}

/// @nodoc
abstract mixin class $AiRunCopyWith<$Res>  {
  factory $AiRunCopyWith(AiRun value, $Res Function(AiRun) _then) = _$AiRunCopyWithImpl;
@useResult
$Res call({
 String runId, String kind, AiRunState state, String? markdown, String? error
});




}
/// @nodoc
class _$AiRunCopyWithImpl<$Res>
    implements $AiRunCopyWith<$Res> {
  _$AiRunCopyWithImpl(this._self, this._then);

  final AiRun _self;
  final $Res Function(AiRun) _then;

/// Create a copy of AiRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? kind = null,Object? state = null,Object? markdown = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AiRunState,markdown: freezed == markdown ? _self.markdown : markdown // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiRun].
extension AiRunPatterns on AiRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiRun value)  $default,){
final _that = this;
switch (_that) {
case _AiRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiRun value)?  $default,){
final _that = this;
switch (_that) {
case _AiRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String kind,  AiRunState state,  String? markdown,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiRun() when $default != null:
return $default(_that.runId,_that.kind,_that.state,_that.markdown,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String kind,  AiRunState state,  String? markdown,  String? error)  $default,) {final _that = this;
switch (_that) {
case _AiRun():
return $default(_that.runId,_that.kind,_that.state,_that.markdown,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String kind,  AiRunState state,  String? markdown,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _AiRun() when $default != null:
return $default(_that.runId,_that.kind,_that.state,_that.markdown,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _AiRun implements AiRun {
  const _AiRun({required this.runId, required this.kind, required this.state, this.markdown, this.error});
  

@override final  String runId;
@override final  String kind;
@override final  AiRunState state;
/// 요약 본문. **완료 전에는 null 이다** — 빈 문자열로 지어내지 않는다
/// (판단 #2: 모르는 값은 0 이 아니라 null).
@override final  String? markdown;
@override final  String? error;

/// Create a copy of AiRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiRunCopyWith<_AiRun> get copyWith => __$AiRunCopyWithImpl<_AiRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.state, state) || other.state == state)&&(identical(other.markdown, markdown) || other.markdown == markdown)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,runId,kind,state,markdown,error);

@override
String toString() {
  return 'AiRun(runId: $runId, kind: $kind, state: $state, markdown: $markdown, error: $error)';
}


}

/// @nodoc
abstract mixin class _$AiRunCopyWith<$Res> implements $AiRunCopyWith<$Res> {
  factory _$AiRunCopyWith(_AiRun value, $Res Function(_AiRun) _then) = __$AiRunCopyWithImpl;
@override @useResult
$Res call({
 String runId, String kind, AiRunState state, String? markdown, String? error
});




}
/// @nodoc
class __$AiRunCopyWithImpl<$Res>
    implements _$AiRunCopyWith<$Res> {
  __$AiRunCopyWithImpl(this._self, this._then);

  final _AiRun _self;
  final $Res Function(_AiRun) _then;

/// Create a copy of AiRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? kind = null,Object? state = null,Object? markdown = freezed,Object? error = freezed,}) {
  return _then(_AiRun(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AiRunState,markdown: freezed == markdown ? _self.markdown : markdown // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
