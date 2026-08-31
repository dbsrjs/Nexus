// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pull.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PullSummary {

 int get number; String get title; PullState get state; bool get draft; String? get authorLogin; String? get authorAvatarUrl; String? get sourceBranch; String? get targetBranch; String? get htmlUrl; String? get openedAt; String? get mergedAt; String? get closedAt;
/// Create a copy of PullSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PullSummaryCopyWith<PullSummary> get copyWith => _$PullSummaryCopyWithImpl<PullSummary>(this as PullSummary, _$identity);

  /// Serializes this PullSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PullSummary&&(identical(other.number, number) || other.number == number)&&(identical(other.title, title) || other.title == title)&&(identical(other.state, state) || other.state == state)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.authorLogin, authorLogin) || other.authorLogin == authorLogin)&&(identical(other.authorAvatarUrl, authorAvatarUrl) || other.authorAvatarUrl == authorAvatarUrl)&&(identical(other.sourceBranch, sourceBranch) || other.sourceBranch == sourceBranch)&&(identical(other.targetBranch, targetBranch) || other.targetBranch == targetBranch)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.mergedAt, mergedAt) || other.mergedAt == mergedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,title,state,draft,authorLogin,authorAvatarUrl,sourceBranch,targetBranch,htmlUrl,openedAt,mergedAt,closedAt);

