// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sprint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Sprint {

 String get id; String get name; String? get goal;/// 계획 단계에서는 날짜가 아직 없을 수 있다. 없으면 번다운을 그릴 수 없다.
 DateTime? get startsAt; DateTime? get endsAt; SprintState get state;
/// Create a copy of Sprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SprintCopyWith<Sprint> get copyWith => _$SprintCopyWithImpl<Sprint>(this as Sprint, _$identity);

  /// Serializes this Sprint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sprint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,goal,startsAt,endsAt,state);

@override
String toString() {
  return 'Sprint(id: $id, name: $name, goal: $goal, startsAt: $startsAt, endsAt: $endsAt, state: $state)';
}


}

/// @nodoc
abstract mixin class $SprintCopyWith<$Res>  {
  factory $SprintCopyWith(Sprint value, $Res Function(Sprint) _then) = _$SprintCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? goal, DateTime? startsAt, DateTime? endsAt, SprintState state
});




}
/// @nodoc
class _$SprintCopyWithImpl<$Res>
    implements $SprintCopyWith<$Res> {
  _$SprintCopyWithImpl(this._self, this._then);

  final Sprint _self;
  final $Res Function(Sprint) _then;

/// Create a copy of Sprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? goal = freezed,Object? startsAt = freezed,Object? endsAt = freezed,Object? state = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String?,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SprintState,
  ));
}

}


