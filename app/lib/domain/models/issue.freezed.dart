// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueAuthor {

 String get id; String get name; String? get avatarUrl;
/// Create a copy of IssueAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueAuthorCopyWith<IssueAuthor> get copyWith => _$IssueAuthorCopyWithImpl<IssueAuthor>(this as IssueAuthor, _$identity);

  /// Serializes this IssueAuthor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl);

@override
String toString() {
  return 'IssueAuthor(id: $id, name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $IssueAuthorCopyWith<$Res>  {
  factory $IssueAuthorCopyWith(IssueAuthor value, $Res Function(IssueAuthor) _then) = _$IssueAuthorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? avatarUrl
});




}
/// @nodoc
class _$IssueAuthorCopyWithImpl<$Res>
    implements $IssueAuthorCopyWith<$Res> {
  _$IssueAuthorCopyWithImpl(this._self, this._then);

  final IssueAuthor _self;
  final $Res Function(IssueAuthor) _then;

/// Create a copy of IssueAuthor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueAuthor].
extension IssueAuthorPatterns on IssueAuthor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueAuthor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueAuthor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueAuthor value)  $default,){
final _that = this;
switch (_that) {
case _IssueAuthor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueAuthor value)?  $default,){
final _that = this;
switch (_that) {
case _IssueAuthor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueAuthor() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _IssueAuthor():
return $default(_that.id,_that.name,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _IssueAuthor() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueAuthor implements IssueAuthor {
  const _IssueAuthor({required this.id, required this.name, this.avatarUrl});
  factory _IssueAuthor.fromJson(Map<String, dynamic> json) => _$IssueAuthorFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? avatarUrl;

/// Create a copy of IssueAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueAuthorCopyWith<_IssueAuthor> get copyWith => __$IssueAuthorCopyWithImpl<_IssueAuthor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueAuthorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl);

@override
String toString() {
  return 'IssueAuthor(id: $id, name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$IssueAuthorCopyWith<$Res> implements $IssueAuthorCopyWith<$Res> {
  factory _$IssueAuthorCopyWith(_IssueAuthor value, $Res Function(_IssueAuthor) _then) = __$IssueAuthorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? avatarUrl
});




}
/// @nodoc
class __$IssueAuthorCopyWithImpl<$Res>
    implements _$IssueAuthorCopyWith<$Res> {
  __$IssueAuthorCopyWithImpl(this._self, this._then);

  final _IssueAuthor _self;
  final $Res Function(_IssueAuthor) _then;

/// Create a copy of IssueAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,}) {
  return _then(_IssueAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Issue {

 String get id;/// 사람이 대화에서 부르는 이름(`NEXUS-12`). 스페이스 안에서 유일하다.
 String get key; String get title; String? get description; IssueStatus get status; IssuePriority get priority; IssueAuthor? get assignee; String? get sprintId; String? get parentId; int? get storyPoints;/// 서버가 **문자열**로 준다 — Decimal 을 double 로 받으면 정밀도가 깎인다.
/// 앱은 정렬과 되돌려 보내기에만 쓰고 산술을 하지 않는다.
 String get position;/// 번다운의 유일한 입력. 상태 전이가 정하므로 앱이 보내지 않는다.
 DateTime? get closedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueCopyWith<Issue> get copyWith => _$IssueCopyWithImpl<Issue>(this as Issue, _$identity);

  /// Serializes this Issue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Issue&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.sprintId, sprintId) || other.sprintId == sprintId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.storyPoints, storyPoints) || other.storyPoints == storyPoints)&&(identical(other.position, position) || other.position == position)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,title,description,status,priority,assignee,sprintId,parentId,storyPoints,position,closedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Issue(id: $id, key: $key, title: $title, description: $description, status: $status, priority: $priority, assignee: $assignee, sprintId: $sprintId, parentId: $parentId, storyPoints: $storyPoints, position: $position, closedAt: $closedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $IssueCopyWith<$Res>  {
  factory $IssueCopyWith(Issue value, $Res Function(Issue) _then) = _$IssueCopyWithImpl;
@useResult
$Res call({
 String id, String key, String title, String? description, IssueStatus status, IssuePriority priority, IssueAuthor? assignee, String? sprintId, String? parentId, int? storyPoints, String position, DateTime? closedAt, DateTime createdAt, DateTime updatedAt
});


$IssueAuthorCopyWith<$Res>? get assignee;

}
/// @nodoc
class _$IssueCopyWithImpl<$Res>
    implements $IssueCopyWith<$Res> {
  _$IssueCopyWithImpl(this._self, this._then);

  final Issue _self;
  final $Res Function(Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? title = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? assignee = freezed,Object? sprintId = freezed,Object? parentId = freezed,Object? storyPoints = freezed,Object? position = null,Object? closedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as IssuePriority,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as IssueAuthor?,sprintId: freezed == sprintId ? _self.sprintId : sprintId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as int?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueAuthorCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $IssueAuthorCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}


/// Adds pattern-matching-related methods to [Issue].
extension IssuePatterns on Issue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Issue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Issue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Issue value)  $default,){
final _that = this;
switch (_that) {
case _Issue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Issue value)?  $default,){
final _that = this;
switch (_that) {
case _Issue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String key,  String title,  String? description,  IssueStatus status,  IssuePriority priority,  IssueAuthor? assignee,  String? sprintId,  String? parentId,  int? storyPoints,  String position,  DateTime? closedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.key,_that.title,_that.description,_that.status,_that.priority,_that.assignee,_that.sprintId,_that.parentId,_that.storyPoints,_that.position,_that.closedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String key,  String title,  String? description,  IssueStatus status,  IssuePriority priority,  IssueAuthor? assignee,  String? sprintId,  String? parentId,  int? storyPoints,  String position,  DateTime? closedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Issue():
return $default(_that.id,_that.key,_that.title,_that.description,_that.status,_that.priority,_that.assignee,_that.sprintId,_that.parentId,_that.storyPoints,_that.position,_that.closedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String key,  String title,  String? description,  IssueStatus status,  IssuePriority priority,  IssueAuthor? assignee,  String? sprintId,  String? parentId,  int? storyPoints,  String position,  DateTime? closedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.key,_that.title,_that.description,_that.status,_that.priority,_that.assignee,_that.sprintId,_that.parentId,_that.storyPoints,_that.position,_that.closedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Issue implements Issue {
  const _Issue({required this.id, required this.key, required this.title, this.description, required this.status, required this.priority, this.assignee, this.sprintId, this.parentId, this.storyPoints, required this.position, this.closedAt, required this.createdAt, required this.updatedAt});
  factory _Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

@override final  String id;
/// 사람이 대화에서 부르는 이름(`NEXUS-12`). 스페이스 안에서 유일하다.
@override final  String key;
@override final  String title;
@override final  String? description;
@override final  IssueStatus status;
@override final  IssuePriority priority;
@override final  IssueAuthor? assignee;
@override final  String? sprintId;
@override final  String? parentId;
@override final  int? storyPoints;
/// 서버가 **문자열**로 준다 — Decimal 을 double 로 받으면 정밀도가 깎인다.
/// 앱은 정렬과 되돌려 보내기에만 쓰고 산술을 하지 않는다.
@override final  String position;
/// 번다운의 유일한 입력. 상태 전이가 정하므로 앱이 보내지 않는다.
@override final  DateTime? closedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueCopyWith<_Issue> get copyWith => __$IssueCopyWithImpl<_Issue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Issue&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.sprintId, sprintId) || other.sprintId == sprintId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.storyPoints, storyPoints) || other.storyPoints == storyPoints)&&(identical(other.position, position) || other.position == position)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,title,description,status,priority,assignee,sprintId,parentId,storyPoints,position,closedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Issue(id: $id, key: $key, title: $title, description: $description, status: $status, priority: $priority, assignee: $assignee, sprintId: $sprintId, parentId: $parentId, storyPoints: $storyPoints, position: $position, closedAt: $closedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$IssueCopyWith<$Res> implements $IssueCopyWith<$Res> {
  factory _$IssueCopyWith(_Issue value, $Res Function(_Issue) _then) = __$IssueCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, String title, String? description, IssueStatus status, IssuePriority priority, IssueAuthor? assignee, String? sprintId, String? parentId, int? storyPoints, String position, DateTime? closedAt, DateTime createdAt, DateTime updatedAt
});


@override $IssueAuthorCopyWith<$Res>? get assignee;

}
/// @nodoc
class __$IssueCopyWithImpl<$Res>
    implements _$IssueCopyWith<$Res> {
  __$IssueCopyWithImpl(this._self, this._then);

  final _Issue _self;
  final $Res Function(_Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? title = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? assignee = freezed,Object? sprintId = freezed,Object? parentId = freezed,Object? storyPoints = freezed,Object? position = null,Object? closedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Issue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as IssuePriority,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as IssueAuthor?,sprintId: freezed == sprintId ? _self.sprintId : sprintId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as int?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueAuthorCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $IssueAuthorCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}

// dart format on