@override
String toString() {
  return 'PullSummary(number: $number, title: $title, state: $state, draft: $draft, authorLogin: $authorLogin, authorAvatarUrl: $authorAvatarUrl, sourceBranch: $sourceBranch, targetBranch: $targetBranch, htmlUrl: $htmlUrl, openedAt: $openedAt, mergedAt: $mergedAt, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class $PullSummaryCopyWith<$Res>  {
  factory $PullSummaryCopyWith(PullSummary value, $Res Function(PullSummary) _then) = _$PullSummaryCopyWithImpl;
@useResult
$Res call({
 int number, String title, PullState state, bool draft, String? authorLogin, String? authorAvatarUrl, String? sourceBranch, String? targetBranch, String? htmlUrl, String? openedAt, String? mergedAt, String? closedAt
});




}
/// @nodoc
class _$PullSummaryCopyWithImpl<$Res>
    implements $PullSummaryCopyWith<$Res> {
  _$PullSummaryCopyWithImpl(this._self, this._then);

  final PullSummary _self;
  final $Res Function(PullSummary) _then;

/// Create a copy of PullSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? title = null,Object? state = null,Object? draft = null,Object? authorLogin = freezed,Object? authorAvatarUrl = freezed,Object? sourceBranch = freezed,Object? targetBranch = freezed,Object? htmlUrl = freezed,Object? openedAt = freezed,Object? mergedAt = freezed,Object? closedAt = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PullState,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as bool,authorLogin: freezed == authorLogin ? _self.authorLogin : authorLogin // ignore: cast_nullable_to_non_nullable
as String?,authorAvatarUrl: freezed == authorAvatarUrl ? _self.authorAvatarUrl : authorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceBranch: freezed == sourceBranch ? _self.sourceBranch : sourceBranch // ignore: cast_nullable_to_non_nullable
as String?,targetBranch: freezed == targetBranch ? _self.targetBranch : targetBranch // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String?,mergedAt: freezed == mergedAt ? _self.mergedAt : mergedAt // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PullSummary].
extension PullSummaryPatterns on PullSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PullSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PullSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PullSummary value)  $default,){
final _that = this;
switch (_that) {
case _PullSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PullSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PullSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String title,  PullState state,  bool draft,  String? authorLogin,  String? authorAvatarUrl,  String? sourceBranch,  String? targetBranch,  String? htmlUrl,  String? openedAt,  String? mergedAt,  String? closedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PullSummary() when $default != null:
return $default(_that.number,_that.title,_that.state,_that.draft,_that.authorLogin,_that.authorAvatarUrl,_that.sourceBranch,_that.targetBranch,_that.htmlUrl,_that.openedAt,_that.mergedAt,_that.closedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String title,  PullState state,  bool draft,  String? authorLogin,  String? authorAvatarUrl,  String? sourceBranch,  String? targetBranch,  String? htmlUrl,  String? openedAt,  String? mergedAt,  String? closedAt)  $default,) {final _that = this;
switch (_that) {
case _PullSummary():
return $default(_that.number,_that.title,_that.state,_that.draft,_that.authorLogin,_that.authorAvatarUrl,_that.sourceBranch,_that.targetBranch,_that.htmlUrl,_that.openedAt,_that.mergedAt,_that.closedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String title,  PullState state,  bool draft,  String? authorLogin,  String? authorAvatarUrl,  String? sourceBranch,  String? targetBranch,  String? htmlUrl,  String? openedAt,  String? mergedAt,  String? closedAt)?  $default,) {final _that = this;
switch (_that) {
case _PullSummary() when $default != null:
return $default(_that.number,_that.title,_that.state,_that.draft,_that.authorLogin,_that.authorAvatarUrl,_that.sourceBranch,_that.targetBranch,_that.htmlUrl,_that.openedAt,_that.mergedAt,_that.closedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PullSummary implements PullSummary {
  const _PullSummary({required this.number, required this.title, required this.state, this.draft = false, this.authorLogin, this.authorAvatarUrl, this.sourceBranch, this.targetBranch, this.htmlUrl, this.openedAt, this.mergedAt, this.closedAt});
  factory _PullSummary.fromJson(Map<String, dynamic> json) => _$PullSummaryFromJson(json);

@override final  int number;
@override final  String title;
@override final  PullState state;
@override@JsonKey() final  bool draft;
@override final  String? authorLogin;
@override final  String? authorAvatarUrl;
@override final  String? sourceBranch;
@override final  String? targetBranch;
@override final  String? htmlUrl;
@override final  String? openedAt;
@override final  String? mergedAt;
@override final  String? closedAt;

/// Create a copy of PullSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullSummaryCopyWith<_PullSummary> get copyWith => __$PullSummaryCopyWithImpl<_PullSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PullSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullSummary&&(identical(other.number, number) || other.number == number)&&(identical(other.title, title) || other.title == title)&&(identical(other.state, state) || other.state == state)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.authorLogin, authorLogin) || other.authorLogin == authorLogin)&&(identical(other.authorAvatarUrl, authorAvatarUrl) || other.authorAvatarUrl == authorAvatarUrl)&&(identical(other.sourceBranch, sourceBranch) || other.sourceBranch == sourceBranch)&&(identical(other.targetBranch, targetBranch) || other.targetBranch == targetBranch)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.mergedAt, mergedAt) || other.mergedAt == mergedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,title,state,draft,authorLogin,authorAvatarUrl,sourceBranch,targetBranch,htmlUrl,openedAt,mergedAt,closedAt);

@override
String toString() {
  return 'PullSummary(number: $number, title: $title, state: $state, draft: $draft, authorLogin: $authorLogin, authorAvatarUrl: $authorAvatarUrl, sourceBranch: $sourceBranch, targetBranch: $targetBranch, htmlUrl: $htmlUrl, openedAt: $openedAt, mergedAt: $mergedAt, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class _$PullSummaryCopyWith<$Res> implements $PullSummaryCopyWith<$Res> {
  factory _$PullSummaryCopyWith(_PullSummary value, $Res Function(_PullSummary) _then) = __$PullSummaryCopyWithImpl;
@override @useResult
$Res call({
 int number, String title, PullState state, bool draft, String? authorLogin, String? authorAvatarUrl, String? sourceBranch, String? targetBranch, String? htmlUrl, String? openedAt, String? mergedAt, String? closedAt
});




}
/// @nodoc
class __$PullSummaryCopyWithImpl<$Res>
    implements _$PullSummaryCopyWith<$Res> {
  __$PullSummaryCopyWithImpl(this._self, this._then);

  final _PullSummary _self;
  final $Res Function(_PullSummary) _then;

/// Create a copy of PullSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? title = null,Object? state = null,Object? draft = null,Object? authorLogin = freezed,Object? authorAvatarUrl = freezed,Object? sourceBranch = freezed,Object? targetBranch = freezed,Object? htmlUrl = freezed,Object? openedAt = freezed,Object? mergedAt = freezed,Object? closedAt = freezed,}) {
  return _then(_PullSummary(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PullState,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as bool,authorLogin: freezed == authorLogin ? _self.authorLogin : authorLogin // ignore: cast_nullable_to_non_nullable
as String?,authorAvatarUrl: freezed == authorAvatarUrl ? _self.authorAvatarUrl : authorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceBranch: freezed == sourceBranch ? _self.sourceBranch : sourceBranch // ignore: cast_nullable_to_non_nullable
as String?,targetBranch: freezed == targetBranch ? _self.targetBranch : targetBranch // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String?,mergedAt: freezed == mergedAt ? _self.mergedAt : mergedAt // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PullDetail {

 int get number; String get title; PullState get state; bool get draft; String? get body; String? get authorLogin; String? get authorAvatarUrl; String? get sourceBranch; String? get targetBranch; String? get htmlUrl; String? get openedAt; String? get mergedAt; String? get closedAt;/// **서버가 모르면 `null` 이다.** 0 으로 두면 "안 바뀐 PR"로 읽힌다.
 int? get additions; int? get deletions; int? get changedFiles; PullReviewState? get review;
/// Create a copy of PullDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PullDetailCopyWith<PullDetail> get copyWith => _$PullDetailCopyWithImpl<PullDetail>(this as PullDetail, _$identity);

  /// Serializes this PullDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PullDetail&&(identical(other.number, number) || other.number == number)&&(identical(other.title, title) || other.title == title)&&(identical(other.state, state) || other.state == state)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.body, body) || other.body == body)&&(identical(other.authorLogin, authorLogin) || other.authorLogin == authorLogin)&&(identical(other.authorAvatarUrl, authorAvatarUrl) || other.authorAvatarUrl == authorAvatarUrl)&&(identical(other.sourceBranch, sourceBranch) || other.sourceBranch == sourceBranch)&&(identical(other.targetBranch, targetBranch) || other.targetBranch == targetBranch)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.mergedAt, mergedAt) || other.mergedAt == mergedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions)&&(identical(other.changedFiles, changedFiles) || other.changedFiles == changedFiles)&&(identical(other.review, review) || other.review == review));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,title,state,draft,body,authorLogin,authorAvatarUrl,sourceBranch,targetBranch,htmlUrl,openedAt,mergedAt,closedAt,additions,deletions,changedFiles,review);

@override
String toString() {
  return 'PullDetail(number: $number, title: $title, state: $state, draft: $draft, body: $body, authorLogin: $authorLogin, authorAvatarUrl: $authorAvatarUrl, sourceBranch: $sourceBranch, targetBranch: $targetBranch, htmlUrl: $htmlUrl, openedAt: $openedAt, mergedAt: $mergedAt, closedAt: $closedAt, additions: $additions, deletions: $deletions, changedFiles: $changedFiles, review: $review)';
}


}

/// @nodoc
abstract mixin class $PullDetailCopyWith<$Res>  {
  factory $PullDetailCopyWith(PullDetail value, $Res Function(PullDetail) _then) = _$PullDetailCopyWithImpl;
@useResult
$Res call({
 int number, String title, PullState state, bool draft, String? body, String? authorLogin, String? authorAvatarUrl, String? sourceBranch, String? targetBranch, String? htmlUrl, String? openedAt, String? mergedAt, String? closedAt, int? additions, int? deletions, int? changedFiles, PullReviewState? review
});




}
/// @nodoc
class _$PullDetailCopyWithImpl<$Res>
    implements $PullDetailCopyWith<$Res> {
  _$PullDetailCopyWithImpl(this._self, this._then);

  final PullDetail _self;
  final $Res Function(PullDetail) _then;

/// Create a copy of PullDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? title = null,Object? state = null,Object? draft = null,Object? body = freezed,Object? authorLogin = freezed,Object? authorAvatarUrl = freezed,Object? sourceBranch = freezed,Object? targetBranch = freezed,Object? htmlUrl = freezed,Object? openedAt = freezed,Object? mergedAt = freezed,Object? closedAt = freezed,Object? additions = freezed,Object? deletions = freezed,Object? changedFiles = freezed,Object? review = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PullState,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as bool,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,authorLogin: freezed == authorLogin ? _self.authorLogin : authorLogin // ignore: cast_nullable_to_non_nullable
as String?,authorAvatarUrl: freezed == authorAvatarUrl ? _self.authorAvatarUrl : authorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceBranch: freezed == sourceBranch ? _self.sourceBranch : sourceBranch // ignore: cast_nullable_to_non_nullable
as String?,targetBranch: freezed == targetBranch ? _self.targetBranch : targetBranch // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String?,mergedAt: freezed == mergedAt ? _self.mergedAt : mergedAt // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,additions: freezed == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int?,deletions: freezed == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int?,changedFiles: freezed == changedFiles ? _self.changedFiles : changedFiles // ignore: cast_nullable_to_non_nullable
as int?,review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as PullReviewState?,
  ));
}

}


/// Adds pattern-matching-related methods to [PullDetail].
extension PullDetailPatterns on PullDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PullDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PullDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PullDetail value)  $default,){
final _that = this;
switch (_that) {
case _PullDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PullDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PullDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String title,  PullState state,  bool draft,  String? body,  String? authorLogin,  String? authorAvatarUrl,  String? sourceBranch,  String? targetBranch,  String? htmlUrl,  String? openedAt,  String? mergedAt,  String? closedAt,  int? additions,  int? deletions,  int? changedFiles,  PullReviewState? review)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PullDetail() when $default != null:
return $default(_that.number,_that.title,_that.state,_that.draft,_that.body,_that.authorLogin,_that.authorAvatarUrl,_that.sourceBranch,_that.targetBranch,_that.htmlUrl,_that.openedAt,_that.mergedAt,_that.closedAt,_that.additions,_that.deletions,_that.changedFiles,_that.review);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String title,  PullState state,  bool draft,  String? body,  String? authorLogin,  String? authorAvatarUrl,  String? sourceBranch,  String? targetBranch,  String? htmlUrl,  String? openedAt,  String? mergedAt,  String? closedAt,  int? additions,  int? deletions,  int? changedFiles,  PullReviewState? review)  $default,) {final _that = this;
switch (_that) {
case _PullDetail():
return $default(_that.number,_that.title,_that.state,_that.draft,_that.body,_that.authorLogin,_that.authorAvatarUrl,_that.sourceBranch,_that.targetBranch,_that.htmlUrl,_that.openedAt,_that.mergedAt,_that.closedAt,_that.additions,_that.deletions,_that.changedFiles,_that.review);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String title,  PullState state,  bool draft,  String? body,  String? authorLogin,  String? authorAvatarUrl,  String? sourceBranch,  String? targetBranch,  String? htmlUrl,  String? openedAt,  String? mergedAt,  String? closedAt,  int? additions,  int? deletions,  int? changedFiles,  PullReviewState? review)?  $default,) {final _that = this;
switch (_that) {
case _PullDetail() when $default != null:
return $default(_that.number,_that.title,_that.state,_that.draft,_that.body,_that.authorLogin,_that.authorAvatarUrl,_that.sourceBranch,_that.targetBranch,_that.htmlUrl,_that.openedAt,_that.mergedAt,_that.closedAt,_that.additions,_that.deletions,_that.changedFiles,_that.review);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PullDetail implements PullDetail {
  const _PullDetail({required this.number, required this.title, required this.state, this.draft = false, this.body, this.authorLogin, this.authorAvatarUrl, this.sourceBranch, this.targetBranch, this.htmlUrl, this.openedAt, this.mergedAt, this.closedAt, this.additions, this.deletions, this.changedFiles, this.review});
  factory _PullDetail.fromJson(Map<String, dynamic> json) => _$PullDetailFromJson(json);

@override final  int number;
@override final  String title;
@override final  PullState state;
@override@JsonKey() final  bool draft;
@override final  String? body;
@override final  String? authorLogin;
@override final  String? authorAvatarUrl;
@override final  String? sourceBranch;
@override final  String? targetBranch;
@override final  String? htmlUrl;
@override final  String? openedAt;
@override final  String? mergedAt;
@override final  String? closedAt;
/// **서버가 모르면 `null` 이다.** 0 으로 두면 "안 바뀐 PR"로 읽힌다.
@override final  int? additions;
@override final  int? deletions;
@override final  int? changedFiles;
@override final  PullReviewState? review;

/// Create a copy of PullDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullDetailCopyWith<_PullDetail> get copyWith => __$PullDetailCopyWithImpl<_PullDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PullDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullDetail&&(identical(other.number, number) || other.number == number)&&(identical(other.title, title) || other.title == title)&&(identical(other.state, state) || other.state == state)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.body, body) || other.body == body)&&(identical(other.authorLogin, authorLogin) || other.authorLogin == authorLogin)&&(identical(other.authorAvatarUrl, authorAvatarUrl) || other.authorAvatarUrl == authorAvatarUrl)&&(identical(other.sourceBranch, sourceBranch) || other.sourceBranch == sourceBranch)&&(identical(other.targetBranch, targetBranch) || other.targetBranch == targetBranch)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.mergedAt, mergedAt) || other.mergedAt == mergedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions)&&(identical(other.changedFiles, changedFiles) || other.changedFiles == changedFiles)&&(identical(other.review, review) || other.review == review));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,title,state,draft,body,authorLogin,authorAvatarUrl,sourceBranch,targetBranch,htmlUrl,openedAt,mergedAt,closedAt,additions,deletions,changedFiles,review);

@override
String toString() {
  return 'PullDetail(number: $number, title: $title, state: $state, draft: $draft, body: $body, authorLogin: $authorLogin, authorAvatarUrl: $authorAvatarUrl, sourceBranch: $sourceBranch, targetBranch: $targetBranch, htmlUrl: $htmlUrl, openedAt: $openedAt, mergedAt: $mergedAt, closedAt: $closedAt, additions: $additions, deletions: $deletions, changedFiles: $changedFiles, review: $review)';
}


}

/// @nodoc
abstract mixin class _$PullDetailCopyWith<$Res> implements $PullDetailCopyWith<$Res> {
  factory _$PullDetailCopyWith(_PullDetail value, $Res Function(_PullDetail) _then) = __$PullDetailCopyWithImpl;
@override @useResult
$Res call({
 int number, String title, PullState state, bool draft, String? body, String? authorLogin, String? authorAvatarUrl, String? sourceBranch, String? targetBranch, String? htmlUrl, String? openedAt, String? mergedAt, String? closedAt, int? additions, int? deletions, int? changedFiles, PullReviewState? review
});




}
/// @nodoc
class __$PullDetailCopyWithImpl<$Res>
    implements _$PullDetailCopyWith<$Res> {
  __$PullDetailCopyWithImpl(this._self, this._then);

  final _PullDetail _self;
  final $Res Function(_PullDetail) _then;

/// Create a copy of PullDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? title = null,Object? state = null,Object? draft = null,Object? body = freezed,Object? authorLogin = freezed,Object? authorAvatarUrl = freezed,Object? sourceBranch = freezed,Object? targetBranch = freezed,Object? htmlUrl = freezed,Object? openedAt = freezed,Object? mergedAt = freezed,Object? closedAt = freezed,Object? additions = freezed,Object? deletions = freezed,Object? changedFiles = freezed,Object? review = freezed,}) {
  return _then(_PullDetail(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PullState,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as bool,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,authorLogin: freezed == authorLogin ? _self.authorLogin : authorLogin // ignore: cast_nullable_to_non_nullable
as String?,authorAvatarUrl: freezed == authorAvatarUrl ? _self.authorAvatarUrl : authorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceBranch: freezed == sourceBranch ? _self.sourceBranch : sourceBranch // ignore: cast_nullable_to_non_nullable
as String?,targetBranch: freezed == targetBranch ? _self.targetBranch : targetBranch // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String?,mergedAt: freezed == mergedAt ? _self.mergedAt : mergedAt // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,additions: freezed == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int?,deletions: freezed == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int?,changedFiles: freezed == changedFiles ? _self.changedFiles : changedFiles // ignore: cast_nullable_to_non_nullable
as int?,review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as PullReviewState?,
  ));
}


}


/// @nodoc
mixin _$PullChangedFile {

 String get path; String get status; int get additions; int get deletions; String? get previousPath;
/// Create a copy of PullChangedFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PullChangedFileCopyWith<PullChangedFile> get copyWith => _$PullChangedFileCopyWithImpl<PullChangedFile>(this as PullChangedFile, _$identity);

  /// Serializes this PullChangedFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PullChangedFile&&(identical(other.path, path) || other.path == path)&&(identical(other.status, status) || other.status == status)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions)&&(identical(other.previousPath, previousPath) || other.previousPath == previousPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,status,additions,deletions,previousPath);

@override
String toString() {
  return 'PullChangedFile(path: $path, status: $status, additions: $additions, deletions: $deletions, previousPath: $previousPath)';
}


}

/// @nodoc
abstract mixin class $PullChangedFileCopyWith<$Res>  {
  factory $PullChangedFileCopyWith(PullChangedFile value, $Res Function(PullChangedFile) _then) = _$PullChangedFileCopyWithImpl;
@useResult
$Res call({
 String path, String status, int additions, int deletions, String? previousPath
});




}
/// @nodoc
class _$PullChangedFileCopyWithImpl<$Res>
    implements $PullChangedFileCopyWith<$Res> {
  _$PullChangedFileCopyWithImpl(this._self, this._then);

  final PullChangedFile _self;
  final $Res Function(PullChangedFile) _then;

/// Create a copy of PullChangedFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? status = null,Object? additions = null,Object? deletions = null,Object? previousPath = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,additions: null == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int,deletions: null == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int,previousPath: freezed == previousPath ? _self.previousPath : previousPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PullChangedFile].
extension PullChangedFilePatterns on PullChangedFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PullChangedFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PullChangedFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PullChangedFile value)  $default,){
final _that = this;
switch (_that) {
case _PullChangedFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PullChangedFile value)?  $default,){
final _that = this;
switch (_that) {
case _PullChangedFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String status,  int additions,  int deletions,  String? previousPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PullChangedFile() when $default != null:
return $default(_that.path,_that.status,_that.additions,_that.deletions,_that.previousPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String status,  int additions,  int deletions,  String? previousPath)  $default,) {final _that = this;
switch (_that) {
case _PullChangedFile():
return $default(_that.path,_that.status,_that.additions,_that.deletions,_that.previousPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String status,  int additions,  int deletions,  String? previousPath)?  $default,) {final _that = this;
switch (_that) {
case _PullChangedFile() when $default != null:
return $default(_that.path,_that.status,_that.additions,_that.deletions,_that.previousPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PullChangedFile implements PullChangedFile {
  const _PullChangedFile({required this.path, required this.status, this.additions = 0, this.deletions = 0, this.previousPath});
  factory _PullChangedFile.fromJson(Map<String, dynamic> json) => _$PullChangedFileFromJson(json);

@override final  String path;
@override final  String status;
@override@JsonKey() final  int additions;
@override@JsonKey() final  int deletions;
@override final  String? previousPath;

/// Create a copy of PullChangedFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullChangedFileCopyWith<_PullChangedFile> get copyWith => __$PullChangedFileCopyWithImpl<_PullChangedFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PullChangedFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullChangedFile&&(identical(other.path, path) || other.path == path)&&(identical(other.status, status) || other.status == status)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions)&&(identical(other.previousPath, previousPath) || other.previousPath == previousPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,status,additions,deletions,previousPath);

@override
String toString() {
  return 'PullChangedFile(path: $path, status: $status, additions: $additions, deletions: $deletions, previousPath: $previousPath)';
}


}

/// @nodoc
abstract mixin class _$PullChangedFileCopyWith<$Res> implements $PullChangedFileCopyWith<$Res> {
  factory _$PullChangedFileCopyWith(_PullChangedFile value, $Res Function(_PullChangedFile) _then) = __$PullChangedFileCopyWithImpl;
@override @useResult
$Res call({
 String path, String status, int additions, int deletions, String? previousPath
});




}
/// @nodoc
class __$PullChangedFileCopyWithImpl<$Res>
    implements _$PullChangedFileCopyWith<$Res> {
  __$PullChangedFileCopyWithImpl(this._self, this._then);

  final _PullChangedFile _self;
  final $Res Function(_PullChangedFile) _then;

/// Create a copy of PullChangedFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? status = null,Object? additions = null,Object? deletions = null,Object? previousPath = freezed,}) {
  return _then(_PullChangedFile(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,additions: null == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int,deletions: null == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int,previousPath: freezed == previousPath ? _self.previousPath : previousPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
