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

// dart format on
