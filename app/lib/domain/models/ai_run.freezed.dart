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
mixin _$AiCitation {

 int get n; String get path; int get startLine; int get endLine; String get commitSha;
/// Create a copy of AiCitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiCitationCopyWith<AiCitation> get copyWith => _$AiCitationCopyWithImpl<AiCitation>(this as AiCitation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiCitation&&(identical(other.n, n) || other.n == n)&&(identical(other.path, path) || other.path == path)&&(identical(other.startLine, startLine) || other.startLine == startLine)&&(identical(other.endLine, endLine) || other.endLine == endLine)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha));
}


@override
int get hashCode => Object.hash(runtimeType,n,path,startLine,endLine,commitSha);

@override
String toString() {
  return 'AiCitation(n: $n, path: $path, startLine: $startLine, endLine: $endLine, commitSha: $commitSha)';
}


}

/// @nodoc
abstract mixin class $AiCitationCopyWith<$Res>  {
  factory $AiCitationCopyWith(AiCitation value, $Res Function(AiCitation) _then) = _$AiCitationCopyWithImpl;
@useResult
$Res call({
 int n, String path, int startLine, int endLine, String commitSha
});




}
/// @nodoc
class _$AiCitationCopyWithImpl<$Res>
    implements $AiCitationCopyWith<$Res> {
  _$AiCitationCopyWithImpl(this._self, this._then);

  final AiCitation _self;
  final $Res Function(AiCitation) _then;

/// Create a copy of AiCitation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? n = null,Object? path = null,Object? startLine = null,Object? endLine = null,Object? commitSha = null,}) {
  return _then(_self.copyWith(
n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,startLine: null == startLine ? _self.startLine : startLine // ignore: cast_nullable_to_non_nullable
as int,endLine: null == endLine ? _self.endLine : endLine // ignore: cast_nullable_to_non_nullable
as int,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AiCitation].
extension AiCitationPatterns on AiCitation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiCitation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiCitation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiCitation value)  $default,){
final _that = this;
switch (_that) {
case _AiCitation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiCitation value)?  $default,){
final _that = this;
switch (_that) {
case _AiCitation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int n,  String path,  int startLine,  int endLine,  String commitSha)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiCitation() when $default != null:
return $default(_that.n,_that.path,_that.startLine,_that.endLine,_that.commitSha);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int n,  String path,  int startLine,  int endLine,  String commitSha)  $default,) {final _that = this;
switch (_that) {
case _AiCitation():
return $default(_that.n,_that.path,_that.startLine,_that.endLine,_that.commitSha);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int n,  String path,  int startLine,  int endLine,  String commitSha)?  $default,) {final _that = this;
switch (_that) {
case _AiCitation() when $default != null:
return $default(_that.n,_that.path,_that.startLine,_that.endLine,_that.commitSha);case _:
  return null;

}
}

}

/// @nodoc


class _AiCitation extends AiCitation {
  const _AiCitation({required this.n, required this.path, required this.startLine, required this.endLine, required this.commitSha}): super._();
  

@override final  int n;
@override final  String path;
@override final  int startLine;
@override final  int endLine;
@override final  String commitSha;

/// Create a copy of AiCitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiCitationCopyWith<_AiCitation> get copyWith => __$AiCitationCopyWithImpl<_AiCitation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiCitation&&(identical(other.n, n) || other.n == n)&&(identical(other.path, path) || other.path == path)&&(identical(other.startLine, startLine) || other.startLine == startLine)&&(identical(other.endLine, endLine) || other.endLine == endLine)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha));
}


@override
int get hashCode => Object.hash(runtimeType,n,path,startLine,endLine,commitSha);

@override
String toString() {
  return 'AiCitation(n: $n, path: $path, startLine: $startLine, endLine: $endLine, commitSha: $commitSha)';
}


}

