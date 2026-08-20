// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueComment {

 String get id; String get issueId; String get body; IssueAuthor get author; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of IssueComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueCommentCopyWith<IssueComment> get copyWith => _$IssueCommentCopyWithImpl<IssueComment>(this as IssueComment, _$identity);

  /// Serializes this IssueComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueComment&&(identical(other.id, id) || other.id == id)&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,issueId,body,author,createdAt,updatedAt);

@override
String toString() {
  return 'IssueComment(id: $id, issueId: $issueId, body: $body, author: $author, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $IssueCommentCopyWith<$Res>  {
  factory $IssueCommentCopyWith(IssueComment value, $Res Function(IssueComment) _then) = _$IssueCommentCopyWithImpl;
@useResult
$Res call({
 String id, String issueId, String body, IssueAuthor author, DateTime createdAt, DateTime updatedAt
});


$IssueAuthorCopyWith<$Res> get author;

}
/// @nodoc
class _$IssueCommentCopyWithImpl<$Res>
    implements $IssueCommentCopyWith<$Res> {
  _$IssueCommentCopyWithImpl(this._self, this._then);

  final IssueComment _self;
  final $Res Function(IssueComment) _then;

/// Create a copy of IssueComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? issueId = null,Object? body = null,Object? author = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as IssueAuthor,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of IssueComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueAuthorCopyWith<$Res> get author {
  
  return $IssueAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssueComment].
extension IssueCommentPatterns on IssueComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueComment value)  $default,){
final _that = this;
switch (_that) {
case _IssueComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueComment value)?  $default,){
final _that = this;
switch (_that) {
case _IssueComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String issueId,  String body,  IssueAuthor author,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueComment() when $default != null:
return $default(_that.id,_that.issueId,_that.body,_that.author,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String issueId,  String body,  IssueAuthor author,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _IssueComment():
return $default(_that.id,_that.issueId,_that.body,_that.author,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String issueId,  String body,  IssueAuthor author,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _IssueComment() when $default != null:
return $default(_that.id,_that.issueId,_that.body,_that.author,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueComment implements IssueComment {
  const _IssueComment({required this.id, required this.issueId, required this.body, required this.author, required this.createdAt, required this.updatedAt});
  factory _IssueComment.fromJson(Map<String, dynamic> json) => _$IssueCommentFromJson(json);

@override final  String id;
@override final  String issueId;
@override final  String body;
@override final  IssueAuthor author;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of IssueComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueCommentCopyWith<_IssueComment> get copyWith => __$IssueCommentCopyWithImpl<_IssueComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueComment&&(identical(other.id, id) || other.id == id)&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,issueId,body,author,createdAt,updatedAt);

@override
String toString() {
  return 'IssueComment(id: $id, issueId: $issueId, body: $body, author: $author, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$IssueCommentCopyWith<$Res> implements $IssueCommentCopyWith<$Res> {
  factory _$IssueCommentCopyWith(_IssueComment value, $Res Function(_IssueComment) _then) = __$IssueCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String issueId, String body, IssueAuthor author, DateTime createdAt, DateTime updatedAt
});


@override $IssueAuthorCopyWith<$Res> get author;

}
/// @nodoc
class __$IssueCommentCopyWithImpl<$Res>
    implements _$IssueCommentCopyWith<$Res> {
  __$IssueCommentCopyWithImpl(this._self, this._then);

  final _IssueComment _self;
  final $Res Function(_IssueComment) _then;

/// Create a copy of IssueComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? issueId = null,Object? body = null,Object? author = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_IssueComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as IssueAuthor,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of IssueComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueAuthorCopyWith<$Res> get author {
  
  return $IssueAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

// dart format on
