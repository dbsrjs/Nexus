// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedMessagesTable extends CachedMessages
    with TableInfo<$CachedMessagesTable, CachedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spaceIdMeta = const VerificationMeta(
    'spaceId',
  );
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
    'space_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedMessagesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> editedAt =
      GeneratedColumn<int>(
        'edited_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CachedMessagesTable.$convertereditedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CachedMessagesTable.$converterdeletedAtn);
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorAvatarUrlMeta = const VerificationMeta(
    'authorAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> authorAvatarUrl = GeneratedColumn<String>(
    'author_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    spaceId,
    channelId,
    body,
    createdAt,
    editedAt,
    deletedAt,
    authorId,
    authorName,
    authorAvatarUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(
        _spaceIdMeta,
        spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spaceIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('author_avatar_url')) {
      context.handle(
        _authorAvatarUrlMeta,
        authorAvatarUrl.isAcceptableOrUnknown(
          data['author_avatar_url']!,
          _authorAvatarUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      spaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: $CachedMessagesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      editedAt: $CachedMessagesTable.$convertereditedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}edited_at'],
        ),
      ),
      deletedAt: $CachedMessagesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      authorAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_avatar_url'],
      ),
    );
  }

  @override
  $CachedMessagesTable createAlias(String alias) {
    return $CachedMessagesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const _UtcMicros();
  static TypeConverter<DateTime, int> $convertereditedAt = const _UtcMicros();
  static TypeConverter<DateTime?, int?> $convertereditedAtn =
      NullAwareTypeConverter.wrap($convertereditedAt);
  static TypeConverter<DateTime, int> $converterdeletedAt = const _UtcMicros();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class CachedMessage extends DataClass implements Insertable<CachedMessage> {
  final String id;
  final String spaceId;
  final String channelId;
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  const CachedMessage({
    required this.id,
    required this.spaceId,
    required this.channelId,
    required this.body,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['space_id'] = Variable<String>(spaceId);
    map['channel_id'] = Variable<String>(channelId);
    map['body'] = Variable<String>(body);
    {
      map['created_at'] = Variable<int>(
        $CachedMessagesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(
        $CachedMessagesTable.$convertereditedAtn.toSql(editedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $CachedMessagesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    map['author_id'] = Variable<String>(authorId);
    map['author_name'] = Variable<String>(authorName);
    if (!nullToAbsent || authorAvatarUrl != null) {
      map['author_avatar_url'] = Variable<String>(authorAvatarUrl);
    }
    return map;
  }

  CachedMessagesCompanion toCompanion(bool nullToAbsent) {
    return CachedMessagesCompanion(
      id: Value(id),
      spaceId: Value(spaceId),
      channelId: Value(channelId),
      body: Value(body),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      authorId: Value(authorId),
      authorName: Value(authorName),
      authorAvatarUrl: authorAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(authorAvatarUrl),
    );
  }

  factory CachedMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessage(
      id: serializer.fromJson<String>(json['id']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      authorId: serializer.fromJson<String>(json['authorId']),
      authorName: serializer.fromJson<String>(json['authorName']),
      authorAvatarUrl: serializer.fromJson<String?>(json['authorAvatarUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spaceId': serializer.toJson<String>(spaceId),
      'channelId': serializer.toJson<String>(channelId),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'authorId': serializer.toJson<String>(authorId),
      'authorName': serializer.toJson<String>(authorName),
      'authorAvatarUrl': serializer.toJson<String?>(authorAvatarUrl),
    };
  }

  CachedMessage copyWith({
    String? id,
    String? spaceId,
    String? channelId,
    String? body,
    DateTime? createdAt,
    Value<DateTime?> editedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? authorId,
    String? authorName,
    Value<String?> authorAvatarUrl = const Value.absent(),
  }) => CachedMessage(
    id: id ?? this.id,
    spaceId: spaceId ?? this.spaceId,
    channelId: channelId ?? this.channelId,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    authorAvatarUrl: authorAvatarUrl.present
        ? authorAvatarUrl.value
        : this.authorAvatarUrl,
  );
  CachedMessage copyWithCompanion(CachedMessagesCompanion data) {
    return CachedMessage(
      id: data.id.present ? data.id.value : this.id,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      authorAvatarUrl: data.authorAvatarUrl.present
          ? data.authorAvatarUrl.value
          : this.authorAvatarUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessage(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('channelId: $channelId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('authorAvatarUrl: $authorAvatarUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    spaceId,
    channelId,
    body,
    createdAt,
    editedAt,
    deletedAt,
    authorId,
    authorName,
    authorAvatarUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessage &&
          other.id == this.id &&
          other.spaceId == this.spaceId &&
          other.channelId == this.channelId &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt &&
          other.authorId == this.authorId &&
          other.authorName == this.authorName &&
          other.authorAvatarUrl == this.authorAvatarUrl);
}

class CachedMessagesCompanion extends UpdateCompanion<CachedMessage> {
  final Value<String> id;
  final Value<String> spaceId;
  final Value<String> channelId;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime?> editedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> authorId;
  final Value<String> authorName;
  final Value<String?> authorAvatarUrl;
  final Value<int> rowid;
  const CachedMessagesCompanion({
    this.id = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.authorAvatarUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMessagesCompanion.insert({
    required String id,
    required String spaceId,
    required String channelId,
    required String body,
    required DateTime createdAt,
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String authorId,
    required String authorName,
    this.authorAvatarUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       spaceId = Value(spaceId),
       channelId = Value(channelId),
       body = Value(body),
       createdAt = Value(createdAt),
       authorId = Value(authorId),
       authorName = Value(authorName);
  static Insertable<CachedMessage> custom({
    Expression<String>? id,
    Expression<String>? spaceId,
    Expression<String>? channelId,
    Expression<String>? body,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<int>? deletedAt,
    Expression<String>? authorId,
    Expression<String>? authorName,
    Expression<String>? authorAvatarUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spaceId != null) 'space_id': spaceId,
      if (channelId != null) 'channel_id': channelId,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (authorId != null) 'author_id': authorId,
      if (authorName != null) 'author_name': authorName,
      if (authorAvatarUrl != null) 'author_avatar_url': authorAvatarUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? spaceId,
    Value<String>? channelId,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime?>? editedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? authorId,
    Value<String>? authorName,
    Value<String?>? authorAvatarUrl,
    Value<int>? rowid,
  }) {
    return CachedMessagesCompanion(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      channelId: channelId ?? this.channelId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CachedMessagesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(
        $CachedMessagesTable.$convertereditedAtn.toSql(editedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $CachedMessagesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (authorAvatarUrl.present) {
      map['author_avatar_url'] = Variable<String>(authorAvatarUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesCompanion(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('channelId: $channelId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('authorAvatarUrl: $authorAvatarUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedChannelsTable extends CachedChannels
    with TableInfo<$CachedChannelsTable, CachedChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spaceIdMeta = const VerificationMeta(
    'spaceId',
  );
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
    'space_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrivateMeta = const VerificationMeta(
    'isPrivate',
  );
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
    'is_private',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    spaceId,
    key,
    name,
    topic,
    categoryId,
    isPrivate,
    position,
    unreadCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(
        _spaceIdMeta,
        spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spaceIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('is_private')) {
      context.handle(
        _isPrivateMeta,
        isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedChannel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      spaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      isPrivate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_private'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
    );
  }

  @override
  $CachedChannelsTable createAlias(String alias) {
    return $CachedChannelsTable(attachedDatabase, alias);
  }
}

class CachedChannel extends DataClass implements Insertable<CachedChannel> {
  final String id;
  final String spaceId;
  final String key;
  final String name;
  final String? topic;
  final String? categoryId;
  final bool isPrivate;
  final int position;
  final int unreadCount;
  const CachedChannel({
    required this.id,
    required this.spaceId,
    required this.key,
    required this.name,
    this.topic,
    this.categoryId,
    required this.isPrivate,
    required this.position,
    required this.unreadCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['space_id'] = Variable<String>(spaceId);
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['is_private'] = Variable<bool>(isPrivate);
    map['position'] = Variable<int>(position);
    map['unread_count'] = Variable<int>(unreadCount);
    return map;
  }

  CachedChannelsCompanion toCompanion(bool nullToAbsent) {
    return CachedChannelsCompanion(
      id: Value(id),
      spaceId: Value(spaceId),
      key: Value(key),
      name: Value(name),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      isPrivate: Value(isPrivate),
      position: Value(position),
      unreadCount: Value(unreadCount),
    );
  }

  factory CachedChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedChannel(
      id: serializer.fromJson<String>(json['id']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      topic: serializer.fromJson<String?>(json['topic']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      position: serializer.fromJson<int>(json['position']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spaceId': serializer.toJson<String>(spaceId),
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'topic': serializer.toJson<String?>(topic),
      'categoryId': serializer.toJson<String?>(categoryId),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'position': serializer.toJson<int>(position),
      'unreadCount': serializer.toJson<int>(unreadCount),
    };
  }

  CachedChannel copyWith({
    String? id,
    String? spaceId,
    String? key,
    String? name,
    Value<String?> topic = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    bool? isPrivate,
    int? position,
    int? unreadCount,
  }) => CachedChannel(
    id: id ?? this.id,
    spaceId: spaceId ?? this.spaceId,
    key: key ?? this.key,
    name: name ?? this.name,
    topic: topic.present ? topic.value : this.topic,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    isPrivate: isPrivate ?? this.isPrivate,
    position: position ?? this.position,
    unreadCount: unreadCount ?? this.unreadCount,
  );
  CachedChannel copyWithCompanion(CachedChannelsCompanion data) {
    return CachedChannel(
      id: data.id.present ? data.id.value : this.id,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      topic: data.topic.present ? data.topic.value : this.topic,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      position: data.position.present ? data.position.value : this.position,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannel(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('topic: $topic, ')
          ..write('categoryId: $categoryId, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('position: $position, ')
          ..write('unreadCount: $unreadCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    spaceId,
    key,
    name,
    topic,
    categoryId,
    isPrivate,
    position,
    unreadCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedChannel &&
          other.id == this.id &&
          other.spaceId == this.spaceId &&
          other.key == this.key &&
          other.name == this.name &&
          other.topic == this.topic &&
          other.categoryId == this.categoryId &&
          other.isPrivate == this.isPrivate &&
          other.position == this.position &&
          other.unreadCount == this.unreadCount);
}

class CachedChannelsCompanion extends UpdateCompanion<CachedChannel> {
  final Value<String> id;
  final Value<String> spaceId;
  final Value<String> key;
  final Value<String> name;
  final Value<String?> topic;
  final Value<String?> categoryId;
  final Value<bool> isPrivate;
  final Value<int> position;
  final Value<int> unreadCount;
  final Value<int> rowid;
  const CachedChannelsCompanion({
    this.id = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.topic = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.position = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedChannelsCompanion.insert({
    required String id,
    required String spaceId,
    required String key,
    required String name,
    this.topic = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.position = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       spaceId = Value(spaceId),
       key = Value(key),
       name = Value(name);
  static Insertable<CachedChannel> custom({
    Expression<String>? id,
    Expression<String>? spaceId,
    Expression<String>? key,
    Expression<String>? name,
    Expression<String>? topic,
    Expression<String>? categoryId,
    Expression<bool>? isPrivate,
    Expression<int>? position,
    Expression<int>? unreadCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spaceId != null) 'space_id': spaceId,
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (topic != null) 'topic': topic,
      if (categoryId != null) 'category_id': categoryId,
      if (isPrivate != null) 'is_private': isPrivate,
      if (position != null) 'position': position,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedChannelsCompanion copyWith({
    Value<String>? id,
    Value<String>? spaceId,
    Value<String>? key,
    Value<String>? name,
    Value<String?>? topic,
    Value<String?>? categoryId,
    Value<bool>? isPrivate,
    Value<int>? position,
    Value<int>? unreadCount,
    Value<int>? rowid,
  }) {
    return CachedChannelsCompanion(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      key: key ?? this.key,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      categoryId: categoryId ?? this.categoryId,
      isPrivate: isPrivate ?? this.isPrivate,
      position: position ?? this.position,
      unreadCount: unreadCount ?? this.unreadCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannelsCompanion(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('topic: $topic, ')
          ..write('categoryId: $categoryId, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('position: $position, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCategoriesTable extends CachedCategories
    with TableInfo<$CachedCategoriesTable, CachedCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spaceIdMeta = const VerificationMeta(
    'spaceId',
  );
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
    'space_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, spaceId, name, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(
        _spaceIdMeta,
        spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      spaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedCategoriesTable createAlias(String alias) {
    return $CachedCategoriesTable(attachedDatabase, alias);
  }
}

class CachedCategory extends DataClass implements Insertable<CachedCategory> {
  final String id;
  final String spaceId;
  final String name;
  final int position;
  const CachedCategory({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['space_id'] = Variable<String>(spaceId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedCategoriesCompanion(
      id: Value(id),
      spaceId: Value(spaceId),
      name: Value(name),
      position: Value(position),
    );
  }

  factory CachedCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCategory(
      id: serializer.fromJson<String>(json['id']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spaceId': serializer.toJson<String>(spaceId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedCategory copyWith({
    String? id,
    String? spaceId,
    String? name,
    int? position,
  }) => CachedCategory(
    id: id ?? this.id,
    spaceId: spaceId ?? this.spaceId,
    name: name ?? this.name,
    position: position ?? this.position,
  );
  CachedCategory copyWithCompanion(CachedCategoriesCompanion data) {
    return CachedCategory(
      id: data.id.present ? data.id.value : this.id,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategory(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, spaceId, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCategory &&
          other.id == this.id &&
          other.spaceId == this.spaceId &&
          other.name == this.name &&
          other.position == this.position);
}

class CachedCategoriesCompanion extends UpdateCompanion<CachedCategory> {
  final Value<String> id;
  final Value<String> spaceId;
  final Value<String> name;
  final Value<int> position;
  final Value<int> rowid;
  const CachedCategoriesCompanion({
    this.id = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCategoriesCompanion.insert({
    required String id,
    required String spaceId,
    required String name,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       spaceId = Value(spaceId),
       name = Value(name);
  static Insertable<CachedCategory> custom({
    Expression<String>? id,
    Expression<String>? spaceId,
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spaceId != null) 'space_id': spaceId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? spaceId,
    Value<String>? name,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedCategoriesCompanion(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      name: name ?? this.name,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSpacesTable extends CachedSpaces
    with TableInfo<$CachedSpacesTable, CachedSpace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSpacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, slug, name, role, iconUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_spaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSpace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSpace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSpace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
    );
  }

  @override
  $CachedSpacesTable createAlias(String alias) {
    return $CachedSpacesTable(attachedDatabase, alias);
  }
}

class CachedSpace extends DataClass implements Insertable<CachedSpace> {
  final String id;
  final String slug;
  final String name;
  final String role;
  final String? iconUrl;
  const CachedSpace({
    required this.id,
    required this.slug,
    required this.name,
    required this.role,
    this.iconUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slug'] = Variable<String>(slug);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    return map;
  }

  CachedSpacesCompanion toCompanion(bool nullToAbsent) {
    return CachedSpacesCompanion(
      id: Value(id),
      slug: Value(slug),
      name: Value(name),
      role: Value(role),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
    );
  }

  factory CachedSpace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSpace(
      id: serializer.fromJson<String>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slug': serializer.toJson<String>(slug),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'iconUrl': serializer.toJson<String?>(iconUrl),
    };
  }

  CachedSpace copyWith({
    String? id,
    String? slug,
    String? name,
    String? role,
    Value<String?> iconUrl = const Value.absent(),
  }) => CachedSpace(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    name: name ?? this.name,
    role: role ?? this.role,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
  );
  CachedSpace copyWithCompanion(CachedSpacesCompanion data) {
    return CachedSpace(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSpace(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('iconUrl: $iconUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug, name, role, iconUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSpace &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.name == this.name &&
          other.role == this.role &&
          other.iconUrl == this.iconUrl);
}

class CachedSpacesCompanion extends UpdateCompanion<CachedSpace> {
  final Value<String> id;
  final Value<String> slug;
  final Value<String> name;
  final Value<String> role;
  final Value<String?> iconUrl;
  final Value<int> rowid;
  const CachedSpacesCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSpacesCompanion.insert({
    required String id,
    required String slug,
    required String name,
    required String role,
    this.iconUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slug = Value(slug),
       name = Value(name),
       role = Value(role);
  static Insertable<CachedSpace> custom({
    Expression<String>? id,
    Expression<String>? slug,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? iconUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSpacesCompanion copyWith({
    Value<String>? id,
    Value<String>? slug,
    Value<String>? name,
    Value<String>? role,
    Value<String?>? iconUrl,
    Value<int>? rowid,
  }) {
    return CachedSpacesCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      role: role ?? this.role,
      iconUrl: iconUrl ?? this.iconUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSpacesCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxMessagesTable extends OutboxMessages
    with TableInfo<$OutboxMessagesTable, OutboxMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spaceIdMeta = const VerificationMeta(
    'spaceId',
  );
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
    'space_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($OutboxMessagesTable.$convertercreatedAt);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorAvatarUrlMeta = const VerificationMeta(
    'authorAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> authorAvatarUrl = GeneratedColumn<String>(
    'author_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _failedMeta = const VerificationMeta('failed');
  @override
  late final GeneratedColumn<bool> failed = GeneratedColumn<bool>(
    'failed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("failed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastFailureMeta = const VerificationMeta(
    'lastFailure',
  );
  @override
  late final GeneratedColumn<String> lastFailure = GeneratedColumn<String>(
    'last_failure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    spaceId,
    channelId,
    body,
    createdAt,
    seq,
    authorId,
    authorName,
    authorAvatarUrl,
    attempts,
    failed,
    lastFailure,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(
        _spaceIdMeta,
        spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spaceIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('author_avatar_url')) {
      context.handle(
        _authorAvatarUrlMeta,
        authorAvatarUrl.isAcceptableOrUnknown(
          data['author_avatar_url']!,
          _authorAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('failed')) {
      context.handle(
        _failedMeta,
        failed.isAcceptableOrUnknown(data['failed']!, _failedMeta),
      );
    }
    if (data.containsKey('last_failure')) {
      context.handle(
        _lastFailureMeta,
        lastFailure.isAcceptableOrUnknown(
          data['last_failure']!,
          _lastFailureMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      spaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: $OutboxMessagesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      authorAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_avatar_url'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      failed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}failed'],
      )!,
      lastFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_failure'],
      ),
    );
  }

  @override
  $OutboxMessagesTable createAlias(String alias) {
    return $OutboxMessagesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const _UtcMicros();
}

class OutboxMessage extends DataClass implements Insertable<OutboxMessage> {
  /// 로컬에서 만든 임시 id(`local-…`). 전송에 성공하면 서버 id 로 대체된다.
  final String id;
  final String spaceId;
  final String channelId;
  final String body;

  /// 사용자가 **쓴** 시각. 서버 도착 시각이 아니다.
  final DateTime createdAt;

  /// 큐에 들어온 순서. **전송 순서는 시각이 아니라 이 값이 정한다.**
  ///
  /// 시각으로 정렬하면 안 되는 이유: Windows 의 `DateTime.now()` 는 밀리초
  /// 해상도라, 연속으로 보낸 메시지 여러 건이 **완전히 같은 값**을 갖는다.
  /// 그러면 순서가 tie-break 에 맡겨지고 실제로 뒤집혔다(테스트가 15회 중
  /// 5회 실패했다). 삽입 순서는 저장해 두어야 확실하다.
  final int seq;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final int attempts;

  /// 자동 재시도를 포기한 상태. 사용자가 재시도하거나 버릴 때까지 남는다.
  /// **조용히 지우지 않는다** — 사라지면 사용자는 보냈다고 믿는다.
  final bool failed;

  /// 마지막 실패 종류(`ApiFailure` 의 이름). 진단용이며 화면 문구는 앱이 정한다.
  final String? lastFailure;
  const OutboxMessage({
    required this.id,
    required this.spaceId,
    required this.channelId,
    required this.body,
    required this.createdAt,
    required this.seq,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.attempts,
    required this.failed,
    this.lastFailure,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['space_id'] = Variable<String>(spaceId);
    map['channel_id'] = Variable<String>(channelId);
    map['body'] = Variable<String>(body);
    {
      map['created_at'] = Variable<int>(
        $OutboxMessagesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['seq'] = Variable<int>(seq);
    map['author_id'] = Variable<String>(authorId);
    map['author_name'] = Variable<String>(authorName);
    if (!nullToAbsent || authorAvatarUrl != null) {
      map['author_avatar_url'] = Variable<String>(authorAvatarUrl);
    }
    map['attempts'] = Variable<int>(attempts);
    map['failed'] = Variable<bool>(failed);
    if (!nullToAbsent || lastFailure != null) {
      map['last_failure'] = Variable<String>(lastFailure);
    }
    return map;
  }

  OutboxMessagesCompanion toCompanion(bool nullToAbsent) {
    return OutboxMessagesCompanion(
      id: Value(id),
      spaceId: Value(spaceId),
      channelId: Value(channelId),
      body: Value(body),
      createdAt: Value(createdAt),
      seq: Value(seq),
      authorId: Value(authorId),
      authorName: Value(authorName),
      authorAvatarUrl: authorAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(authorAvatarUrl),
      attempts: Value(attempts),
      failed: Value(failed),
      lastFailure: lastFailure == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailure),
    );
  }

  factory OutboxMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxMessage(
      id: serializer.fromJson<String>(json['id']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      seq: serializer.fromJson<int>(json['seq']),
      authorId: serializer.fromJson<String>(json['authorId']),
      authorName: serializer.fromJson<String>(json['authorName']),
      authorAvatarUrl: serializer.fromJson<String?>(json['authorAvatarUrl']),
      attempts: serializer.fromJson<int>(json['attempts']),
      failed: serializer.fromJson<bool>(json['failed']),
      lastFailure: serializer.fromJson<String?>(json['lastFailure']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spaceId': serializer.toJson<String>(spaceId),
      'channelId': serializer.toJson<String>(channelId),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'seq': serializer.toJson<int>(seq),
      'authorId': serializer.toJson<String>(authorId),
      'authorName': serializer.toJson<String>(authorName),
      'authorAvatarUrl': serializer.toJson<String?>(authorAvatarUrl),
      'attempts': serializer.toJson<int>(attempts),
      'failed': serializer.toJson<bool>(failed),
      'lastFailure': serializer.toJson<String?>(lastFailure),
    };
  }

  OutboxMessage copyWith({
    String? id,
    String? spaceId,
    String? channelId,
    String? body,
    DateTime? createdAt,
    int? seq,
    String? authorId,
    String? authorName,
    Value<String?> authorAvatarUrl = const Value.absent(),
    int? attempts,
    bool? failed,
    Value<String?> lastFailure = const Value.absent(),
  }) => OutboxMessage(
    id: id ?? this.id,
    spaceId: spaceId ?? this.spaceId,
    channelId: channelId ?? this.channelId,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    seq: seq ?? this.seq,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    authorAvatarUrl: authorAvatarUrl.present
        ? authorAvatarUrl.value
        : this.authorAvatarUrl,
    attempts: attempts ?? this.attempts,
    failed: failed ?? this.failed,
    lastFailure: lastFailure.present ? lastFailure.value : this.lastFailure,
  );
  OutboxMessage copyWithCompanion(OutboxMessagesCompanion data) {
    return OutboxMessage(
      id: data.id.present ? data.id.value : this.id,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      seq: data.seq.present ? data.seq.value : this.seq,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      authorAvatarUrl: data.authorAvatarUrl.present
          ? data.authorAvatarUrl.value
          : this.authorAvatarUrl,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      failed: data.failed.present ? data.failed.value : this.failed,
      lastFailure: data.lastFailure.present
          ? data.lastFailure.value
          : this.lastFailure,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxMessage(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('channelId: $channelId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('seq: $seq, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('authorAvatarUrl: $authorAvatarUrl, ')
          ..write('attempts: $attempts, ')
          ..write('failed: $failed, ')
          ..write('lastFailure: $lastFailure')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    spaceId,
    channelId,
    body,
    createdAt,
    seq,
    authorId,
    authorName,
    authorAvatarUrl,
    attempts,
    failed,
    lastFailure,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxMessage &&
          other.id == this.id &&
          other.spaceId == this.spaceId &&
          other.channelId == this.channelId &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.seq == this.seq &&
          other.authorId == this.authorId &&
          other.authorName == this.authorName &&
          other.authorAvatarUrl == this.authorAvatarUrl &&
          other.attempts == this.attempts &&
          other.failed == this.failed &&
          other.lastFailure == this.lastFailure);
}

class OutboxMessagesCompanion extends UpdateCompanion<OutboxMessage> {
  final Value<String> id;
  final Value<String> spaceId;
  final Value<String> channelId;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<int> seq;
  final Value<String> authorId;
  final Value<String> authorName;
  final Value<String?> authorAvatarUrl;
  final Value<int> attempts;
  final Value<bool> failed;
  final Value<String?> lastFailure;
  final Value<int> rowid;
  const OutboxMessagesCompanion({
    this.id = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.authorAvatarUrl = const Value.absent(),
    this.attempts = const Value.absent(),
    this.failed = const Value.absent(),
    this.lastFailure = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxMessagesCompanion.insert({
    required String id,
    required String spaceId,
    required String channelId,
    required String body,
    required DateTime createdAt,
    this.seq = const Value.absent(),
    required String authorId,
    required String authorName,
    this.authorAvatarUrl = const Value.absent(),
    this.attempts = const Value.absent(),
    this.failed = const Value.absent(),
    this.lastFailure = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       spaceId = Value(spaceId),
       channelId = Value(channelId),
       body = Value(body),
       createdAt = Value(createdAt),
       authorId = Value(authorId),
       authorName = Value(authorName);
  static Insertable<OutboxMessage> custom({
    Expression<String>? id,
    Expression<String>? spaceId,
    Expression<String>? channelId,
    Expression<String>? body,
    Expression<int>? createdAt,
    Expression<int>? seq,
    Expression<String>? authorId,
    Expression<String>? authorName,
    Expression<String>? authorAvatarUrl,
    Expression<int>? attempts,
    Expression<bool>? failed,
    Expression<String>? lastFailure,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spaceId != null) 'space_id': spaceId,
      if (channelId != null) 'channel_id': channelId,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (seq != null) 'seq': seq,
      if (authorId != null) 'author_id': authorId,
      if (authorName != null) 'author_name': authorName,
      if (authorAvatarUrl != null) 'author_avatar_url': authorAvatarUrl,
      if (attempts != null) 'attempts': attempts,
      if (failed != null) 'failed': failed,
      if (lastFailure != null) 'last_failure': lastFailure,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? spaceId,
    Value<String>? channelId,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<int>? seq,
    Value<String>? authorId,
    Value<String>? authorName,
    Value<String?>? authorAvatarUrl,
    Value<int>? attempts,
    Value<bool>? failed,
    Value<String?>? lastFailure,
    Value<int>? rowid,
  }) {
    return OutboxMessagesCompanion(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      channelId: channelId ?? this.channelId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      seq: seq ?? this.seq,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      attempts: attempts ?? this.attempts,
      failed: failed ?? this.failed,
      lastFailure: lastFailure ?? this.lastFailure,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $OutboxMessagesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (authorAvatarUrl.present) {
      map['author_avatar_url'] = Variable<String>(authorAvatarUrl.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (failed.present) {
      map['failed'] = Variable<bool>(failed.value);
    }
    if (lastFailure.present) {
      map['last_failure'] = Variable<String>(lastFailure.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxMessagesCompanion(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('channelId: $channelId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('seq: $seq, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('authorAvatarUrl: $authorAvatarUrl, ')
          ..write('attempts: $attempts, ')
          ..write('failed: $failed, ')
          ..write('lastFailure: $lastFailure, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedMessagesTable cachedMessages = $CachedMessagesTable(this);
  late final $CachedChannelsTable cachedChannels = $CachedChannelsTable(this);
  late final $CachedCategoriesTable cachedCategories = $CachedCategoriesTable(
    this,
  );
  late final $CachedSpacesTable cachedSpaces = $CachedSpacesTable(this);
  late final $OutboxMessagesTable outboxMessages = $OutboxMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedMessages,
    cachedChannels,
    cachedCategories,
    cachedSpaces,
    outboxMessages,
  ];
}

typedef $$CachedMessagesTableCreateCompanionBuilder =
    CachedMessagesCompanion Function({
      required String id,
      required String spaceId,
      required String channelId,
      required String body,
      required DateTime createdAt,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      required String authorId,
      required String authorName,
      Value<String?> authorAvatarUrl,
      Value<int> rowid,
    });
typedef $$CachedMessagesTableUpdateCompanionBuilder =
    CachedMessagesCompanion Function({
      Value<String> id,
      Value<String> spaceId,
      Value<String> channelId,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      Value<String> authorId,
      Value<String> authorName,
      Value<String?> authorAvatarUrl,
      Value<int> rowid,
    });

class $$CachedMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get editedAt =>
      $composableBuilder(
        column: $table.editedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => column,
  );
}

class $$CachedMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMessagesTable,
          CachedMessage,
          $$CachedMessagesTableFilterComposer,
          $$CachedMessagesTableOrderingComposer,
          $$CachedMessagesTableAnnotationComposer,
          $$CachedMessagesTableCreateCompanionBuilder,
          $$CachedMessagesTableUpdateCompanionBuilder,
          (
            CachedMessage,
            BaseReferences<_$AppDatabase, $CachedMessagesTable, CachedMessage>,
          ),
          CachedMessage,
          PrefetchHooks Function()
        > {
  $$CachedMessagesTableTableManager(
    _$AppDatabase db,
    $CachedMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> spaceId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<String?> authorAvatarUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMessagesCompanion(
                id: id,
                spaceId: spaceId,
                channelId: channelId,
                body: body,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                authorId: authorId,
                authorName: authorName,
                authorAvatarUrl: authorAvatarUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String spaceId,
                required String channelId,
                required String body,
                required DateTime createdAt,
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String authorId,
                required String authorName,
                Value<String?> authorAvatarUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMessagesCompanion.insert(
                id: id,
                spaceId: spaceId,
                channelId: channelId,
                body: body,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                authorId: authorId,
                authorName: authorName,
                authorAvatarUrl: authorAvatarUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMessagesTable,
      CachedMessage,
      $$CachedMessagesTableFilterComposer,
      $$CachedMessagesTableOrderingComposer,
      $$CachedMessagesTableAnnotationComposer,
      $$CachedMessagesTableCreateCompanionBuilder,
      $$CachedMessagesTableUpdateCompanionBuilder,
      (
        CachedMessage,
        BaseReferences<_$AppDatabase, $CachedMessagesTable, CachedMessage>,
      ),
      CachedMessage,
      PrefetchHooks Function()
    >;
typedef $$CachedChannelsTableCreateCompanionBuilder =
    CachedChannelsCompanion Function({
      required String id,
      required String spaceId,
      required String key,
      required String name,
      Value<String?> topic,
      Value<String?> categoryId,
      Value<bool> isPrivate,
      Value<int> position,
      Value<int> unreadCount,
      Value<int> rowid,
    });
typedef $$CachedChannelsTableUpdateCompanionBuilder =
    CachedChannelsCompanion Function({
      Value<String> id,
      Value<String> spaceId,
      Value<String> key,
      Value<String> name,
      Value<String?> topic,
      Value<String?> categoryId,
      Value<bool> isPrivate,
      Value<int> position,
      Value<int> unreadCount,
      Value<int> rowid,
    });

class $$CachedChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedChannelsTable> {
  $$CachedChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedChannelsTable> {
  $$CachedChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedChannelsTable> {
  $$CachedChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );
}

class $$CachedChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedChannelsTable,
          CachedChannel,
          $$CachedChannelsTableFilterComposer,
          $$CachedChannelsTableOrderingComposer,
          $$CachedChannelsTableAnnotationComposer,
          $$CachedChannelsTableCreateCompanionBuilder,
          $$CachedChannelsTableUpdateCompanionBuilder,
          (
            CachedChannel,
            BaseReferences<_$AppDatabase, $CachedChannelsTable, CachedChannel>,
          ),
          CachedChannel,
          PrefetchHooks Function()
        > {
  $$CachedChannelsTableTableManager(
    _$AppDatabase db,
    $CachedChannelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> spaceId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedChannelsCompanion(
                id: id,
                spaceId: spaceId,
                key: key,
                name: name,
                topic: topic,
                categoryId: categoryId,
                isPrivate: isPrivate,
                position: position,
                unreadCount: unreadCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String spaceId,
                required String key,
                required String name,
                Value<String?> topic = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedChannelsCompanion.insert(
                id: id,
                spaceId: spaceId,
                key: key,
                name: name,
                topic: topic,
                categoryId: categoryId,
                isPrivate: isPrivate,
                position: position,
                unreadCount: unreadCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedChannelsTable,
      CachedChannel,
      $$CachedChannelsTableFilterComposer,
      $$CachedChannelsTableOrderingComposer,
      $$CachedChannelsTableAnnotationComposer,
      $$CachedChannelsTableCreateCompanionBuilder,
      $$CachedChannelsTableUpdateCompanionBuilder,
      (
        CachedChannel,
        BaseReferences<_$AppDatabase, $CachedChannelsTable, CachedChannel>,
      ),
      CachedChannel,
      PrefetchHooks Function()
    >;
typedef $$CachedCategoriesTableCreateCompanionBuilder =
    CachedCategoriesCompanion Function({
      required String id,
      required String spaceId,
      required String name,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$CachedCategoriesTableUpdateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<String> id,
      Value<String> spaceId,
      Value<String> name,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCategoriesTable,
          CachedCategory,
          $$CachedCategoriesTableFilterComposer,
          $$CachedCategoriesTableOrderingComposer,
          $$CachedCategoriesTableAnnotationComposer,
          $$CachedCategoriesTableCreateCompanionBuilder,
          $$CachedCategoriesTableUpdateCompanionBuilder,
          (
            CachedCategory,
            BaseReferences<
              _$AppDatabase,
              $CachedCategoriesTable,
              CachedCategory
            >,
          ),
          CachedCategory,
          PrefetchHooks Function()
        > {
  $$CachedCategoriesTableTableManager(
    _$AppDatabase db,
    $CachedCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> spaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion(
                id: id,
                spaceId: spaceId,
                name: name,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String spaceId,
                required String name,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion.insert(
                id: id,
                spaceId: spaceId,
                name: name,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCategoriesTable,
      CachedCategory,
      $$CachedCategoriesTableFilterComposer,
      $$CachedCategoriesTableOrderingComposer,
      $$CachedCategoriesTableAnnotationComposer,
      $$CachedCategoriesTableCreateCompanionBuilder,
      $$CachedCategoriesTableUpdateCompanionBuilder,
      (
        CachedCategory,
        BaseReferences<_$AppDatabase, $CachedCategoriesTable, CachedCategory>,
      ),
      CachedCategory,
      PrefetchHooks Function()
    >;
typedef $$CachedSpacesTableCreateCompanionBuilder =
    CachedSpacesCompanion Function({
      required String id,
      required String slug,
      required String name,
      required String role,
      Value<String?> iconUrl,
      Value<int> rowid,
    });
typedef $$CachedSpacesTableUpdateCompanionBuilder =
    CachedSpacesCompanion Function({
      Value<String> id,
      Value<String> slug,
      Value<String> name,
      Value<String> role,
      Value<String?> iconUrl,
      Value<int> rowid,
    });

class $$CachedSpacesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSpacesTable> {
  $$CachedSpacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSpacesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSpacesTable> {
  $$CachedSpacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSpacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSpacesTable> {
  $$CachedSpacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);
}

class $$CachedSpacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSpacesTable,
          CachedSpace,
          $$CachedSpacesTableFilterComposer,
          $$CachedSpacesTableOrderingComposer,
          $$CachedSpacesTableAnnotationComposer,
          $$CachedSpacesTableCreateCompanionBuilder,
          $$CachedSpacesTableUpdateCompanionBuilder,
          (
            CachedSpace,
            BaseReferences<_$AppDatabase, $CachedSpacesTable, CachedSpace>,
          ),
          CachedSpace,
          PrefetchHooks Function()
        > {
  $$CachedSpacesTableTableManager(_$AppDatabase db, $CachedSpacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSpacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSpacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSpacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSpacesCompanion(
                id: id,
                slug: slug,
                name: name,
                role: role,
                iconUrl: iconUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String slug,
                required String name,
                required String role,
                Value<String?> iconUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSpacesCompanion.insert(
                id: id,
                slug: slug,
                name: name,
                role: role,
                iconUrl: iconUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSpacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSpacesTable,
      CachedSpace,
      $$CachedSpacesTableFilterComposer,
      $$CachedSpacesTableOrderingComposer,
      $$CachedSpacesTableAnnotationComposer,
      $$CachedSpacesTableCreateCompanionBuilder,
      $$CachedSpacesTableUpdateCompanionBuilder,
      (
        CachedSpace,
        BaseReferences<_$AppDatabase, $CachedSpacesTable, CachedSpace>,
      ),
      CachedSpace,
      PrefetchHooks Function()
    >;
typedef $$OutboxMessagesTableCreateCompanionBuilder =
    OutboxMessagesCompanion Function({
      required String id,
      required String spaceId,
      required String channelId,
      required String body,
      required DateTime createdAt,
      Value<int> seq,
      required String authorId,
      required String authorName,
      Value<String?> authorAvatarUrl,
      Value<int> attempts,
      Value<bool> failed,
      Value<String?> lastFailure,
      Value<int> rowid,
    });
typedef $$OutboxMessagesTableUpdateCompanionBuilder =
    OutboxMessagesCompanion Function({
      Value<String> id,
      Value<String> spaceId,
      Value<String> channelId,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<int> seq,
      Value<String> authorId,
      Value<String> authorName,
      Value<String?> authorAvatarUrl,
      Value<int> attempts,
      Value<bool> failed,
      Value<String?> lastFailure,
      Value<int> rowid,
    });

class $$OutboxMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxMessagesTable> {
  $$OutboxMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFailure => $composableBuilder(
    column: $table.lastFailure,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxMessagesTable> {
  $$OutboxMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFailure => $composableBuilder(
    column: $table.lastFailure,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxMessagesTable> {
  $$OutboxMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<bool> get failed =>
      $composableBuilder(column: $table.failed, builder: (column) => column);

  GeneratedColumn<String> get lastFailure => $composableBuilder(
    column: $table.lastFailure,
    builder: (column) => column,
  );
}

class $$OutboxMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxMessagesTable,
          OutboxMessage,
          $$OutboxMessagesTableFilterComposer,
          $$OutboxMessagesTableOrderingComposer,
          $$OutboxMessagesTableAnnotationComposer,
          $$OutboxMessagesTableCreateCompanionBuilder,
          $$OutboxMessagesTableUpdateCompanionBuilder,
          (
            OutboxMessage,
            BaseReferences<_$AppDatabase, $OutboxMessagesTable, OutboxMessage>,
          ),
          OutboxMessage,
          PrefetchHooks Function()
        > {
  $$OutboxMessagesTableTableManager(
    _$AppDatabase db,
    $OutboxMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> spaceId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<String?> authorAvatarUrl = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> failed = const Value.absent(),
                Value<String?> lastFailure = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxMessagesCompanion(
                id: id,
                spaceId: spaceId,
                channelId: channelId,
                body: body,
                createdAt: createdAt,
                seq: seq,
                authorId: authorId,
                authorName: authorName,
                authorAvatarUrl: authorAvatarUrl,
                attempts: attempts,
                failed: failed,
                lastFailure: lastFailure,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String spaceId,
                required String channelId,
                required String body,
                required DateTime createdAt,
                Value<int> seq = const Value.absent(),
                required String authorId,
                required String authorName,
                Value<String?> authorAvatarUrl = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> failed = const Value.absent(),
                Value<String?> lastFailure = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxMessagesCompanion.insert(
                id: id,
                spaceId: spaceId,
                channelId: channelId,
                body: body,
                createdAt: createdAt,
                seq: seq,
                authorId: authorId,
                authorName: authorName,
                authorAvatarUrl: authorAvatarUrl,
                attempts: attempts,
                failed: failed,
                lastFailure: lastFailure,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxMessagesTable,
      OutboxMessage,
      $$OutboxMessagesTableFilterComposer,
      $$OutboxMessagesTableOrderingComposer,
      $$OutboxMessagesTableAnnotationComposer,
      $$OutboxMessagesTableCreateCompanionBuilder,
      $$OutboxMessagesTableUpdateCompanionBuilder,
      (
        OutboxMessage,
        BaseReferences<_$AppDatabase, $OutboxMessagesTable, OutboxMessage>,
      ),
      OutboxMessage,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedMessagesTableTableManager get cachedMessages =>
      $$CachedMessagesTableTableManager(_db, _db.cachedMessages);
  $$CachedChannelsTableTableManager get cachedChannels =>
      $$CachedChannelsTableTableManager(_db, _db.cachedChannels);
  $$CachedCategoriesTableTableManager get cachedCategories =>
      $$CachedCategoriesTableTableManager(_db, _db.cachedCategories);
  $$CachedSpacesTableTableManager get cachedSpaces =>
      $$CachedSpacesTableTableManager(_db, _db.cachedSpaces);
  $$OutboxMessagesTableTableManager get outboxMessages =>
      $$OutboxMessagesTableTableManager(_db, _db.outboxMessages);
}