/// @nodoc
abstract mixin class _$AiCitationCopyWith<$Res> implements $AiCitationCopyWith<$Res> {
  factory _$AiCitationCopyWith(_AiCitation value, $Res Function(_AiCitation) _then) = __$AiCitationCopyWithImpl;
@override @useResult
$Res call({
 int n, String path, int startLine, int endLine, String commitSha
});




}
/// @nodoc
class __$AiCitationCopyWithImpl<$Res>
    implements _$AiCitationCopyWith<$Res> {
  __$AiCitationCopyWithImpl(this._self, this._then);

  final _AiCitation _self;
  final $Res Function(_AiCitation) _then;

/// Create a copy of AiCitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? n = null,Object? path = null,Object? startLine = null,Object? endLine = null,Object? commitSha = null,}) {
  return _then(_AiCitation(
n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,startLine: null == startLine ? _self.startLine : startLine // ignore: cast_nullable_to_non_nullable
as int,endLine: null == endLine ? _self.endLine : endLine // ignore: cast_nullable_to_non_nullable
as int,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AiRun {

 String get runId; String get kind; AiRunState get state;/// 요약 · 자유 질문 본문. **완료 전에는 null 이다** — 빈 문자열로 지어내지
/// 않는다(판단 #2: 모르는 값은 0 이 아니라 null).
 String? get markdown;/// 이슈 초안의 제목 · 본문. 그 밖의 종류에서는 null 이다.
 String? get title; String? get description; List<AiCitation> get citations; String? get error;/// 주 모델 대신 **전환 모델**이 답했는지. 무료 한도(하루 20회)를 넘거나
/// 주 모델이 붐비면 서버가 가벼운 모델로 답한다 — 화면이 한 줄로 알린다.
 bool get fallback;
/// Create a copy of AiRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiRunCopyWith<AiRun> get copyWith => _$AiRunCopyWithImpl<AiRun>(this as AiRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.state, state) || other.state == state)&&(identical(other.markdown, markdown) || other.markdown == markdown)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.citations, citations)&&(identical(other.error, error) || other.error == error)&&(identical(other.fallback, fallback) || other.fallback == fallback));
}


@override
int get hashCode => Object.hash(runtimeType,runId,kind,state,markdown,title,description,const DeepCollectionEquality().hash(citations),error,fallback);

@override
String toString() {
  return 'AiRun(runId: $runId, kind: $kind, state: $state, markdown: $markdown, title: $title, description: $description, citations: $citations, error: $error, fallback: $fallback)';
}


}

/// @nodoc
abstract mixin class $AiRunCopyWith<$Res>  {
  factory $AiRunCopyWith(AiRun value, $Res Function(AiRun) _then) = _$AiRunCopyWithImpl;
@useResult
$Res call({
 String runId, String kind, AiRunState state, String? markdown, String? title, String? description, List<AiCitation> citations, String? error, bool fallback
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
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? kind = null,Object? state = null,Object? markdown = freezed,Object? title = freezed,Object? description = freezed,Object? citations = null,Object? error = freezed,Object? fallback = null,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AiRunState,markdown: freezed == markdown ? _self.markdown : markdown // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,citations: null == citations ? _self.citations : citations // ignore: cast_nullable_to_non_nullable
as List<AiCitation>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fallback: null == fallback ? _self.fallback : fallback // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String kind,  AiRunState state,  String? markdown,  String? title,  String? description,  List<AiCitation> citations,  String? error,  bool fallback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiRun() when $default != null:
return $default(_that.runId,_that.kind,_that.state,_that.markdown,_that.title,_that.description,_that.citations,_that.error,_that.fallback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String kind,  AiRunState state,  String? markdown,  String? title,  String? description,  List<AiCitation> citations,  String? error,  bool fallback)  $default,) {final _that = this;
switch (_that) {
case _AiRun():
return $default(_that.runId,_that.kind,_that.state,_that.markdown,_that.title,_that.description,_that.citations,_that.error,_that.fallback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String kind,  AiRunState state,  String? markdown,  String? title,  String? description,  List<AiCitation> citations,  String? error,  bool fallback)?  $default,) {final _that = this;
switch (_that) {
case _AiRun() when $default != null:
return $default(_that.runId,_that.kind,_that.state,_that.markdown,_that.title,_that.description,_that.citations,_that.error,_that.fallback);case _:
  return null;

}
}

}

/// @nodoc


class _AiRun extends AiRun {
  const _AiRun({required this.runId, required this.kind, required this.state, this.markdown, this.title, this.description, final  List<AiCitation> citations = const <AiCitation>[], this.error, this.fallback = false}): _citations = citations,super._();
  

@override final  String runId;
@override final  String kind;
@override final  AiRunState state;
/// 요약 · 자유 질문 본문. **완료 전에는 null 이다** — 빈 문자열로 지어내지
/// 않는다(판단 #2: 모르는 값은 0 이 아니라 null).
@override final  String? markdown;
/// 이슈 초안의 제목 · 본문. 그 밖의 종류에서는 null 이다.
@override final  String? title;
@override final  String? description;
 final  List<AiCitation> _citations;
@override@JsonKey() List<AiCitation> get citations {
  if (_citations is EqualUnmodifiableListView) return _citations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citations);
}

@override final  String? error;
/// 주 모델 대신 **전환 모델**이 답했는지. 무료 한도(하루 20회)를 넘거나
/// 주 모델이 붐비면 서버가 가벼운 모델로 답한다 — 화면이 한 줄로 알린다.
@override@JsonKey() final  bool fallback;

/// Create a copy of AiRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiRunCopyWith<_AiRun> get copyWith => __$AiRunCopyWithImpl<_AiRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.state, state) || other.state == state)&&(identical(other.markdown, markdown) || other.markdown == markdown)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._citations, _citations)&&(identical(other.error, error) || other.error == error)&&(identical(other.fallback, fallback) || other.fallback == fallback));
}


@override
int get hashCode => Object.hash(runtimeType,runId,kind,state,markdown,title,description,const DeepCollectionEquality().hash(_citations),error,fallback);

@override
String toString() {
  return 'AiRun(runId: $runId, kind: $kind, state: $state, markdown: $markdown, title: $title, description: $description, citations: $citations, error: $error, fallback: $fallback)';
}


}

/// @nodoc
abstract mixin class _$AiRunCopyWith<$Res> implements $AiRunCopyWith<$Res> {
  factory _$AiRunCopyWith(_AiRun value, $Res Function(_AiRun) _then) = __$AiRunCopyWithImpl;
@override @useResult
$Res call({
 String runId, String kind, AiRunState state, String? markdown, String? title, String? description, List<AiCitation> citations, String? error, bool fallback
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
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? kind = null,Object? state = null,Object? markdown = freezed,Object? title = freezed,Object? description = freezed,Object? citations = null,Object? error = freezed,Object? fallback = null,}) {
  return _then(_AiRun(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AiRunState,markdown: freezed == markdown ? _self.markdown : markdown // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,citations: null == citations ? _self._citations : citations // ignore: cast_nullable_to_non_nullable
as List<AiCitation>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fallback: null == fallback ? _self.fallback : fallback // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
