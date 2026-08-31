// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repo_browse.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RepoBranch {

 String get name; bool get protected;
/// Create a copy of RepoBranch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepoBranchCopyWith<RepoBranch> get copyWith => _$RepoBranchCopyWithImpl<RepoBranch>(this as RepoBranch, _$identity);

  /// Serializes this RepoBranch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepoBranch&&(identical(other.name, name) || other.name == name)&&(identical(other.protected, protected) || other.protected == protected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,protected);

@override
String toString() {
  return 'RepoBranch(name: $name, protected: $protected)';
}


}

/// @nodoc
abstract mixin class $RepoBranchCopyWith<$Res>  {
  factory $RepoBranchCopyWith(RepoBranch value, $Res Function(RepoBranch) _then) = _$RepoBranchCopyWithImpl;
@useResult
$Res call({
 String name, bool protected
});




}
/// @nodoc
class _$RepoBranchCopyWithImpl<$Res>
    implements $RepoBranchCopyWith<$Res> {
  _$RepoBranchCopyWithImpl(this._self, this._then);

  final RepoBranch _self;
  final $Res Function(RepoBranch) _then;

/// Create a copy of RepoBranch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? protected = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protected: null == protected ? _self.protected : protected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RepoBranch].
extension RepoBranchPatterns on RepoBranch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepoBranch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepoBranch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepoBranch value)  $default,){
final _that = this;
switch (_that) {
case _RepoBranch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepoBranch value)?  $default,){
final _that = this;
switch (_that) {
case _RepoBranch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool protected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepoBranch() when $default != null:
return $default(_that.name,_that.protected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool protected)  $default,) {final _that = this;
switch (_that) {
case _RepoBranch():
return $default(_that.name,_that.protected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool protected)?  $default,) {final _that = this;
switch (_that) {
case _RepoBranch() when $default != null:
return $default(_that.name,_that.protected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RepoBranch implements RepoBranch {
  const _RepoBranch({required this.name, this.protected = false});
  factory _RepoBranch.fromJson(Map<String, dynamic> json) => _$RepoBranchFromJson(json);

@override final  String name;
@override@JsonKey() final  bool protected;

/// Create a copy of RepoBranch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepoBranchCopyWith<_RepoBranch> get copyWith => __$RepoBranchCopyWithImpl<_RepoBranch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepoBranchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepoBranch&&(identical(other.name, name) || other.name == name)&&(identical(other.protected, protected) || other.protected == protected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,protected);

@override
String toString() {
  return 'RepoBranch(name: $name, protected: $protected)';
}


}

/// @nodoc
abstract mixin class _$RepoBranchCopyWith<$Res> implements $RepoBranchCopyWith<$Res> {
  factory _$RepoBranchCopyWith(_RepoBranch value, $Res Function(_RepoBranch) _then) = __$RepoBranchCopyWithImpl;
@override @useResult
$Res call({
 String name, bool protected
});




}
/// @nodoc
class __$RepoBranchCopyWithImpl<$Res>
    implements _$RepoBranchCopyWith<$Res> {
  __$RepoBranchCopyWithImpl(this._self, this._then);

  final _RepoBranch _self;
  final $Res Function(_RepoBranch) _then;

/// Create a copy of RepoBranch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? protected = null,}) {
  return _then(_RepoBranch(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protected: null == protected ? _self.protected : protected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TreeEntry {

 String get name; String get path; String get type; int? get size;
/// Create a copy of TreeEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TreeEntryCopyWith<TreeEntry> get copyWith => _$TreeEntryCopyWithImpl<TreeEntry>(this as TreeEntry, _$identity);

  /// Serializes this TreeEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TreeEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,type,size);

@override
String toString() {
  return 'TreeEntry(name: $name, path: $path, type: $type, size: $size)';
}


}

/// @nodoc
abstract mixin class $TreeEntryCopyWith<$Res>  {
  factory $TreeEntryCopyWith(TreeEntry value, $Res Function(TreeEntry) _then) = _$TreeEntryCopyWithImpl;
@useResult
$Res call({
 String name, String path, String type, int? size
});




}
/// @nodoc
class _$TreeEntryCopyWithImpl<$Res>
    implements $TreeEntryCopyWith<$Res> {
  _$TreeEntryCopyWithImpl(this._self, this._then);

  final TreeEntry _self;
  final $Res Function(TreeEntry) _then;

/// Create a copy of TreeEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? type = null,Object? size = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TreeEntry].
extension TreeEntryPatterns on TreeEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TreeEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TreeEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TreeEntry value)  $default,){
final _that = this;
switch (_that) {
case _TreeEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TreeEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TreeEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path,  String type,  int? size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TreeEntry() when $default != null:
return $default(_that.name,_that.path,_that.type,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path,  String type,  int? size)  $default,) {final _that = this;
switch (_that) {
case _TreeEntry():
return $default(_that.name,_that.path,_that.type,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path,  String type,  int? size)?  $default,) {final _that = this;
switch (_that) {
case _TreeEntry() when $default != null:
return $default(_that.name,_that.path,_that.type,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TreeEntry extends TreeEntry {
  const _TreeEntry({required this.name, required this.path, required this.type, this.size}): super._();
  factory _TreeEntry.fromJson(Map<String, dynamic> json) => _$TreeEntryFromJson(json);

@override final  String name;
@override final  String path;
@override final  String type;
@override final  int? size;

/// Create a copy of TreeEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TreeEntryCopyWith<_TreeEntry> get copyWith => __$TreeEntryCopyWithImpl<_TreeEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TreeEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TreeEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,type,size);

@override
String toString() {
  return 'TreeEntry(name: $name, path: $path, type: $type, size: $size)';
}


}

/// @nodoc
abstract mixin class _$TreeEntryCopyWith<$Res> implements $TreeEntryCopyWith<$Res> {
  factory _$TreeEntryCopyWith(_TreeEntry value, $Res Function(_TreeEntry) _then) = __$TreeEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, String type, int? size
});




}
/// @nodoc
class __$TreeEntryCopyWithImpl<$Res>
    implements _$TreeEntryCopyWith<$Res> {
  __$TreeEntryCopyWithImpl(this._self, this._then);

  final _TreeEntry _self;
  final $Res Function(_TreeEntry) _then;

/// Create a copy of TreeEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? type = null,Object? size = freezed,}) {
  return _then(_TreeEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$BlobView {

 String get path; int get size; String? get content; String? get omitted;
/// Create a copy of BlobView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlobViewCopyWith<BlobView> get copyWith => _$BlobViewCopyWithImpl<BlobView>(this as BlobView, _$identity);

  /// Serializes this BlobView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlobView&&(identical(other.path, path) || other.path == path)&&(identical(other.size, size) || other.size == size)&&(identical(other.content, content) || other.content == content)&&(identical(other.omitted, omitted) || other.omitted == omitted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,size,content,omitted);

@override
String toString() {
  return 'BlobView(path: $path, size: $size, content: $content, omitted: $omitted)';
}


}

/// @nodoc
abstract mixin class $BlobViewCopyWith<$Res>  {
  factory $BlobViewCopyWith(BlobView value, $Res Function(BlobView) _then) = _$BlobViewCopyWithImpl;
@useResult
$Res call({
 String path, int size, String? content, String? omitted
});




}
/// @nodoc
class _$BlobViewCopyWithImpl<$Res>
    implements $BlobViewCopyWith<$Res> {
  _$BlobViewCopyWithImpl(this._self, this._then);

  final BlobView _self;
  final $Res Function(BlobView) _then;

/// Create a copy of BlobView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? size = null,Object? content = freezed,Object? omitted = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,omitted: freezed == omitted ? _self.omitted : omitted // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BlobView].
extension BlobViewPatterns on BlobView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlobView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlobView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlobView value)  $default,){
final _that = this;
switch (_that) {
case _BlobView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlobView value)?  $default,){
final _that = this;
switch (_that) {
case _BlobView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int size,  String? content,  String? omitted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlobView() when $default != null:
return $default(_that.path,_that.size,_that.content,_that.omitted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int size,  String? content,  String? omitted)  $default,) {final _that = this;
switch (_that) {
case _BlobView():
return $default(_that.path,_that.size,_that.content,_that.omitted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int size,  String? content,  String? omitted)?  $default,) {final _that = this;
switch (_that) {
case _BlobView() when $default != null:
return $default(_that.path,_that.size,_that.content,_that.omitted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlobView extends BlobView {
  const _BlobView({required this.path, required this.size, this.content, this.omitted}): super._();
  factory _BlobView.fromJson(Map<String, dynamic> json) => _$BlobViewFromJson(json);

@override final  String path;
@override final  int size;
@override final  String? content;
@override final  String? omitted;

/// Create a copy of BlobView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlobViewCopyWith<_BlobView> get copyWith => __$BlobViewCopyWithImpl<_BlobView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlobViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlobView&&(identical(other.path, path) || other.path == path)&&(identical(other.size, size) || other.size == size)&&(identical(other.content, content) || other.content == content)&&(identical(other.omitted, omitted) || other.omitted == omitted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,size,content,omitted);

@override
String toString() {
  return 'BlobView(path: $path, size: $size, content: $content, omitted: $omitted)';
}


}

/// @nodoc
abstract mixin class _$BlobViewCopyWith<$Res> implements $BlobViewCopyWith<$Res> {
  factory _$BlobViewCopyWith(_BlobView value, $Res Function(_BlobView) _then) = __$BlobViewCopyWithImpl;
@override @useResult
$Res call({
 String path, int size, String? content, String? omitted
});




}
/// @nodoc
class __$BlobViewCopyWithImpl<$Res>
    implements _$BlobViewCopyWith<$Res> {
  __$BlobViewCopyWithImpl(this._self, this._then);

  final _BlobView _self;
  final $Res Function(_BlobView) _then;

/// Create a copy of BlobView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? size = null,Object? content = freezed,Object? omitted = freezed,}) {
  return _then(_BlobView(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,omitted: freezed == omitted ? _self.omitted : omitted // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CommitSummary {

 String get sha; String get message; String? get authorName; DateTime? get committedAt;/// 바뀐 파일 수. **브랜치 이력에서는 `null`** 이다 — GitHub 목록 API 가
/// 주지 않는다. 0 으로 두면 "안 바뀐 커밋"으로 읽힌다.
 int? get changedCount;
/// Create a copy of CommitSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommitSummaryCopyWith<CommitSummary> get copyWith => _$CommitSummaryCopyWithImpl<CommitSummary>(this as CommitSummary, _$identity);

  /// Serializes this CommitSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitSummary&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.message, message) || other.message == message)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.committedAt, committedAt) || other.committedAt == committedAt)&&(identical(other.changedCount, changedCount) || other.changedCount == changedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,message,authorName,committedAt,changedCount);

@override
String toString() {
  return 'CommitSummary(sha: $sha, message: $message, authorName: $authorName, committedAt: $committedAt, changedCount: $changedCount)';
}


}

/// @nodoc
abstract mixin class $CommitSummaryCopyWith<$Res>  {
  factory $CommitSummaryCopyWith(CommitSummary value, $Res Function(CommitSummary) _then) = _$CommitSummaryCopyWithImpl;
@useResult
$Res call({
 String sha, String message, String? authorName, DateTime? committedAt, int? changedCount
});




}
/// @nodoc
class _$CommitSummaryCopyWithImpl<$Res>
    implements $CommitSummaryCopyWith<$Res> {
  _$CommitSummaryCopyWithImpl(this._self, this._then);

  final CommitSummary _self;
  final $Res Function(CommitSummary) _then;

/// Create a copy of CommitSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sha = null,Object? message = null,Object? authorName = freezed,Object? committedAt = freezed,Object? changedCount = freezed,}) {
  return _then(_self.copyWith(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,committedAt: freezed == committedAt ? _self.committedAt : committedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,changedCount: freezed == changedCount ? _self.changedCount : changedCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommitSummary].
extension CommitSummaryPatterns on CommitSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommitSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommitSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommitSummary value)  $default,){
final _that = this;
switch (_that) {
case _CommitSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommitSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CommitSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sha,  String message,  String? authorName,  DateTime? committedAt,  int? changedCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommitSummary() when $default != null:
return $default(_that.sha,_that.message,_that.authorName,_that.committedAt,_that.changedCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sha,  String message,  String? authorName,  DateTime? committedAt,  int? changedCount)  $default,) {final _that = this;
switch (_that) {
case _CommitSummary():
return $default(_that.sha,_that.message,_that.authorName,_that.committedAt,_that.changedCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sha,  String message,  String? authorName,  DateTime? committedAt,  int? changedCount)?  $default,) {final _that = this;
switch (_that) {
case _CommitSummary() when $default != null:
return $default(_that.sha,_that.message,_that.authorName,_that.committedAt,_that.changedCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommitSummary extends CommitSummary {
  const _CommitSummary({required this.sha, required this.message, this.authorName, this.committedAt, this.changedCount}): super._();
  factory _CommitSummary.fromJson(Map<String, dynamic> json) => _$CommitSummaryFromJson(json);

@override final  String sha;
@override final  String message;
@override final  String? authorName;
@override final  DateTime? committedAt;
/// 바뀐 파일 수. **브랜치 이력에서는 `null`** 이다 — GitHub 목록 API 가
/// 주지 않는다. 0 으로 두면 "안 바뀐 커밋"으로 읽힌다.
@override final  int? changedCount;

/// Create a copy of CommitSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommitSummaryCopyWith<_CommitSummary> get copyWith => __$CommitSummaryCopyWithImpl<_CommitSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommitSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommitSummary&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.message, message) || other.message == message)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.committedAt, committedAt) || other.committedAt == committedAt)&&(identical(other.changedCount, changedCount) || other.changedCount == changedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,message,authorName,committedAt,changedCount);

@override
String toString() {
  return 'CommitSummary(sha: $sha, message: $message, authorName: $authorName, committedAt: $committedAt, changedCount: $changedCount)';
}


}

/// @nodoc
abstract mixin class _$CommitSummaryCopyWith<$Res> implements $CommitSummaryCopyWith<$Res> {
  factory _$CommitSummaryCopyWith(_CommitSummary value, $Res Function(_CommitSummary) _then) = __$CommitSummaryCopyWithImpl;
@override @useResult
$Res call({
 String sha, String message, String? authorName, DateTime? committedAt, int? changedCount
});




}
/// @nodoc
class __$CommitSummaryCopyWithImpl<$Res>
    implements _$CommitSummaryCopyWith<$Res> {
  __$CommitSummaryCopyWithImpl(this._self, this._then);

  final _CommitSummary _self;
  final $Res Function(_CommitSummary) _then;

/// Create a copy of CommitSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sha = null,Object? message = null,Object? authorName = freezed,Object? committedAt = freezed,Object? changedCount = freezed,}) {
  return _then(_CommitSummary(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,committedAt: freezed == committedAt ? _self.committedAt : committedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,changedCount: freezed == changedCount ? _self.changedCount : changedCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ChangedFile {

 String get path; String get status;
/// Create a copy of ChangedFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangedFileCopyWith<ChangedFile> get copyWith => _$ChangedFileCopyWithImpl<ChangedFile>(this as ChangedFile, _$identity);

  /// Serializes this ChangedFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangedFile&&(identical(other.path, path) || other.path == path)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,status);

@override
String toString() {
  return 'ChangedFile(path: $path, status: $status)';
}


}

/// @nodoc
abstract mixin class $ChangedFileCopyWith<$Res>  {
  factory $ChangedFileCopyWith(ChangedFile value, $Res Function(ChangedFile) _then) = _$ChangedFileCopyWithImpl;
@useResult
$Res call({
 String path, String status
});




}
/// @nodoc
class _$ChangedFileCopyWithImpl<$Res>
    implements $ChangedFileCopyWith<$Res> {
  _$ChangedFileCopyWithImpl(this._self, this._then);

  final ChangedFile _self;
  final $Res Function(ChangedFile) _then;

/// Create a copy of ChangedFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? status = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangedFile].
extension ChangedFilePatterns on ChangedFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangedFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangedFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangedFile value)  $default,){
final _that = this;
switch (_that) {
case _ChangedFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangedFile value)?  $default,){
final _that = this;
switch (_that) {
case _ChangedFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangedFile() when $default != null:
return $default(_that.path,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String status)  $default,) {final _that = this;
switch (_that) {
case _ChangedFile():
return $default(_that.path,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ChangedFile() when $default != null:
return $default(_that.path,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangedFile extends ChangedFile {
  const _ChangedFile({required this.path, required this.status}): super._();
  factory _ChangedFile.fromJson(Map<String, dynamic> json) => _$ChangedFileFromJson(json);

@override final  String path;
@override final  String status;

/// Create a copy of ChangedFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangedFileCopyWith<_ChangedFile> get copyWith => __$ChangedFileCopyWithImpl<_ChangedFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangedFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangedFile&&(identical(other.path, path) || other.path == path)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,status);

@override
String toString() {
  return 'ChangedFile(path: $path, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ChangedFileCopyWith<$Res> implements $ChangedFileCopyWith<$Res> {
  factory _$ChangedFileCopyWith(_ChangedFile value, $Res Function(_ChangedFile) _then) = __$ChangedFileCopyWithImpl;
@override @useResult
$Res call({
 String path, String status
});




}
/// @nodoc
class __$ChangedFileCopyWithImpl<$Res>
    implements _$ChangedFileCopyWith<$Res> {
  __$ChangedFileCopyWithImpl(this._self, this._then);

  final _ChangedFile _self;
  final $Res Function(_ChangedFile) _then;

/// Create a copy of ChangedFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? status = null,}) {
  return _then(_ChangedFile(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CommitDetail {

 String get sha; String get message; String? get authorName; DateTime? get committedAt; List<ChangedFile> get files;
/// Create a copy of CommitDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommitDetailCopyWith<CommitDetail> get copyWith => _$CommitDetailCopyWithImpl<CommitDetail>(this as CommitDetail, _$identity);

  /// Serializes this CommitDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitDetail&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.message, message) || other.message == message)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.committedAt, committedAt) || other.committedAt == committedAt)&&const DeepCollectionEquality().equals(other.files, files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,message,authorName,committedAt,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'CommitDetail(sha: $sha, message: $message, authorName: $authorName, committedAt: $committedAt, files: $files)';
}


}

/// @nodoc
abstract mixin class $CommitDetailCopyWith<$Res>  {
  factory $CommitDetailCopyWith(CommitDetail value, $Res Function(CommitDetail) _then) = _$CommitDetailCopyWithImpl;
@useResult
$Res call({
 String sha, String message, String? authorName, DateTime? committedAt, List<ChangedFile> files
});




}
/// @nodoc
class _$CommitDetailCopyWithImpl<$Res>
    implements $CommitDetailCopyWith<$Res> {
  _$CommitDetailCopyWithImpl(this._self, this._then);

  final CommitDetail _self;
  final $Res Function(CommitDetail) _then;

/// Create a copy of CommitDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sha = null,Object? message = null,Object? authorName = freezed,Object? committedAt = freezed,Object? files = null,}) {
  return _then(_self.copyWith(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,committedAt: freezed == committedAt ? _self.committedAt : committedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<ChangedFile>,
  ));
}

}


/// Adds pattern-matching-related methods to [CommitDetail].
extension CommitDetailPatterns on CommitDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommitDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommitDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommitDetail value)  $default,){
final _that = this;
switch (_that) {
case _CommitDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommitDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CommitDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sha,  String message,  String? authorName,  DateTime? committedAt,  List<ChangedFile> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommitDetail() when $default != null:
return $default(_that.sha,_that.message,_that.authorName,_that.committedAt,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sha,  String message,  String? authorName,  DateTime? committedAt,  List<ChangedFile> files)  $default,) {final _that = this;
switch (_that) {
case _CommitDetail():
return $default(_that.sha,_that.message,_that.authorName,_that.committedAt,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sha,  String message,  String? authorName,  DateTime? committedAt,  List<ChangedFile> files)?  $default,) {final _that = this;
switch (_that) {
case _CommitDetail() when $default != null:
return $default(_that.sha,_that.message,_that.authorName,_that.committedAt,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommitDetail extends CommitDetail {
  const _CommitDetail({required this.sha, required this.message, this.authorName, this.committedAt, final  List<ChangedFile> files = const <ChangedFile>[]}): _files = files,super._();
  factory _CommitDetail.fromJson(Map<String, dynamic> json) => _$CommitDetailFromJson(json);

@override final  String sha;
@override final  String message;
@override final  String? authorName;
@override final  DateTime? committedAt;
 final  List<ChangedFile> _files;
@override@JsonKey() List<ChangedFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of CommitDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommitDetailCopyWith<_CommitDetail> get copyWith => __$CommitDetailCopyWithImpl<_CommitDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommitDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommitDetail&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.message, message) || other.message == message)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.committedAt, committedAt) || other.committedAt == committedAt)&&const DeepCollectionEquality().equals(other._files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,message,authorName,committedAt,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'CommitDetail(sha: $sha, message: $message, authorName: $authorName, committedAt: $committedAt, files: $files)';
}


}

/// @nodoc
abstract mixin class _$CommitDetailCopyWith<$Res> implements $CommitDetailCopyWith<$Res> {
  factory _$CommitDetailCopyWith(_CommitDetail value, $Res Function(_CommitDetail) _then) = __$CommitDetailCopyWithImpl;
@override @useResult
$Res call({
 String sha, String message, String? authorName, DateTime? committedAt, List<ChangedFile> files
});




}
/// @nodoc
class __$CommitDetailCopyWithImpl<$Res>
    implements _$CommitDetailCopyWith<$Res> {
  __$CommitDetailCopyWithImpl(this._self, this._then);

  final _CommitDetail _self;
  final $Res Function(_CommitDetail) _then;

/// Create a copy of CommitDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sha = null,Object? message = null,Object? authorName = freezed,Object? committedAt = freezed,Object? files = null,}) {
  return _then(_CommitDetail(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,committedAt: freezed == committedAt ? _self.committedAt : committedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<ChangedFile>,
  ));
}


}


/// @nodoc
mixin _$RepoEventView {

 String get kind;// push · pr · other
 String get repoId; String? get repoFullPath; String? get ref; int? get number; List<CommitSummary> get commits;
/// Create a copy of RepoEventView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepoEventViewCopyWith<RepoEventView> get copyWith => _$RepoEventViewCopyWithImpl<RepoEventView>(this as RepoEventView, _$identity);

  /// Serializes this RepoEventView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepoEventView&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.repoId, repoId) || other.repoId == repoId)&&(identical(other.repoFullPath, repoFullPath) || other.repoFullPath == repoFullPath)&&(identical(other.ref, ref) || other.ref == ref)&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other.commits, commits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,repoId,repoFullPath,ref,number,const DeepCollectionEquality().hash(commits));

@override
String toString() {
  return 'RepoEventView(kind: $kind, repoId: $repoId, repoFullPath: $repoFullPath, ref: $ref, number: $number, commits: $commits)';
}


}

/// @nodoc
abstract mixin class $RepoEventViewCopyWith<$Res>  {
  factory $RepoEventViewCopyWith(RepoEventView value, $Res Function(RepoEventView) _then) = _$RepoEventViewCopyWithImpl;
@useResult
$Res call({
 String kind, String repoId, String? repoFullPath, String? ref, int? number, List<CommitSummary> commits
});




}
/// @nodoc
class _$RepoEventViewCopyWithImpl<$Res>
    implements $RepoEventViewCopyWith<$Res> {
  _$RepoEventViewCopyWithImpl(this._self, this._then);

  final RepoEventView _self;
  final $Res Function(RepoEventView) _then;

/// Create a copy of RepoEventView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? repoId = null,Object? repoFullPath = freezed,Object? ref = freezed,Object? number = freezed,Object? commits = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,repoId: null == repoId ? _self.repoId : repoId // ignore: cast_nullable_to_non_nullable
as String,repoFullPath: freezed == repoFullPath ? _self.repoFullPath : repoFullPath // ignore: cast_nullable_to_non_nullable
as String?,ref: freezed == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,commits: null == commits ? _self.commits : commits // ignore: cast_nullable_to_non_nullable
as List<CommitSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [RepoEventView].
extension RepoEventViewPatterns on RepoEventView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepoEventView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepoEventView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepoEventView value)  $default,){
final _that = this;
switch (_that) {
case _RepoEventView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepoEventView value)?  $default,){
final _that = this;
switch (_that) {
case _RepoEventView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String repoId,  String? repoFullPath,  String? ref,  int? number,  List<CommitSummary> commits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepoEventView() when $default != null:
return $default(_that.kind,_that.repoId,_that.repoFullPath,_that.ref,_that.number,_that.commits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String repoId,  String? repoFullPath,  String? ref,  int? number,  List<CommitSummary> commits)  $default,) {final _that = this;
switch (_that) {
case _RepoEventView():
return $default(_that.kind,_that.repoId,_that.repoFullPath,_that.ref,_that.number,_that.commits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String repoId,  String? repoFullPath,  String? ref,  int? number,  List<CommitSummary> commits)?  $default,) {final _that = this;
switch (_that) {
case _RepoEventView() when $default != null:
return $default(_that.kind,_that.repoId,_that.repoFullPath,_that.ref,_that.number,_that.commits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RepoEventView implements RepoEventView {
  const _RepoEventView({required this.kind, required this.repoId, this.repoFullPath, this.ref, this.number, final  List<CommitSummary> commits = const <CommitSummary>[]}): _commits = commits;
  factory _RepoEventView.fromJson(Map<String, dynamic> json) => _$RepoEventViewFromJson(json);

@override final  String kind;
// push · pr · other
@override final  String repoId;
@override final  String? repoFullPath;
@override final  String? ref;
@override final  int? number;
 final  List<CommitSummary> _commits;
@override@JsonKey() List<CommitSummary> get commits {
  if (_commits is EqualUnmodifiableListView) return _commits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_commits);
}


/// Create a copy of RepoEventView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepoEventViewCopyWith<_RepoEventView> get copyWith => __$RepoEventViewCopyWithImpl<_RepoEventView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepoEventViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepoEventView&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.repoId, repoId) || other.repoId == repoId)&&(identical(other.repoFullPath, repoFullPath) || other.repoFullPath == repoFullPath)&&(identical(other.ref, ref) || other.ref == ref)&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other._commits, _commits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,repoId,repoFullPath,ref,number,const DeepCollectionEquality().hash(_commits));

@override
String toString() {
  return 'RepoEventView(kind: $kind, repoId: $repoId, repoFullPath: $repoFullPath, ref: $ref, number: $number, commits: $commits)';
}


}

/// @nodoc
abstract mixin class _$RepoEventViewCopyWith<$Res> implements $RepoEventViewCopyWith<$Res> {
  factory _$RepoEventViewCopyWith(_RepoEventView value, $Res Function(_RepoEventView) _then) = __$RepoEventViewCopyWithImpl;
@override @useResult
$Res call({
 String kind, String repoId, String? repoFullPath, String? ref, int? number, List<CommitSummary> commits
});




}
/// @nodoc
class __$RepoEventViewCopyWithImpl<$Res>
    implements _$RepoEventViewCopyWith<$Res> {
  __$RepoEventViewCopyWithImpl(this._self, this._then);

  final _RepoEventView _self;
  final $Res Function(_RepoEventView) _then;

/// Create a copy of RepoEventView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? repoId = null,Object? repoFullPath = freezed,Object? ref = freezed,Object? number = freezed,Object? commits = null,}) {
  return _then(_RepoEventView(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,repoId: null == repoId ? _self.repoId : repoId // ignore: cast_nullable_to_non_nullable
as String,repoFullPath: freezed == repoFullPath ? _self.repoFullPath : repoFullPath // ignore: cast_nullable_to_non_nullable
as String?,ref: freezed == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,commits: null == commits ? _self._commits : commits // ignore: cast_nullable_to_non_nullable
as List<CommitSummary>,
  ));
}


}

// dart format on