/// Adds pattern-matching-related methods to [Sprint].
extension SprintPatterns on Sprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sprint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sprint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sprint value)  $default,){
final _that = this;
switch (_that) {
case _Sprint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sprint value)?  $default,){
final _that = this;
switch (_that) {
case _Sprint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? goal,  DateTime? startsAt,  DateTime? endsAt,  SprintState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sprint() when $default != null:
return $default(_that.id,_that.name,_that.goal,_that.startsAt,_that.endsAt,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? goal,  DateTime? startsAt,  DateTime? endsAt,  SprintState state)  $default,) {final _that = this;
switch (_that) {
case _Sprint():
return $default(_that.id,_that.name,_that.goal,_that.startsAt,_that.endsAt,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? goal,  DateTime? startsAt,  DateTime? endsAt,  SprintState state)?  $default,) {final _that = this;
switch (_that) {
case _Sprint() when $default != null:
return $default(_that.id,_that.name,_that.goal,_that.startsAt,_that.endsAt,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sprint implements Sprint {
  const _Sprint({required this.id, required this.name, this.goal, this.startsAt, this.endsAt, required this.state});
  factory _Sprint.fromJson(Map<String, dynamic> json) => _$SprintFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? goal;
/// 계획 단계에서는 날짜가 아직 없을 수 있다. 없으면 번다운을 그릴 수 없다.
@override final  DateTime? startsAt;
@override final  DateTime? endsAt;
@override final  SprintState state;

/// Create a copy of Sprint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SprintCopyWith<_Sprint> get copyWith => __$SprintCopyWithImpl<_Sprint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SprintToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sprint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,goal,startsAt,endsAt,state);

@override
String toString() {
  return 'Sprint(id: $id, name: $name, goal: $goal, startsAt: $startsAt, endsAt: $endsAt, state: $state)';
}


}

/// @nodoc
abstract mixin class _$SprintCopyWith<$Res> implements $SprintCopyWith<$Res> {
  factory _$SprintCopyWith(_Sprint value, $Res Function(_Sprint) _then) = __$SprintCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? goal, DateTime? startsAt, DateTime? endsAt, SprintState state
});




}
/// @nodoc
class __$SprintCopyWithImpl<$Res>
    implements _$SprintCopyWith<$Res> {
  __$SprintCopyWithImpl(this._self, this._then);

  final _Sprint _self;
  final $Res Function(_Sprint) _then;

/// Create a copy of Sprint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? goal = freezed,Object? startsAt = freezed,Object? endsAt = freezed,Object? state = null,}) {
  return _then(_Sprint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String?,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SprintState,
  ));
}


}


/// @nodoc
mixin _$BurndownDay {

 DateTime get date; int get points; int get count;
/// Create a copy of BurndownDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BurndownDayCopyWith<BurndownDay> get copyWith => _$BurndownDayCopyWithImpl<BurndownDay>(this as BurndownDay, _$identity);

  /// Serializes this BurndownDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BurndownDay&&(identical(other.date, date) || other.date == date)&&(identical(other.points, points) || other.points == points)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,points,count);

@override
String toString() {
  return 'BurndownDay(date: $date, points: $points, count: $count)';
}


}

/// @nodoc
abstract mixin class $BurndownDayCopyWith<$Res>  {
  factory $BurndownDayCopyWith(BurndownDay value, $Res Function(BurndownDay) _then) = _$BurndownDayCopyWithImpl;
@useResult
$Res call({
 DateTime date, int points, int count
});




}
/// @nodoc
class _$BurndownDayCopyWithImpl<$Res>
    implements $BurndownDayCopyWith<$Res> {
  _$BurndownDayCopyWithImpl(this._self, this._then);

  final BurndownDay _self;
  final $Res Function(BurndownDay) _then;

/// Create a copy of BurndownDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? points = null,Object? count = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BurndownDay].
extension BurndownDayPatterns on BurndownDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BurndownDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BurndownDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BurndownDay value)  $default,){
final _that = this;
switch (_that) {
case _BurndownDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BurndownDay value)?  $default,){
final _that = this;
switch (_that) {
case _BurndownDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  int points,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BurndownDay() when $default != null:
return $default(_that.date,_that.points,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  int points,  int count)  $default,) {final _that = this;
switch (_that) {
case _BurndownDay():
return $default(_that.date,_that.points,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  int points,  int count)?  $default,) {final _that = this;
switch (_that) {
case _BurndownDay() when $default != null:
return $default(_that.date,_that.points,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BurndownDay implements BurndownDay {
  const _BurndownDay({required this.date, required this.points, required this.count});
  factory _BurndownDay.fromJson(Map<String, dynamic> json) => _$BurndownDayFromJson(json);

@override final  DateTime date;
@override final  int points;
@override final  int count;

/// Create a copy of BurndownDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BurndownDayCopyWith<_BurndownDay> get copyWith => __$BurndownDayCopyWithImpl<_BurndownDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BurndownDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BurndownDay&&(identical(other.date, date) || other.date == date)&&(identical(other.points, points) || other.points == points)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,points,count);

@override
String toString() {
  return 'BurndownDay(date: $date, points: $points, count: $count)';
}


}

/// @nodoc
abstract mixin class _$BurndownDayCopyWith<$Res> implements $BurndownDayCopyWith<$Res> {
  factory _$BurndownDayCopyWith(_BurndownDay value, $Res Function(_BurndownDay) _then) = __$BurndownDayCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, int points, int count
});




}
/// @nodoc
class __$BurndownDayCopyWithImpl<$Res>
    implements _$BurndownDayCopyWith<$Res> {
  __$BurndownDayCopyWithImpl(this._self, this._then);

  final _BurndownDay _self;
  final $Res Function(_BurndownDay) _then;

/// Create a copy of BurndownDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? points = null,Object? count = null,}) {
  return _then(_BurndownDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$BurndownTotal {

 int get points; int get count;
/// Create a copy of BurndownTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BurndownTotalCopyWith<BurndownTotal> get copyWith => _$BurndownTotalCopyWithImpl<BurndownTotal>(this as BurndownTotal, _$identity);

  /// Serializes this BurndownTotal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BurndownTotal&&(identical(other.points, points) || other.points == points)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,points,count);

@override
String toString() {
  return 'BurndownTotal(points: $points, count: $count)';
}


}

/// @nodoc
abstract mixin class $BurndownTotalCopyWith<$Res>  {
  factory $BurndownTotalCopyWith(BurndownTotal value, $Res Function(BurndownTotal) _then) = _$BurndownTotalCopyWithImpl;
@useResult
$Res call({
 int points, int count
});




}
/// @nodoc
class _$BurndownTotalCopyWithImpl<$Res>
    implements $BurndownTotalCopyWith<$Res> {
  _$BurndownTotalCopyWithImpl(this._self, this._then);

  final BurndownTotal _self;
  final $Res Function(BurndownTotal) _then;

/// Create a copy of BurndownTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,Object? count = null,}) {
  return _then(_self.copyWith(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BurndownTotal].
extension BurndownTotalPatterns on BurndownTotal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BurndownTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BurndownTotal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BurndownTotal value)  $default,){
final _that = this;
switch (_that) {
case _BurndownTotal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BurndownTotal value)?  $default,){
final _that = this;
switch (_that) {
case _BurndownTotal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int points,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BurndownTotal() when $default != null:
return $default(_that.points,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int points,  int count)  $default,) {final _that = this;
switch (_that) {
case _BurndownTotal():
return $default(_that.points,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int points,  int count)?  $default,) {final _that = this;
switch (_that) {
case _BurndownTotal() when $default != null:
return $default(_that.points,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BurndownTotal implements BurndownTotal {
  const _BurndownTotal({required this.points, required this.count});
  factory _BurndownTotal.fromJson(Map<String, dynamic> json) => _$BurndownTotalFromJson(json);

@override final  int points;
@override final  int count;

/// Create a copy of BurndownTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BurndownTotalCopyWith<_BurndownTotal> get copyWith => __$BurndownTotalCopyWithImpl<_BurndownTotal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BurndownTotalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BurndownTotal&&(identical(other.points, points) || other.points == points)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,points,count);

@override
String toString() {
  return 'BurndownTotal(points: $points, count: $count)';
}


}

/// @nodoc
abstract mixin class _$BurndownTotalCopyWith<$Res> implements $BurndownTotalCopyWith<$Res> {
  factory _$BurndownTotalCopyWith(_BurndownTotal value, $Res Function(_BurndownTotal) _then) = __$BurndownTotalCopyWithImpl;
@override @useResult
$Res call({
 int points, int count
});




}
/// @nodoc
class __$BurndownTotalCopyWithImpl<$Res>
    implements _$BurndownTotalCopyWith<$Res> {
  __$BurndownTotalCopyWithImpl(this._self, this._then);

  final _BurndownTotal _self;
  final $Res Function(_BurndownTotal) _then;

/// Create a copy of BurndownTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,Object? count = null,}) {
  return _then(_BurndownTotal(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Burndown {

 String get sprintId; DateTime get startsAt; DateTime get endsAt; BurndownTotal get total; List<BurndownDay> get days;
/// Create a copy of Burndown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BurndownCopyWith<Burndown> get copyWith => _$BurndownCopyWithImpl<Burndown>(this as Burndown, _$identity);

  /// Serializes this Burndown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Burndown&&(identical(other.sprintId, sprintId) || other.sprintId == sprintId)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.days, days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sprintId,startsAt,endsAt,total,const DeepCollectionEquality().hash(days));

@override
String toString() {
  return 'Burndown(sprintId: $sprintId, startsAt: $startsAt, endsAt: $endsAt, total: $total, days: $days)';
}


}

/// @nodoc
abstract mixin class $BurndownCopyWith<$Res>  {
  factory $BurndownCopyWith(Burndown value, $Res Function(Burndown) _then) = _$BurndownCopyWithImpl;
@useResult
$Res call({
 String sprintId, DateTime startsAt, DateTime endsAt, BurndownTotal total, List<BurndownDay> days
});


$BurndownTotalCopyWith<$Res> get total;

}
/// @nodoc
class _$BurndownCopyWithImpl<$Res>
    implements $BurndownCopyWith<$Res> {
  _$BurndownCopyWithImpl(this._self, this._then);

  final Burndown _self;
  final $Res Function(Burndown) _then;

/// Create a copy of Burndown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sprintId = null,Object? startsAt = null,Object? endsAt = null,Object? total = null,Object? days = null,}) {
  return _then(_self.copyWith(
sprintId: null == sprintId ? _self.sprintId : sprintId // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as BurndownTotal,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<BurndownDay>,
  ));
}
/// Create a copy of Burndown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BurndownTotalCopyWith<$Res> get total {
  
  return $BurndownTotalCopyWith<$Res>(_self.total, (value) {
    return _then(_self.copyWith(total: value));
  });
}
}


/// Adds pattern-matching-related methods to [Burndown].
extension BurndownPatterns on Burndown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Burndown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Burndown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Burndown value)  $default,){
final _that = this;
switch (_that) {
case _Burndown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Burndown value)?  $default,){
final _that = this;
switch (_that) {
case _Burndown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sprintId,  DateTime startsAt,  DateTime endsAt,  BurndownTotal total,  List<BurndownDay> days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Burndown() when $default != null:
return $default(_that.sprintId,_that.startsAt,_that.endsAt,_that.total,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sprintId,  DateTime startsAt,  DateTime endsAt,  BurndownTotal total,  List<BurndownDay> days)  $default,) {final _that = this;
switch (_that) {
case _Burndown():
return $default(_that.sprintId,_that.startsAt,_that.endsAt,_that.total,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sprintId,  DateTime startsAt,  DateTime endsAt,  BurndownTotal total,  List<BurndownDay> days)?  $default,) {final _that = this;
switch (_that) {
case _Burndown() when $default != null:
return $default(_that.sprintId,_that.startsAt,_that.endsAt,_that.total,_that.days);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Burndown implements Burndown {
  const _Burndown({required this.sprintId, required this.startsAt, required this.endsAt, required this.total, required final  List<BurndownDay> days}): _days = days;
  factory _Burndown.fromJson(Map<String, dynamic> json) => _$BurndownFromJson(json);

@override final  String sprintId;
@override final  DateTime startsAt;
@override final  DateTime endsAt;
@override final  BurndownTotal total;
 final  List<BurndownDay> _days;
@override List<BurndownDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}


/// Create a copy of Burndown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BurndownCopyWith<_Burndown> get copyWith => __$BurndownCopyWithImpl<_Burndown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BurndownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Burndown&&(identical(other.sprintId, sprintId) || other.sprintId == sprintId)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._days, _days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sprintId,startsAt,endsAt,total,const DeepCollectionEquality().hash(_days));

@override
String toString() {
  return 'Burndown(sprintId: $sprintId, startsAt: $startsAt, endsAt: $endsAt, total: $total, days: $days)';
}


}

/// @nodoc
abstract mixin class _$BurndownCopyWith<$Res> implements $BurndownCopyWith<$Res> {
  factory _$BurndownCopyWith(_Burndown value, $Res Function(_Burndown) _then) = __$BurndownCopyWithImpl;
@override @useResult
$Res call({
 String sprintId, DateTime startsAt, DateTime endsAt, BurndownTotal total, List<BurndownDay> days
});


@override $BurndownTotalCopyWith<$Res> get total;

}
/// @nodoc
class __$BurndownCopyWithImpl<$Res>
    implements _$BurndownCopyWith<$Res> {
  __$BurndownCopyWithImpl(this._self, this._then);

  final _Burndown _self;
  final $Res Function(_Burndown) _then;

/// Create a copy of Burndown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sprintId = null,Object? startsAt = null,Object? endsAt = null,Object? total = null,Object? days = null,}) {
  return _then(_Burndown(
sprintId: null == sprintId ? _self.sprintId : sprintId // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as BurndownTotal,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<BurndownDay>,
  ));
}

/// Create a copy of Burndown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BurndownTotalCopyWith<$Res> get total {
  
  return $BurndownTotalCopyWith<$Res>(_self.total, (value) {
    return _then(_self.copyWith(total: value));
  });
}
}

// dart format on
