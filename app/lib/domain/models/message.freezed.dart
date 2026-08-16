// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageAuthor {

 String get id; String get name; String? get avatarUrl;
/// Create a copy of MessageAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageAuthorCopyWith<MessageAuthor> get copyWith => _$MessageAuthorCopyWithImpl<MessageAuthor>(this as MessageAuthor, _$identity);

  /// Serializes this MessageAuthor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl);

@override
String toString() {
  return 'MessageAuthor(id: $id, name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $MessageAuthorCopyWith<$Res>  {
  factory $MessageAuthorCopyWith(MessageAuthor value, $Res Function(MessageAuthor) _then) = _$MessageAuthorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? avatarUrl
});




}
/// @nodoc
class _$MessageAuthorCopyWithImpl<$Res>
    implements $MessageAuthorCopyWith<$Res> {
  _$MessageAuthorCopyWithImpl(this._self, this._then);

  final MessageAuthor _self;
  final $Res Function(MessageAuthor) _then;

/// Create a copy of MessageAuthor
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


/// Adds pattern-matching-related methods to [MessageAuthor].
extension MessageAuthorPatterns on MessageAuthor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageAuthor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageAuthor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageAuthor value)  $default,){
final _that = this;
switch (_that) {
case _MessageAuthor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageAuthor value)?  $default,){
final _that = this;
switch (_that) {
case _MessageAuthor() when $default != null:
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
case _MessageAuthor() when $default != null:
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
case _MessageAuthor():
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
case _MessageAuthor() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageAuthor implements MessageAuthor {
  const _MessageAuthor({required this.id, required this.name, this.avatarUrl});
  factory _MessageAuthor.fromJson(Map<String, dynamic> json) => _$MessageAuthorFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? avatarUrl;

/// Create a copy of MessageAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageAuthorCopyWith<_MessageAuthor> get copyWith => __$MessageAuthorCopyWithImpl<_MessageAuthor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageAuthorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl);

@override
String toString() {
  return 'MessageAuthor(id: $id, name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$MessageAuthorCopyWith<$Res> implements $MessageAuthorCopyWith<$Res> {
  factory _$MessageAuthorCopyWith(_MessageAuthor value, $Res Function(_MessageAuthor) _then) = __$MessageAuthorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? avatarUrl
});




}
/// @nodoc
class __$MessageAuthorCopyWithImpl<$Res>
    implements _$MessageAuthorCopyWith<$Res> {
  __$MessageAuthorCopyWithImpl(this._self, this._then);

  final _MessageAuthor _self;
  final $Res Function(_MessageAuthor) _then;

/// Create a copy of MessageAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,}) {
  return _then(_MessageAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MessageReaction {

 String get emoji; int get count;/// **보는 사람 기준**이다. 그래서 소켓 브로드캐스트에는 실려 오지 않고,
/// 앱이 자기 userId 로 계산한다.
 bool get mine;
/// Create a copy of MessageReaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageReactionCopyWith<MessageReaction> get copyWith => _$MessageReactionCopyWithImpl<MessageReaction>(this as MessageReaction, _$identity);

  /// Serializes this MessageReaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageReaction&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&(identical(other.mine, mine) || other.mine == mine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,emoji,count,mine);

@override
String toString() {
  return 'MessageReaction(emoji: $emoji, count: $count, mine: $mine)';
}


}

/// @nodoc
abstract mixin class $MessageReactionCopyWith<$Res>  {
  factory $MessageReactionCopyWith(MessageReaction value, $Res Function(MessageReaction) _then) = _$MessageReactionCopyWithImpl;
@useResult
$Res call({
 String emoji, int count, bool mine
});




}
/// @nodoc
class _$MessageReactionCopyWithImpl<$Res>
    implements $MessageReactionCopyWith<$Res> {
  _$MessageReactionCopyWithImpl(this._self, this._then);

  final MessageReaction _self;
  final $Res Function(MessageReaction) _then;

/// Create a copy of MessageReaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emoji = null,Object? count = null,Object? mine = null,}) {
  return _then(_self.copyWith(
emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,mine: null == mine ? _self.mine : mine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageReaction].
extension MessageReactionPatterns on MessageReaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageReaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageReaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageReaction value)  $default,){
final _that = this;
switch (_that) {
case _MessageReaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageReaction value)?  $default,){
final _that = this;
switch (_that) {
case _MessageReaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String emoji,  int count,  bool mine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageReaction() when $default != null:
return $default(_that.emoji,_that.count,_that.mine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String emoji,  int count,  bool mine)  $default,) {final _that = this;
switch (_that) {
case _MessageReaction():
return $default(_that.emoji,_that.count,_that.mine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String emoji,  int count,  bool mine)?  $default,) {final _that = this;
switch (_that) {
case _MessageReaction() when $default != null:
return $default(_that.emoji,_that.count,_that.mine);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageReaction implements MessageReaction {
  const _MessageReaction({required this.emoji, required this.count, this.mine = false});
  factory _MessageReaction.fromJson(Map<String, dynamic> json) => _$MessageReactionFromJson(json);

@override final  String emoji;
@override final  int count;
/// **보는 사람 기준**이다. 그래서 소켓 브로드캐스트에는 실려 오지 않고,
/// 앱이 자기 userId 로 계산한다.
@override@JsonKey() final  bool mine;

/// Create a copy of MessageReaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageReactionCopyWith<_MessageReaction> get copyWith => __$MessageReactionCopyWithImpl<_MessageReaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageReactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageReaction&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&(identical(other.mine, mine) || other.mine == mine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,emoji,count,mine);

@override
String toString() {
  return 'MessageReaction(emoji: $emoji, count: $count, mine: $mine)';
}


}

/// @nodoc
abstract mixin class _$MessageReactionCopyWith<$Res> implements $MessageReactionCopyWith<$Res> {
  factory _$MessageReactionCopyWith(_MessageReaction value, $Res Function(_MessageReaction) _then) = __$MessageReactionCopyWithImpl;
@override @useResult
$Res call({
 String emoji, int count, bool mine
});




}
/// @nodoc
class __$MessageReactionCopyWithImpl<$Res>
    implements _$MessageReactionCopyWith<$Res> {
  __$MessageReactionCopyWithImpl(this._self, this._then);

  final _MessageReaction _self;
  final $Res Function(_MessageReaction) _then;

/// Create a copy of MessageReaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emoji = null,Object? count = null,Object? mine = null,}) {
  return _then(_MessageReaction(
emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,mine: null == mine ? _self.mine : mine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$QuotedMessage {

 String get id; String get body; String get authorName;/// 원본이 지워졌는지. 그래도 인용은 남긴다 — 답장의 맥락은 그때도 필요하다.
 bool get deleted;
/// Create a copy of QuotedMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuotedMessageCopyWith<QuotedMessage> get copyWith => _$QuotedMessageCopyWithImpl<QuotedMessage>(this as QuotedMessage, _$identity);

  /// Serializes this QuotedMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuotedMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.deleted, deleted) || other.deleted == deleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,body,authorName,deleted);

@override
String toString() {
  return 'QuotedMessage(id: $id, body: $body, authorName: $authorName, deleted: $deleted)';
}


}

/// @nodoc
abstract mixin class $QuotedMessageCopyWith<$Res>  {
  factory $QuotedMessageCopyWith(QuotedMessage value, $Res Function(QuotedMessage) _then) = _$QuotedMessageCopyWithImpl;
@useResult
$Res call({
 String id, String body, String authorName, bool deleted
});




}
/// @nodoc
class _$QuotedMessageCopyWithImpl<$Res>
    implements $QuotedMessageCopyWith<$Res> {
  _$QuotedMessageCopyWithImpl(this._self, this._then);

  final QuotedMessage _self;
  final $Res Function(QuotedMessage) _then;

/// Create a copy of QuotedMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? body = null,Object? authorName = null,Object? deleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuotedMessage].
extension QuotedMessagePatterns on QuotedMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuotedMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuotedMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuotedMessage value)  $default,){
final _that = this;
switch (_that) {
case _QuotedMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuotedMessage value)?  $default,){
final _that = this;
switch (_that) {
case _QuotedMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String body,  String authorName,  bool deleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuotedMessage() when $default != null:
return $default(_that.id,_that.body,_that.authorName,_that.deleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String body,  String authorName,  bool deleted)  $default,) {final _that = this;
switch (_that) {
case _QuotedMessage():
return $default(_that.id,_that.body,_that.authorName,_that.deleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String body,  String authorName,  bool deleted)?  $default,) {final _that = this;
switch (_that) {
case _QuotedMessage() when $default != null:
return $default(_that.id,_that.body,_that.authorName,_that.deleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuotedMessage implements QuotedMessage {
  const _QuotedMessage({required this.id, required this.body, required this.authorName, this.deleted = false});
  factory _QuotedMessage.fromJson(Map<String, dynamic> json) => _$QuotedMessageFromJson(json);

@override final  String id;
@override final  String body;
@override final  String authorName;
/// 원본이 지워졌는지. 그래도 인용은 남긴다 — 답장의 맥락은 그때도 필요하다.
@override@JsonKey() final  bool deleted;

/// Create a copy of QuotedMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuotedMessageCopyWith<_QuotedMessage> get copyWith => __$QuotedMessageCopyWithImpl<_QuotedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuotedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuotedMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.deleted, deleted) || other.deleted == deleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,body,authorName,deleted);

@override
String toString() {
  return 'QuotedMessage(id: $id, body: $body, authorName: $authorName, deleted: $deleted)';
}


}

/// @nodoc
abstract mixin class _$QuotedMessageCopyWith<$Res> implements $QuotedMessageCopyWith<$Res> {
  factory _$QuotedMessageCopyWith(_QuotedMessage value, $Res Function(_QuotedMessage) _then) = __$QuotedMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String body, String authorName, bool deleted
});




}
/// @nodoc
class __$QuotedMessageCopyWithImpl<$Res>
    implements _$QuotedMessageCopyWith<$Res> {
  __$QuotedMessageCopyWithImpl(this._self, this._then);

  final _QuotedMessage _self;
  final $Res Function(_QuotedMessage) _then;

/// Create a copy of QuotedMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? body = null,Object? authorName = null,Object? deleted = null,}) {
  return _then(_QuotedMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MessageMention {

/// `user` · `channel` · `everyone`.
 String get type;/// `@channel` · `@everyone` 은 대상이 없어 null.
 String? get userId; String? get name;
/// Create a copy of MessageMention
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageMentionCopyWith<MessageMention> get copyWith => _$MessageMentionCopyWithImpl<MessageMention>(this as MessageMention, _$identity);

  /// Serializes this MessageMention to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageMention&&(identical(other.type, type) || other.type == type)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,userId,name);

@override
String toString() {
  return 'MessageMention(type: $type, userId: $userId, name: $name)';
}


}

/// @nodoc
abstract mixin class $MessageMentionCopyWith<$Res>  {
  factory $MessageMentionCopyWith(MessageMention value, $Res Function(MessageMention) _then) = _$MessageMentionCopyWithImpl;
@useResult
$Res call({
 String type, String? userId, String? name
});




}
/// @nodoc
class _$MessageMentionCopyWithImpl<$Res>
    implements $MessageMentionCopyWith<$Res> {
  _$MessageMentionCopyWithImpl(this._self, this._then);

  final MessageMention _self;
  final $Res Function(MessageMention) _then;

/// Create a copy of MessageMention
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? userId = freezed,Object? name = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageMention].
extension MessageMentionPatterns on MessageMention {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageMention value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageMention() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageMention value)  $default,){
final _that = this;
switch (_that) {
case _MessageMention():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageMention value)?  $default,){
final _that = this;
switch (_that) {
case _MessageMention() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String? userId,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageMention() when $default != null:
return $default(_that.type,_that.userId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String? userId,  String? name)  $default,) {final _that = this;
switch (_that) {
case _MessageMention():
return $default(_that.type,_that.userId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String? userId,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _MessageMention() when $default != null:
return $default(_that.type,_that.userId,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageMention implements MessageMention {
  const _MessageMention({required this.type, this.userId, this.name});
  factory _MessageMention.fromJson(Map<String, dynamic> json) => _$MessageMentionFromJson(json);

/// `user` · `channel` · `everyone`.
@override final  String type;
/// `@channel` · `@everyone` 은 대상이 없어 null.
@override final  String? userId;
@override final  String? name;

/// Create a copy of MessageMention
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageMentionCopyWith<_MessageMention> get copyWith => __$MessageMentionCopyWithImpl<_MessageMention>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageMentionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageMention&&(identical(other.type, type) || other.type == type)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,userId,name);

@override
String toString() {
  return 'MessageMention(type: $type, userId: $userId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$MessageMentionCopyWith<$Res> implements $MessageMentionCopyWith<$Res> {
  factory _$MessageMentionCopyWith(_MessageMention value, $Res Function(_MessageMention) _then) = __$MessageMentionCopyWithImpl;
@override @useResult
$Res call({
 String type, String? userId, String? name
});




}
/// @nodoc
class __$MessageMentionCopyWithImpl<$Res>
    implements _$MessageMentionCopyWith<$Res> {
  __$MessageMentionCopyWithImpl(this._self, this._then);

  final _MessageMention _self;
  final $Res Function(_MessageMention) _then;

/// Create a copy of MessageMention
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? userId = freezed,Object? name = freezed,}) {
  return _then(_MessageMention(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MessageAttachment {

 String get id; String get name; String? get mime;/// 바이트 수. **서버가 문자열로 준다** — `bigint` 컬럼이라 숫자로 바꾸면
/// 2^53 을 넘는 값이 조용히 뭉개진다. 앱에서는 표시용이라 int 로 받는다.
@JsonKey(fromJson: _sizeFromJson) int get sizeBytes;/// 이미지면 원본 크기. 미리보기 자리를 먼저 잡는 데 쓴다 —
/// 없으면 이미지가 로드될 때마다 목록이 튄다.
 int? get width; int? get height;
/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageAttachmentCopyWith<MessageAttachment> get copyWith => _$MessageAttachmentCopyWithImpl<MessageAttachment>(this as MessageAttachment, _$identity);

  /// Serializes this MessageAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,mime,sizeBytes,width,height);

@override
String toString() {
  return 'MessageAttachment(id: $id, name: $name, mime: $mime, sizeBytes: $sizeBytes, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $MessageAttachmentCopyWith<$Res>  {
  factory $MessageAttachmentCopyWith(MessageAttachment value, $Res Function(MessageAttachment) _then) = _$MessageAttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? mime,@JsonKey(fromJson: _sizeFromJson) int sizeBytes, int? width, int? height
});




}
/// @nodoc
class _$MessageAttachmentCopyWithImpl<$Res>
    implements $MessageAttachmentCopyWith<$Res> {
  _$MessageAttachmentCopyWithImpl(this._self, this._then);

  final MessageAttachment _self;
  final $Res Function(MessageAttachment) _then;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? mime = freezed,Object? sizeBytes = null,Object? width = freezed,Object? height = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageAttachment].
extension MessageAttachmentPatterns on MessageAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageAttachment value)  $default,){
final _that = this;
switch (_that) {
case _MessageAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? mime, @JsonKey(fromJson: _sizeFromJson)  int sizeBytes,  int? width,  int? height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
return $default(_that.id,_that.name,_that.mime,_that.sizeBytes,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? mime, @JsonKey(fromJson: _sizeFromJson)  int sizeBytes,  int? width,  int? height)  $default,) {final _that = this;
switch (_that) {
case _MessageAttachment():
return $default(_that.id,_that.name,_that.mime,_that.sizeBytes,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? mime, @JsonKey(fromJson: _sizeFromJson)  int sizeBytes,  int? width,  int? height)?  $default,) {final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
return $default(_that.id,_that.name,_that.mime,_that.sizeBytes,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageAttachment extends MessageAttachment {
  const _MessageAttachment({required this.id, required this.name, this.mime, @JsonKey(fromJson: _sizeFromJson) this.sizeBytes = 0, this.width, this.height}): super._();
  factory _MessageAttachment.fromJson(Map<String, dynamic> json) => _$MessageAttachmentFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? mime;
/// 바이트 수. **서버가 문자열로 준다** — `bigint` 컬럼이라 숫자로 바꾸면
/// 2^53 을 넘는 값이 조용히 뭉개진다. 앱에서는 표시용이라 int 로 받는다.
@override@JsonKey(fromJson: _sizeFromJson) final  int sizeBytes;
/// 이미지면 원본 크기. 미리보기 자리를 먼저 잡는 데 쓴다 —
/// 없으면 이미지가 로드될 때마다 목록이 튄다.
@override final  int? width;
@override final  int? height;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageAttachmentCopyWith<_MessageAttachment> get copyWith => __$MessageAttachmentCopyWithImpl<_MessageAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,mime,sizeBytes,width,height);

@override
String toString() {
  return 'MessageAttachment(id: $id, name: $name, mime: $mime, sizeBytes: $sizeBytes, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$MessageAttachmentCopyWith<$Res> implements $MessageAttachmentCopyWith<$Res> {
  factory _$MessageAttachmentCopyWith(_MessageAttachment value, $Res Function(_MessageAttachment) _then) = __$MessageAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? mime,@JsonKey(fromJson: _sizeFromJson) int sizeBytes, int? width, int? height
});




}
/// @nodoc
class __$MessageAttachmentCopyWithImpl<$Res>
    implements _$MessageAttachmentCopyWith<$Res> {
  __$MessageAttachmentCopyWithImpl(this._self, this._then);

  final _MessageAttachment _self;
  final $Res Function(_MessageAttachment) _then;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? mime = freezed,Object? sizeBytes = null,Object? width = freezed,Object? height = freezed,}) {
  return _then(_MessageAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Message {

 String get id; String get channelId; String get body; DateTime get createdAt; MessageAuthor get author; DateTime? get editedAt;/// 소프트 삭제. 서버는 행을 지우지 않고 **본문만 비워서** 내려보낸다
/// (docs/백엔드-설계.md §3 보관 정책). 목록에서 빼지 않는 이유는,
/// 빼 버리면 클라이언트가 이미 그린 메시지를 지울 근거가 없어서다.
 DateTime? get deletedAt;/// 이모지별 요약. 서버가 목록에 함께 실어 준다.
 List<MessageReaction> get reactions;/// 값이 있으면 스레드 답글이다. 채널 타임라인에는 나오지 않는다.
 String? get parentId;/// 이 메시지에 달린 답글 수. 답글 자신은 늘 0 이다.
 int get replyCount;/// 마지막 답글 시각. 스레드 요약을 그릴 때 쓴다.
 DateTime? get lastReplyAt;/// 이 메시지에 걸린 멘션. 본문의 `<@id>` 를 이름으로 바꾸는 데 쓴다.
 List<MessageMention> get mentions;/// 붙은 파일. **본문이 비어도 이것만 있으면 메시지가 성립한다.**
 List<MessageAttachment> get attachments;/// 채널 상단에 고정됐는지. 답글은 고정할 수 없어 늘 false 다.
 bool get pinned;/// 답장이면 가리키는 원본. **`parentId` 와 다른 축이다** — 답장은
/// 타임라인에 남고, 스레드 답글은 빠진다. 둘을 함께 쓸 수도 있다.
 QuotedMessage? get quoted;/// 낙관적 갱신용 — 서버 응답을 기다리는 중.
/// 서버 응답에는 없는 필드라 기본값 false 로 들어온다.
 bool get pending;/// 전송이 실패해 재시도를 기다리는 중. 역시 로컬 전용이다.
 bool get failed;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, id) || other.id == id)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.author, author) || other.author == author)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&const DeepCollectionEquality().equals(other.reactions, reactions)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.lastReplyAt, lastReplyAt) || other.lastReplyAt == lastReplyAt)&&const DeepCollectionEquality().equals(other.mentions, mentions)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.quoted, quoted) || other.quoted == quoted)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.failed, failed) || other.failed == failed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,channelId,body,createdAt,author,editedAt,deletedAt,const DeepCollectionEquality().hash(reactions),parentId,replyCount,lastReplyAt,const DeepCollectionEquality().hash(mentions),const DeepCollectionEquality().hash(attachments),pinned,quoted,pending,failed);

@override
String toString() {
  return 'Message(id: $id, channelId: $channelId, body: $body, createdAt: $createdAt, author: $author, editedAt: $editedAt, deletedAt: $deletedAt, reactions: $reactions, parentId: $parentId, replyCount: $replyCount, lastReplyAt: $lastReplyAt, mentions: $mentions, attachments: $attachments, pinned: $pinned, quoted: $quoted, pending: $pending, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, String channelId, String body, DateTime createdAt, MessageAuthor author, DateTime? editedAt, DateTime? deletedAt, List<MessageReaction> reactions, String? parentId, int replyCount, DateTime? lastReplyAt, List<MessageMention> mentions, List<MessageAttachment> attachments, bool pinned, QuotedMessage? quoted, bool pending, bool failed
});


$MessageAuthorCopyWith<$Res> get author;$QuotedMessageCopyWith<$Res>? get quoted;

}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? channelId = null,Object? body = null,Object? createdAt = null,Object? author = null,Object? editedAt = freezed,Object? deletedAt = freezed,Object? reactions = null,Object? parentId = freezed,Object? replyCount = null,Object? lastReplyAt = freezed,Object? mentions = null,Object? attachments = null,Object? pinned = null,Object? quoted = freezed,Object? pending = null,Object? failed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as MessageAuthor,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<MessageReaction>,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,lastReplyAt: freezed == lastReplyAt ? _self.lastReplyAt : lastReplyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mentions: null == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<MessageMention>,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachment>,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,quoted: freezed == quoted ? _self.quoted : quoted // ignore: cast_nullable_to_non_nullable
as QuotedMessage?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageAuthorCopyWith<$Res> get author {
  
  return $MessageAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuotedMessageCopyWith<$Res>? get quoted {
    if (_self.quoted == null) {
    return null;
  }

  return $QuotedMessageCopyWith<$Res>(_self.quoted!, (value) {
    return _then(_self.copyWith(quoted: value));
  });
}
}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String channelId,  String body,  DateTime createdAt,  MessageAuthor author,  DateTime? editedAt,  DateTime? deletedAt,  List<MessageReaction> reactions,  String? parentId,  int replyCount,  DateTime? lastReplyAt,  List<MessageMention> mentions,  List<MessageAttachment> attachments,  bool pinned,  QuotedMessage? quoted,  bool pending,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.channelId,_that.body,_that.createdAt,_that.author,_that.editedAt,_that.deletedAt,_that.reactions,_that.parentId,_that.replyCount,_that.lastReplyAt,_that.mentions,_that.attachments,_that.pinned,_that.quoted,_that.pending,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String channelId,  String body,  DateTime createdAt,  MessageAuthor author,  DateTime? editedAt,  DateTime? deletedAt,  List<MessageReaction> reactions,  String? parentId,  int replyCount,  DateTime? lastReplyAt,  List<MessageMention> mentions,  List<MessageAttachment> attachments,  bool pinned,  QuotedMessage? quoted,  bool pending,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.channelId,_that.body,_that.createdAt,_that.author,_that.editedAt,_that.deletedAt,_that.reactions,_that.parentId,_that.replyCount,_that.lastReplyAt,_that.mentions,_that.attachments,_that.pinned,_that.quoted,_that.pending,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String channelId,  String body,  DateTime createdAt,  MessageAuthor author,  DateTime? editedAt,  DateTime? deletedAt,  List<MessageReaction> reactions,  String? parentId,  int replyCount,  DateTime? lastReplyAt,  List<MessageMention> mentions,  List<MessageAttachment> attachments,  bool pinned,  QuotedMessage? quoted,  bool pending,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.channelId,_that.body,_that.createdAt,_that.author,_that.editedAt,_that.deletedAt,_that.reactions,_that.parentId,_that.replyCount,_that.lastReplyAt,_that.mentions,_that.attachments,_that.pinned,_that.quoted,_that.pending,_that.failed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message extends Message {
  const _Message({required this.id, required this.channelId, required this.body, required this.createdAt, required this.author, this.editedAt, this.deletedAt, final  List<MessageReaction> reactions = const <MessageReaction>[], this.parentId, this.replyCount = 0, this.lastReplyAt, final  List<MessageMention> mentions = const <MessageMention>[], final  List<MessageAttachment> attachments = const <MessageAttachment>[], this.pinned = false, this.quoted, this.pending = false, this.failed = false}): _reactions = reactions,_mentions = mentions,_attachments = attachments,super._();
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String id;
@override final  String channelId;
@override final  String body;
@override final  DateTime createdAt;
@override final  MessageAuthor author;
@override final  DateTime? editedAt;
/// 소프트 삭제. 서버는 행을 지우지 않고 **본문만 비워서** 내려보낸다
/// (docs/백엔드-설계.md §3 보관 정책). 목록에서 빼지 않는 이유는,
/// 빼 버리면 클라이언트가 이미 그린 메시지를 지울 근거가 없어서다.
@override final  DateTime? deletedAt;
/// 이모지별 요약. 서버가 목록에 함께 실어 준다.
 final  List<MessageReaction> _reactions;
/// 이모지별 요약. 서버가 목록에 함께 실어 준다.
@override@JsonKey() List<MessageReaction> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}

/// 값이 있으면 스레드 답글이다. 채널 타임라인에는 나오지 않는다.
@override final  String? parentId;
/// 이 메시지에 달린 답글 수. 답글 자신은 늘 0 이다.
@override@JsonKey() final  int replyCount;
/// 마지막 답글 시각. 스레드 요약을 그릴 때 쓴다.
@override final  DateTime? lastReplyAt;
/// 이 메시지에 걸린 멘션. 본문의 `<@id>` 를 이름으로 바꾸는 데 쓴다.
 final  List<MessageMention> _mentions;
/// 이 메시지에 걸린 멘션. 본문의 `<@id>` 를 이름으로 바꾸는 데 쓴다.
@override@JsonKey() List<MessageMention> get mentions {
  if (_mentions is EqualUnmodifiableListView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentions);
}

/// 붙은 파일. **본문이 비어도 이것만 있으면 메시지가 성립한다.**
 final  List<MessageAttachment> _attachments;
/// 붙은 파일. **본문이 비어도 이것만 있으면 메시지가 성립한다.**
@override@JsonKey() List<MessageAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

/// 채널 상단에 고정됐는지. 답글은 고정할 수 없어 늘 false 다.
@override@JsonKey() final  bool pinned;
/// 답장이면 가리키는 원본. **`parentId` 와 다른 축이다** — 답장은
/// 타임라인에 남고, 스레드 답글은 빠진다. 둘을 함께 쓸 수도 있다.
@override final  QuotedMessage? quoted;
/// 낙관적 갱신용 — 서버 응답을 기다리는 중.
/// 서버 응답에는 없는 필드라 기본값 false 로 들어온다.
@override@JsonKey() final  bool pending;
/// 전송이 실패해 재시도를 기다리는 중. 역시 로컬 전용이다.
@override@JsonKey() final  bool failed;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.author, author) || other.author == author)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&const DeepCollectionEquality().equals(other._reactions, _reactions)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.lastReplyAt, lastReplyAt) || other.lastReplyAt == lastReplyAt)&&const DeepCollectionEquality().equals(other._mentions, _mentions)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.quoted, quoted) || other.quoted == quoted)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.failed, failed) || other.failed == failed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,channelId,body,createdAt,author,editedAt,deletedAt,const DeepCollectionEquality().hash(_reactions),parentId,replyCount,lastReplyAt,const DeepCollectionEquality().hash(_mentions),const DeepCollectionEquality().hash(_attachments),pinned,quoted,pending,failed);

@override
String toString() {
  return 'Message(id: $id, channelId: $channelId, body: $body, createdAt: $createdAt, author: $author, editedAt: $editedAt, deletedAt: $deletedAt, reactions: $reactions, parentId: $parentId, replyCount: $replyCount, lastReplyAt: $lastReplyAt, mentions: $mentions, attachments: $attachments, pinned: $pinned, quoted: $quoted, pending: $pending, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String channelId, String body, DateTime createdAt, MessageAuthor author, DateTime? editedAt, DateTime? deletedAt, List<MessageReaction> reactions, String? parentId, int replyCount, DateTime? lastReplyAt, List<MessageMention> mentions, List<MessageAttachment> attachments, bool pinned, QuotedMessage? quoted, bool pending, bool failed
});


@override $MessageAuthorCopyWith<$Res> get author;@override $QuotedMessageCopyWith<$Res>? get quoted;

}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? channelId = null,Object? body = null,Object? createdAt = null,Object? author = null,Object? editedAt = freezed,Object? deletedAt = freezed,Object? reactions = null,Object? parentId = freezed,Object? replyCount = null,Object? lastReplyAt = freezed,Object? mentions = null,Object? attachments = null,Object? pinned = null,Object? quoted = freezed,Object? pending = null,Object? failed = null,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as MessageAuthor,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<MessageReaction>,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,lastReplyAt: freezed == lastReplyAt ? _self.lastReplyAt : lastReplyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mentions: null == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<MessageMention>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachment>,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,quoted: freezed == quoted ? _self.quoted : quoted // ignore: cast_nullable_to_non_nullable
as QuotedMessage?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageAuthorCopyWith<$Res> get author {
  
  return $MessageAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuotedMessageCopyWith<$Res>? get quoted {
    if (_self.quoted == null) {
    return null;
  }

  return $QuotedMessageCopyWith<$Res>(_self.quoted!, (value) {
    return _then(_self.copyWith(quoted: value));
  });
}
}

// dart format on
