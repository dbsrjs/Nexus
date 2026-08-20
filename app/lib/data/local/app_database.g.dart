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
  late final GeneratedColumnWithTypeConverter<List<MessageReaction>, String>
  reactions =
      GeneratedColumn<String>(
        'reactions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<MessageReaction>>(
        $CachedMessagesTable.$converterreactions,
      );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyCountMeta = const VerificationMeta(
    'replyCount',
  );
  @override
  late final GeneratedColumn<int> replyCount = GeneratedColumn<int>(
    'reply_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastReplyAt =
      GeneratedColumn<int>(
        'last_reply_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CachedMessagesTable.$converterlastReplyAtn);
  @override
  late final GeneratedColumnWithTypeConverter<QuotedMessage?, String> quoted =
      GeneratedColumn<String>(
        'quoted',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<QuotedMessage?>($CachedMessagesTable.$converterquoted);
  @override
  late final GeneratedColumnWithTypeConverter<List<MessageMention>, String>
  mentions =
      GeneratedColumn<String>(
        'mentions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<List<MessageMention>>(
        $CachedMessagesTable.$convertermentions,
      );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<MessageAttachment>, String>
  attachments =
      GeneratedColumn<String>(
        'attachments',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<List<MessageAttachment>>(
        $CachedMessagesTable.$converterattachments,
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
    reactions,
    parentId,
    replyCount,
    lastReplyAt,
    quoted,
    mentions,
    pinned,
    attachments,
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
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('reply_count')) {
      context.handle(
        _replyCountMeta,
        replyCount.isAcceptableOrUnknown(data['reply_count']!, _replyCountMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
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
      reactions: $CachedMessagesTable.$converterreactions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reactions'],
        )!,
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      replyCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reply_count'],
      )!,
      lastReplyAt: $CachedMessagesTable.$converterlastReplyAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_reply_at'],
        ),
      ),
      quoted: $CachedMessagesTable.$converterquoted.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quoted'],
        )!,
      ),
      mentions: $CachedMessagesTable.$convertermentions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mentions'],
        )!,
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      attachments: $CachedMessagesTable.$converterattachments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attachments'],
        )!,
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
  static TypeConverter<List<MessageReaction>, String> $converterreactions =
      const _ReactionsJson();
  static TypeConverter<DateTime, int> $converterlastReplyAt =
      const _UtcMicros();
  static TypeConverter<DateTime?, int?> $converterlastReplyAtn =
      NullAwareTypeConverter.wrap($converterlastReplyAt);
  static TypeConverter<QuotedMessage?, String> $converterquoted =
      const _QuotedJson();
  static TypeConverter<List<MessageMention>, String> $convertermentions =
      const _MentionsJson();
  static TypeConverter<List<MessageAttachment>, String> $converterattachments =
      const _AttachmentsJson();
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
  final List<MessageReaction> reactions;

  /// 값이 있으면 스레드 답글이다. **채널 타임라인 조회는 이것이 NULL 인 것만
  /// 본다** — 서버가 그렇게 나누므로 캐시도 같은 규칙이어야 한다.
  final String? parentId;
  final int replyCount;
  final DateTime? lastReplyAt;

  /// 답장이면 인용 요약. 빈 문자열이면 답장이 아니다.
  final QuotedMessage? quoted;

  /// 본문의 `<@id>` 를 이름으로 바꾸는 데 쓰는 멘션 목록.
  final List<MessageMention> mentions;

  /// 채널 상단에 고정됐는지.
  final bool pinned;

  /// 붙은 파일 요약. 바이트는 여기 없다 — 볼 때 서버에서 받는다.
  final List<MessageAttachment> attachments;
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
    required this.reactions,
    this.parentId,
    required this.replyCount,
    this.lastReplyAt,
    this.quoted,
    required this.mentions,
    required this.pinned,
    required this.attachments,
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
    {
      map['reactions'] = Variable<String>(
        $CachedMessagesTable.$converterreactions.toSql(reactions),
      );
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['reply_count'] = Variable<int>(replyCount);
    if (!nullToAbsent || lastReplyAt != null) {
      map['last_reply_at'] = Variable<int>(
        $CachedMessagesTable.$converterlastReplyAtn.toSql(lastReplyAt),
      );
    }
    if (!nullToAbsent || quoted != null) {
      map['quoted'] = Variable<String>(
        $CachedMessagesTable.$converterquoted.toSql(quoted),
      );
    }
    {
      map['mentions'] = Variable<String>(
        $CachedMessagesTable.$convertermentions.toSql(mentions),
      );
    }
    map['pinned'] = Variable<bool>(pinned);
    {
      map['attachments'] = Variable<String>(
        $CachedMessagesTable.$converterattachments.toSql(attachments),
      );
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
      reactions: Value(reactions),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      replyCount: Value(replyCount),
      lastReplyAt: lastReplyAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReplyAt),
      quoted: quoted == null && nullToAbsent
          ? const Value.absent()
          : Value(quoted),
      mentions: Value(mentions),
      pinned: Value(pinned),
      attachments: Value(attachments),
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
      reactions: serializer.fromJson<List<MessageReaction>>(json['reactions']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      replyCount: serializer.fromJson<int>(json['replyCount']),
      lastReplyAt: serializer.fromJson<DateTime?>(json['lastReplyAt']),
      quoted: serializer.fromJson<QuotedMessage?>(json['quoted']),
      mentions: serializer.fromJson<List<MessageMention>>(json['mentions']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      attachments: serializer.fromJson<List<MessageAttachment>>(
        json['attachments'],
      ),
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
      'reactions': serializer.toJson<List<MessageReaction>>(reactions),
      'parentId': serializer.toJson<String?>(parentId),
      'replyCount': serializer.toJson<int>(replyCount),
      'lastReplyAt': serializer.toJson<DateTime?>(lastReplyAt),
      'quoted': serializer.toJson<QuotedMessage?>(quoted),
      'mentions': serializer.toJson<List<MessageMention>>(mentions),
      'pinned': serializer.toJson<bool>(pinned),
      'attachments': serializer.toJson<List<MessageAttachment>>(attachments),
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
    List<MessageReaction>? reactions,
    Value<String?> parentId = const Value.absent(),
    int? replyCount,
    Value<DateTime?> lastReplyAt = const Value.absent(),
    Value<QuotedMessage?> quoted = const Value.absent(),
    List<MessageMention>? mentions,
    bool? pinned,
    List<MessageAttachment>? attachments,
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
    reactions: reactions ?? this.reactions,
    parentId: parentId.present ? parentId.value : this.parentId,
    replyCount: replyCount ?? this.replyCount,
    lastReplyAt: lastReplyAt.present ? lastReplyAt.value : this.lastReplyAt,
    quoted: quoted.present ? quoted.value : this.quoted,
    mentions: mentions ?? this.mentions,
    pinned: pinned ?? this.pinned,
    attachments: attachments ?? this.attachments,
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
      reactions: data.reactions.present ? data.reactions.value : this.reactions,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      replyCount: data.replyCount.present
          ? data.replyCount.value
          : this.replyCount,
      lastReplyAt: data.lastReplyAt.present
          ? data.lastReplyAt.value
          : this.lastReplyAt,
      quoted: data.quoted.present ? data.quoted.value : this.quoted,
      mentions: data.mentions.present ? data.mentions.value : this.mentions,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
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
          ..write('authorAvatarUrl: $authorAvatarUrl, ')
          ..write('reactions: $reactions, ')
          ..write('parentId: $parentId, ')
          ..write('replyCount: $replyCount, ')
          ..write('lastReplyAt: $lastReplyAt, ')
          ..write('quoted: $quoted, ')
          ..write('mentions: $mentions, ')
          ..write('pinned: $pinned, ')
          ..write('attachments: $attachments')
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
    reactions,
    parentId,
    replyCount,
    lastReplyAt,
    quoted,
    mentions,
    pinned,
    attachments,
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
          other.authorAvatarUrl == this.authorAvatarUrl &&
          other.reactions == this.reactions &&
          other.parentId == this.parentId &&
          other.replyCount == this.replyCount &&
          other.lastReplyAt == this.lastReplyAt &&
          other.quoted == this.quoted &&
          other.mentions == this.mentions &&
          other.pinned == this.pinned &&
          other.attachments == this.attachments);
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
  final Value<List<MessageReaction>> reactions;
  final Value<String?> parentId;
  final Value<int> replyCount;
  final Value<DateTime?> lastReplyAt;
  final Value<QuotedMessage?> quoted;
  final Value<List<MessageMention>> mentions;
  final Value<bool> pinned;
  final Value<List<MessageAttachment>> attachments;
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
    this.reactions = const Value.absent(),
    this.parentId = const Value.absent(),
    this.replyCount = const Value.absent(),
    this.lastReplyAt = const Value.absent(),
    this.quoted = const Value.absent(),
    this.mentions = const Value.absent(),
    this.pinned = const Value.absent(),
    this.attachments = const Value.absent(),
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
    this.reactions = const Value.absent(),
    this.parentId = const Value.absent(),
    this.replyCount = const Value.absent(),
    this.lastReplyAt = const Value.absent(),
    this.quoted = const Value.absent(),
    this.mentions = const Value.absent(),
    this.pinned = const Value.absent(),
    this.attachments = const Value.absent(),
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
    Expression<String>? reactions,
    Expression<String>? parentId,
    Expression<int>? replyCount,
    Expression<int>? lastReplyAt,
    Expression<String>? quoted,
    Expression<String>? mentions,
    Expression<bool>? pinned,
    Expression<String>? attachments,
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
      if (reactions != null) 'reactions': reactions,
      if (parentId != null) 'parent_id': parentId,
      if (replyCount != null) 'reply_count': replyCount,
      if (lastReplyAt != null) 'last_reply_at': lastReplyAt,
      if (quoted != null) 'quoted': quoted,
      if (mentions != null) 'mentions': mentions,
      if (pinned != null) 'pinned': pinned,
      if (attachments != null) 'attachments': attachments,
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
    Value<List<MessageReaction>>? reactions,
    Value<String?>? parentId,
    Value<int>? replyCount,
    Value<DateTime?>? lastReplyAt,
    Value<QuotedMessage?>? quoted,
    Value<List<MessageMention>>? mentions,
    Value<bool>? pinned,
    Value<List<MessageAttachment>>? attachments,
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
      reactions: reactions ?? this.reactions,
      parentId: parentId ?? this.parentId,
      replyCount: replyCount ?? this.replyCount,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      quoted: quoted ?? this.quoted,
      mentions: mentions ?? this.mentions,
      pinned: pinned ?? this.pinned,
      attachments: attachments ?? this.attachments,
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
    if (reactions.present) {
      map['reactions'] = Variable<String>(
        $CachedMessagesTable.$converterreactions.toSql(reactions.value),
      );
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (replyCount.present) {
      map['reply_count'] = Variable<int>(replyCount.value);
    }
    if (lastReplyAt.present) {
      map['last_reply_at'] = Variable<int>(
        $CachedMessagesTable.$converterlastReplyAtn.toSql(lastReplyAt.value),
      );
    }
    if (quoted.present) {
      map['quoted'] = Variable<String>(
        $CachedMessagesTable.$converterquoted.toSql(quoted.value),
      );
    }
    if (mentions.present) {
      map['mentions'] = Variable<String>(
        $CachedMessagesTable.$convertermentions.toSql(mentions.value),
      );
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(
        $CachedMessagesTable.$converterattachments.toSql(attachments.value),
      );
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
          ..write('reactions: $reactions, ')
          ..write('parentId: $parentId, ')
          ..write('replyCount: $replyCount, ')
          ..write('lastReplyAt: $lastReplyAt, ')
          ..write('quoted: $quoted, ')
          ..write('mentions: $mentions, ')
          ..write('pinned: $pinned, ')
          ..write('attachments: $attachments, ')
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
  static const VerificationMeta _mentionCountMeta = const VerificationMeta(
    'mentionCount',
  );
  @override
  late final GeneratedColumn<int> mentionCount = GeneratedColumn<int>(
    'mention_count',
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
    mentionCount,
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
    if (data.containsKey('mention_count')) {
      context.handle(
        _mentionCountMeta,
        mentionCount.isAcceptableOrUnknown(
          data['mention_count']!,
          _mentionCountMeta,
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
      mentionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mention_count'],
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

  /// 안 읽은 **멘션** 수. 안 읽은 수와 따로 센다.
  final int mentionCount;
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
    required this.mentionCount,
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
    map['mention_count'] = Variable<int>(mentionCount);
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
      mentionCount: Value(mentionCount),
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
      mentionCount: serializer.fromJson<int>(json['mentionCount']),
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
      'mentionCount': serializer.toJson<int>(mentionCount),
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
    int? mentionCount,
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
    mentionCount: mentionCount ?? this.mentionCount,
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
      mentionCount: data.mentionCount.present
          ? data.mentionCount.value
          : this.mentionCount,
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
          ..write('unreadCount: $unreadCount, ')
          ..write('mentionCount: $mentionCount')
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
    mentionCount,
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
          other.unreadCount == this.unreadCount &&
          other.mentionCount == this.mentionCount);
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
  final Value<int> mentionCount;
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
    this.mentionCount = const Value.absent(),
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
    this.mentionCount = const Value.absent(),
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
    Expression<int>? mentionCount,
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
      if (mentionCount != null) 'mention_count': mentionCount,
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
    Value<int>? mentionCount,
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
      mentionCount: mentionCount ?? this.mentionCount,
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
    if (mentionCount.present) {
      map['mention_count'] = Variable<int>(mentionCount.value);
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
          ..write('mentionCount: $mentionCount, ')
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

class $CachedIssuesTable extends CachedIssues
    with TableInfo<$CachedIssuesTable, CachedIssue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedIssuesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assigneeIdMeta = const VerificationMeta(
    'assigneeId',
  );
  @override
  late final GeneratedColumn<String> assigneeId = GeneratedColumn<String>(
    'assignee_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assigneeNameMeta = const VerificationMeta(
    'assigneeName',
  );
  @override
  late final GeneratedColumn<String> assigneeName = GeneratedColumn<String>(
    'assignee_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assigneeAvatarUrlMeta = const VerificationMeta(
    'assigneeAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> assigneeAvatarUrl =
      GeneratedColumn<String>(
        'assignee_avatar_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sprintIdMeta = const VerificationMeta(
    'sprintId',
  );
  @override
  late final GeneratedColumn<String> sprintId = GeneratedColumn<String>(
    'sprint_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storyPointsMeta = const VerificationMeta(
    'storyPoints',
  );
  @override
  late final GeneratedColumn<int> storyPoints = GeneratedColumn<int>(
    'story_points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<double> sortKey = GeneratedColumn<double>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusRankMeta = const VerificationMeta(
    'statusRank',
  );
  @override
  late final GeneratedColumn<int> statusRank = GeneratedColumn<int>(
    'status_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> closedAt =
      GeneratedColumn<int>(
        'closed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CachedIssuesTable.$converterclosedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedIssuesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedIssuesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    spaceId,
    key,
    title,
    description,
    status,
    priority,
    assigneeId,
    assigneeName,
    assigneeAvatarUrl,
    sprintId,
    parentId,
    storyPoints,
    position,
    sortKey,
    statusRank,
    closedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_issues';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedIssue> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('assignee_id')) {
      context.handle(
        _assigneeIdMeta,
        assigneeId.isAcceptableOrUnknown(data['assignee_id']!, _assigneeIdMeta),
      );
    }
    if (data.containsKey('assignee_name')) {
      context.handle(
        _assigneeNameMeta,
        assigneeName.isAcceptableOrUnknown(
          data['assignee_name']!,
          _assigneeNameMeta,
        ),
      );
    }
    if (data.containsKey('assignee_avatar_url')) {
      context.handle(
        _assigneeAvatarUrlMeta,
        assigneeAvatarUrl.isAcceptableOrUnknown(
          data['assignee_avatar_url']!,
          _assigneeAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('sprint_id')) {
      context.handle(
        _sprintIdMeta,
        sprintId.isAcceptableOrUnknown(data['sprint_id']!, _sprintIdMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('story_points')) {
      context.handle(
        _storyPointsMeta,
        storyPoints.isAcceptableOrUnknown(
          data['story_points']!,
          _storyPointsMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sortKeyMeta);
    }
    if (data.containsKey('status_rank')) {
      context.handle(
        _statusRankMeta,
        statusRank.isAcceptableOrUnknown(data['status_rank']!, _statusRankMeta),
      );
    } else if (isInserting) {
      context.missing(_statusRankMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedIssue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedIssue(
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
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      assigneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_id'],
      ),
      assigneeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_name'],
      ),
      assigneeAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_avatar_url'],
      ),
      sprintId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sprint_id'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      storyPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_points'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sort_key'],
      )!,
      statusRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_rank'],
      )!,
      closedAt: $CachedIssuesTable.$converterclosedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}closed_at'],
        ),
      ),
      createdAt: $CachedIssuesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $CachedIssuesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $CachedIssuesTable createAlias(String alias) {
    return $CachedIssuesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterclosedAt = const _UtcMicros();
  static TypeConverter<DateTime?, int?> $converterclosedAtn =
      NullAwareTypeConverter.wrap($converterclosedAt);
  static TypeConverter<DateTime, int> $convertercreatedAt = const _UtcMicros();
  static TypeConverter<DateTime, int> $converterupdatedAt = const _UtcMicros();
}

class CachedIssue extends DataClass implements Insertable<CachedIssue> {
  final String id;
  final String spaceId;
  final String key;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeAvatarUrl;
  final String? sprintId;
  final String? parentId;
  final int? storyPoints;

  /// 서버가 준 Decimal 문자열을 그대로 둔다. 이동 요청에 되돌려 보낼 값이다.
  final String position;

  /// **정렬은 이것이 한다.** position 문자열은 사전순이 수 순서와 달라
  /// ('-1000' 이 '500' 보다 뒤에 온다) 그대로 정렬하면 뒤집힌다.
  final double sortKey;

  /// 컬럼 순서(backlog · doing · review · done). 이름으로 정렬하면
  /// 알파벳순(backlog · doing · done · review)이 되어 보드가 뒤섞인다.
  final int statusRank;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedIssue({
    required this.id,
    required this.spaceId,
    required this.key,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.assigneeName,
    this.assigneeAvatarUrl,
    this.sprintId,
    this.parentId,
    this.storyPoints,
    required this.position,
    required this.sortKey,
    required this.statusRank,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['space_id'] = Variable<String>(spaceId);
    map['key'] = Variable<String>(key);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || assigneeId != null) {
      map['assignee_id'] = Variable<String>(assigneeId);
    }
    if (!nullToAbsent || assigneeName != null) {
      map['assignee_name'] = Variable<String>(assigneeName);
    }
    if (!nullToAbsent || assigneeAvatarUrl != null) {
      map['assignee_avatar_url'] = Variable<String>(assigneeAvatarUrl);
    }
    if (!nullToAbsent || sprintId != null) {
      map['sprint_id'] = Variable<String>(sprintId);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || storyPoints != null) {
      map['story_points'] = Variable<int>(storyPoints);
    }
    map['position'] = Variable<String>(position);
    map['sort_key'] = Variable<double>(sortKey);
    map['status_rank'] = Variable<int>(statusRank);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(
        $CachedIssuesTable.$converterclosedAtn.toSql(closedAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $CachedIssuesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $CachedIssuesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  CachedIssuesCompanion toCompanion(bool nullToAbsent) {
    return CachedIssuesCompanion(
      id: Value(id),
      spaceId: Value(spaceId),
      key: Value(key),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      priority: Value(priority),
      assigneeId: assigneeId == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeId),
      assigneeName: assigneeName == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeName),
      assigneeAvatarUrl: assigneeAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeAvatarUrl),
      sprintId: sprintId == null && nullToAbsent
          ? const Value.absent()
          : Value(sprintId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      storyPoints: storyPoints == null && nullToAbsent
          ? const Value.absent()
          : Value(storyPoints),
      position: Value(position),
      sortKey: Value(sortKey),
      statusRank: Value(statusRank),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedIssue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedIssue(
      id: serializer.fromJson<String>(json['id']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      key: serializer.fromJson<String>(json['key']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      assigneeId: serializer.fromJson<String?>(json['assigneeId']),
      assigneeName: serializer.fromJson<String?>(json['assigneeName']),
      assigneeAvatarUrl: serializer.fromJson<String?>(
        json['assigneeAvatarUrl'],
      ),
      sprintId: serializer.fromJson<String?>(json['sprintId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      storyPoints: serializer.fromJson<int?>(json['storyPoints']),
      position: serializer.fromJson<String>(json['position']),
      sortKey: serializer.fromJson<double>(json['sortKey']),
      statusRank: serializer.fromJson<int>(json['statusRank']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spaceId': serializer.toJson<String>(spaceId),
      'key': serializer.toJson<String>(key),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'assigneeId': serializer.toJson<String?>(assigneeId),
      'assigneeName': serializer.toJson<String?>(assigneeName),
      'assigneeAvatarUrl': serializer.toJson<String?>(assigneeAvatarUrl),
      'sprintId': serializer.toJson<String?>(sprintId),
      'parentId': serializer.toJson<String?>(parentId),
      'storyPoints': serializer.toJson<int?>(storyPoints),
      'position': serializer.toJson<String>(position),
      'sortKey': serializer.toJson<double>(sortKey),
      'statusRank': serializer.toJson<int>(statusRank),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedIssue copyWith({
    String? id,
    String? spaceId,
    String? key,
    String? title,
    Value<String?> description = const Value.absent(),
    String? status,
    String? priority,
    Value<String?> assigneeId = const Value.absent(),
    Value<String?> assigneeName = const Value.absent(),
    Value<String?> assigneeAvatarUrl = const Value.absent(),
    Value<String?> sprintId = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    Value<int?> storyPoints = const Value.absent(),
    String? position,
    double? sortKey,
    int? statusRank,
    Value<DateTime?> closedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedIssue(
    id: id ?? this.id,
    spaceId: spaceId ?? this.spaceId,
    key: key ?? this.key,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    assigneeId: assigneeId.present ? assigneeId.value : this.assigneeId,
    assigneeName: assigneeName.present ? assigneeName.value : this.assigneeName,
    assigneeAvatarUrl: assigneeAvatarUrl.present
        ? assigneeAvatarUrl.value
        : this.assigneeAvatarUrl,
    sprintId: sprintId.present ? sprintId.value : this.sprintId,
    parentId: parentId.present ? parentId.value : this.parentId,
    storyPoints: storyPoints.present ? storyPoints.value : this.storyPoints,
    position: position ?? this.position,
    sortKey: sortKey ?? this.sortKey,
    statusRank: statusRank ?? this.statusRank,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedIssue copyWithCompanion(CachedIssuesCompanion data) {
    return CachedIssue(
      id: data.id.present ? data.id.value : this.id,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      key: data.key.present ? data.key.value : this.key,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      assigneeId: data.assigneeId.present
          ? data.assigneeId.value
          : this.assigneeId,
      assigneeName: data.assigneeName.present
          ? data.assigneeName.value
          : this.assigneeName,
      assigneeAvatarUrl: data.assigneeAvatarUrl.present
          ? data.assigneeAvatarUrl.value
          : this.assigneeAvatarUrl,
      sprintId: data.sprintId.present ? data.sprintId.value : this.sprintId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      storyPoints: data.storyPoints.present
          ? data.storyPoints.value
          : this.storyPoints,
      position: data.position.present ? data.position.value : this.position,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      statusRank: data.statusRank.present
          ? data.statusRank.value
          : this.statusRank,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedIssue(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('assigneeName: $assigneeName, ')
          ..write('assigneeAvatarUrl: $assigneeAvatarUrl, ')
          ..write('sprintId: $sprintId, ')
          ..write('parentId: $parentId, ')
          ..write('storyPoints: $storyPoints, ')
          ..write('position: $position, ')
          ..write('sortKey: $sortKey, ')
          ..write('statusRank: $statusRank, ')
          ..write('closedAt: $closedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    spaceId,
    key,
    title,
    description,
    status,
    priority,
    assigneeId,
    assigneeName,
    assigneeAvatarUrl,
    sprintId,
    parentId,
    storyPoints,
    position,
    sortKey,
    statusRank,
    closedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedIssue &&
          other.id == this.id &&
          other.spaceId == this.spaceId &&
          other.key == this.key &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.assigneeId == this.assigneeId &&
          other.assigneeName == this.assigneeName &&
          other.assigneeAvatarUrl == this.assigneeAvatarUrl &&
          other.sprintId == this.sprintId &&
          other.parentId == this.parentId &&
          other.storyPoints == this.storyPoints &&
          other.position == this.position &&
          other.sortKey == this.sortKey &&
          other.statusRank == this.statusRank &&
          other.closedAt == this.closedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedIssuesCompanion extends UpdateCompanion<CachedIssue> {
  final Value<String> id;
  final Value<String> spaceId;
  final Value<String> key;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<String> priority;
  final Value<String?> assigneeId;
  final Value<String?> assigneeName;
  final Value<String?> assigneeAvatarUrl;
  final Value<String?> sprintId;
  final Value<String?> parentId;
  final Value<int?> storyPoints;
  final Value<String> position;
  final Value<double> sortKey;
  final Value<int> statusRank;
  final Value<DateTime?> closedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedIssuesCompanion({
    this.id = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.key = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.assigneeId = const Value.absent(),
    this.assigneeName = const Value.absent(),
    this.assigneeAvatarUrl = const Value.absent(),
    this.sprintId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.storyPoints = const Value.absent(),
    this.position = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.statusRank = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedIssuesCompanion.insert({
    required String id,
    required String spaceId,
    required String key,
    required String title,
    this.description = const Value.absent(),
    required String status,
    required String priority,
    this.assigneeId = const Value.absent(),
    this.assigneeName = const Value.absent(),
    this.assigneeAvatarUrl = const Value.absent(),
    this.sprintId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.storyPoints = const Value.absent(),
    required String position,
    required double sortKey,
    required int statusRank,
    this.closedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       spaceId = Value(spaceId),
       key = Value(key),
       title = Value(title),
       status = Value(status),
       priority = Value(priority),
       position = Value(position),
       sortKey = Value(sortKey),
       statusRank = Value(statusRank),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedIssue> custom({
    Expression<String>? id,
    Expression<String>? spaceId,
    Expression<String>? key,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? assigneeId,
    Expression<String>? assigneeName,
    Expression<String>? assigneeAvatarUrl,
    Expression<String>? sprintId,
    Expression<String>? parentId,
    Expression<int>? storyPoints,
    Expression<String>? position,
    Expression<double>? sortKey,
    Expression<int>? statusRank,
    Expression<int>? closedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spaceId != null) 'space_id': spaceId,
      if (key != null) 'key': key,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (assigneeId != null) 'assignee_id': assigneeId,
      if (assigneeName != null) 'assignee_name': assigneeName,
      if (assigneeAvatarUrl != null) 'assignee_avatar_url': assigneeAvatarUrl,
      if (sprintId != null) 'sprint_id': sprintId,
      if (parentId != null) 'parent_id': parentId,
      if (storyPoints != null) 'story_points': storyPoints,
      if (position != null) 'position': position,
      if (sortKey != null) 'sort_key': sortKey,
      if (statusRank != null) 'status_rank': statusRank,
      if (closedAt != null) 'closed_at': closedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedIssuesCompanion copyWith({
    Value<String>? id,
    Value<String>? spaceId,
    Value<String>? key,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? status,
    Value<String>? priority,
    Value<String?>? assigneeId,
    Value<String?>? assigneeName,
    Value<String?>? assigneeAvatarUrl,
    Value<String?>? sprintId,
    Value<String?>? parentId,
    Value<int?>? storyPoints,
    Value<String>? position,
    Value<double>? sortKey,
    Value<int>? statusRank,
    Value<DateTime?>? closedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedIssuesCompanion(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatarUrl: assigneeAvatarUrl ?? this.assigneeAvatarUrl,
      sprintId: sprintId ?? this.sprintId,
      parentId: parentId ?? this.parentId,
      storyPoints: storyPoints ?? this.storyPoints,
      position: position ?? this.position,
      sortKey: sortKey ?? this.sortKey,
      statusRank: statusRank ?? this.statusRank,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (assigneeId.present) {
      map['assignee_id'] = Variable<String>(assigneeId.value);
    }
    if (assigneeName.present) {
      map['assignee_name'] = Variable<String>(assigneeName.value);
    }
    if (assigneeAvatarUrl.present) {
      map['assignee_avatar_url'] = Variable<String>(assigneeAvatarUrl.value);
    }
    if (sprintId.present) {
      map['sprint_id'] = Variable<String>(sprintId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (storyPoints.present) {
      map['story_points'] = Variable<int>(storyPoints.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<double>(sortKey.value);
    }
    if (statusRank.present) {
      map['status_rank'] = Variable<int>(statusRank.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(
        $CachedIssuesTable.$converterclosedAtn.toSql(closedAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CachedIssuesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CachedIssuesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedIssuesCompanion(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('assigneeName: $assigneeName, ')
          ..write('assigneeAvatarUrl: $assigneeAvatarUrl, ')
          ..write('sprintId: $sprintId, ')
          ..write('parentId: $parentId, ')
          ..write('storyPoints: $storyPoints, ')
          ..write('position: $position, ')
          ..write('sortKey: $sortKey, ')
          ..write('statusRank: $statusRank, ')
          ..write('closedAt: $closedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotedMessageIdMeta = const VerificationMeta(
    'quotedMessageId',
  );
  @override
  late final GeneratedColumn<String> quotedMessageId = GeneratedColumn<String>(
    'quoted_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<QuotedMessage?, String> quoted =
      GeneratedColumn<String>(
        'quoted',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<QuotedMessage?>($OutboxMessagesTable.$converterquoted);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  attachmentIds = GeneratedColumn<String>(
    'attachment_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  ).withConverter<List<String>>($OutboxMessagesTable.$converterattachmentIds);
  @override
  late final GeneratedColumnWithTypeConverter<List<MessageAttachment>, String>
  attachments =
      GeneratedColumn<String>(
        'attachments',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<List<MessageAttachment>>(
        $OutboxMessagesTable.$converterattachments,
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
    parentId,
    quotedMessageId,
    quoted,
    attachmentIds,
    attachments,
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
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('quoted_message_id')) {
      context.handle(
        _quotedMessageIdMeta,
        quotedMessageId.isAcceptableOrUnknown(
          data['quoted_message_id']!,
          _quotedMessageIdMeta,
        ),
      );
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
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      quotedMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quoted_message_id'],
      ),
      quoted: $OutboxMessagesTable.$converterquoted.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quoted'],
        )!,
      ),
      attachmentIds: $OutboxMessagesTable.$converterattachmentIds.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attachment_ids'],
        )!,
      ),
      attachments: $OutboxMessagesTable.$converterattachments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attachments'],
        )!,
      ),
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

  static TypeConverter<QuotedMessage?, String> $converterquoted =
      const _QuotedJson();
  static TypeConverter<List<String>, String> $converterattachmentIds =
      const _IdListJson();
  static TypeConverter<List<MessageAttachment>, String> $converterattachments =
      const _AttachmentsJson();
  static TypeConverter<DateTime, int> $convertercreatedAt = const _UtcMicros();
}

class OutboxMessage extends DataClass implements Insertable<OutboxMessage> {
  /// 로컬에서 만든 임시 id(`local-…`). 전송에 성공하면 서버 id 로 대체된다.
  final String id;
  final String spaceId;
  final String channelId;
  final String body;

  /// 스레드 답글이면 부모 id. 오프라인에서 쓴 답글도 답글로 나가야 한다.
  final String? parentId;

  /// 답장이면 인용 대상 id. 큐에서도 답장은 답장으로 나가야 한다.
  final String? quotedMessageId;

  /// 인용 요약. 큐에 있는 동안 화면에 인용문을 그리려면 필요하다 —
  /// 서버에 닿기 전에는 원본을 서버에서 받아올 수 없다.
  final QuotedMessage? quoted;

  /// 붙일 첨부의 id. **파일 자체는 큐에 없다** — 이미 서버에 올라가 있다.
  ///
  /// 업로드는 온라인에서만 되지만, 한 번 올라가면 그 뒤 오프라인이 되어도
  /// 이 메시지는 큐에서 기다렸다 나갈 수 있다. 다만 **24시간 안에 나가야
  /// 한다** — 그 전에 연결되지 못한 첨부는 서버가 고아로 보고 지운다.
  final List<String> attachmentIds;

  /// 첨부 요약. 큐에 있는 동안 화면에 파일 이름을 그리려면 필요하다 —
  /// 인용 요약을 함께 담아 두는 것과 같은 이유다.
  final List<MessageAttachment> attachments;

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
    this.parentId,
    this.quotedMessageId,
    this.quoted,
    required this.attachmentIds,
    required this.attachments,
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
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || quotedMessageId != null) {
      map['quoted_message_id'] = Variable<String>(quotedMessageId);
    }
    if (!nullToAbsent || quoted != null) {
      map['quoted'] = Variable<String>(
        $OutboxMessagesTable.$converterquoted.toSql(quoted),
      );
    }
    {
      map['attachment_ids'] = Variable<String>(
        $OutboxMessagesTable.$converterattachmentIds.toSql(attachmentIds),
      );
    }
    {
      map['attachments'] = Variable<String>(
        $OutboxMessagesTable.$converterattachments.toSql(attachments),
      );
    }
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
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      quotedMessageId: quotedMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(quotedMessageId),
      quoted: quoted == null && nullToAbsent
          ? const Value.absent()
          : Value(quoted),
      attachmentIds: Value(attachmentIds),
      attachments: Value(attachments),
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
      parentId: serializer.fromJson<String?>(json['parentId']),
      quotedMessageId: serializer.fromJson<String?>(json['quotedMessageId']),
      quoted: serializer.fromJson<QuotedMessage?>(json['quoted']),
      attachmentIds: serializer.fromJson<List<String>>(json['attachmentIds']),
      attachments: serializer.fromJson<List<MessageAttachment>>(
        json['attachments'],
      ),
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
      'parentId': serializer.toJson<String?>(parentId),
      'quotedMessageId': serializer.toJson<String?>(quotedMessageId),
      'quoted': serializer.toJson<QuotedMessage?>(quoted),
      'attachmentIds': serializer.toJson<List<String>>(attachmentIds),
      'attachments': serializer.toJson<List<MessageAttachment>>(attachments),
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
    Value<String?> parentId = const Value.absent(),
    Value<String?> quotedMessageId = const Value.absent(),
    Value<QuotedMessage?> quoted = const Value.absent(),
    List<String>? attachmentIds,
    List<MessageAttachment>? attachments,
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
    parentId: parentId.present ? parentId.value : this.parentId,
    quotedMessageId: quotedMessageId.present
        ? quotedMessageId.value
        : this.quotedMessageId,
    quoted: quoted.present ? quoted.value : this.quoted,
    attachmentIds: attachmentIds ?? this.attachmentIds,
    attachments: attachments ?? this.attachments,
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
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      quotedMessageId: data.quotedMessageId.present
          ? data.quotedMessageId.value
          : this.quotedMessageId,
      quoted: data.quoted.present ? data.quoted.value : this.quoted,
      attachmentIds: data.attachmentIds.present
          ? data.attachmentIds.value
          : this.attachmentIds,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
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
          ..write('parentId: $parentId, ')
          ..write('quotedMessageId: $quotedMessageId, ')
          ..write('quoted: $quoted, ')
          ..write('attachmentIds: $attachmentIds, ')
          ..write('attachments: $attachments, ')
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
    parentId,
    quotedMessageId,
    quoted,
    attachmentIds,
    attachments,
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
          other.parentId == this.parentId &&
          other.quotedMessageId == this.quotedMessageId &&
          other.quoted == this.quoted &&
          other.attachmentIds == this.attachmentIds &&
          other.attachments == this.attachments &&
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
  final Value<String?> parentId;
  final Value<String?> quotedMessageId;
  final Value<QuotedMessage?> quoted;
  final Value<List<String>> attachmentIds;
  final Value<List<MessageAttachment>> attachments;
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
    this.parentId = const Value.absent(),
    this.quotedMessageId = const Value.absent(),
    this.quoted = const Value.absent(),
    this.attachmentIds = const Value.absent(),
    this.attachments = const Value.absent(),
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
    this.parentId = const Value.absent(),
    this.quotedMessageId = const Value.absent(),
    this.quoted = const Value.absent(),
    this.attachmentIds = const Value.absent(),
    this.attachments = const Value.absent(),
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
    Expression<String>? parentId,
    Expression<String>? quotedMessageId,
    Expression<String>? quoted,
    Expression<String>? attachmentIds,
    Expression<String>? attachments,
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
      if (parentId != null) 'parent_id': parentId,
      if (quotedMessageId != null) 'quoted_message_id': quotedMessageId,
      if (quoted != null) 'quoted': quoted,
      if (attachmentIds != null) 'attachment_ids': attachmentIds,
      if (attachments != null) 'attachments': attachments,
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
    Value<String?>? parentId,
    Value<String?>? quotedMessageId,
    Value<QuotedMessage?>? quoted,
    Value<List<String>>? attachmentIds,
    Value<List<MessageAttachment>>? attachments,
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
      parentId: parentId ?? this.parentId,
      quotedMessageId: quotedMessageId ?? this.quotedMessageId,
      quoted: quoted ?? this.quoted,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      attachments: attachments ?? this.attachments,
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
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (quotedMessageId.present) {
      map['quoted_message_id'] = Variable<String>(quotedMessageId.value);
    }
    if (quoted.present) {
      map['quoted'] = Variable<String>(
        $OutboxMessagesTable.$converterquoted.toSql(quoted.value),
      );
    }
    if (attachmentIds.present) {
      map['attachment_ids'] = Variable<String>(
        $OutboxMessagesTable.$converterattachmentIds.toSql(attachmentIds.value),
      );
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(
        $OutboxMessagesTable.$converterattachments.toSql(attachments.value),
      );
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
          ..write('parentId: $parentId, ')
          ..write('quotedMessageId: $quotedMessageId, ')
          ..write('quoted: $quoted, ')
          ..write('attachmentIds: $attachmentIds, ')
          ..write('attachments: $attachments, ')
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
  late final $CachedIssuesTable cachedIssues = $CachedIssuesTable(this);
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
    cachedIssues,
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
      Value<List<MessageReaction>> reactions,
      Value<String?> parentId,
      Value<int> replyCount,
      Value<DateTime?> lastReplyAt,
      Value<QuotedMessage?> quoted,
      Value<List<MessageMention>> mentions,
      Value<bool> pinned,
      Value<List<MessageAttachment>> attachments,
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
      Value<List<MessageReaction>> reactions,
      Value<String?> parentId,
      Value<int> replyCount,
      Value<DateTime?> lastReplyAt,
      Value<QuotedMessage?> quoted,
      Value<List<MessageMention>> mentions,
      Value<bool> pinned,
      Value<List<MessageAttachment>> attachments,
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

  ColumnWithTypeConverterFilters<
    List<MessageReaction>,
    List<MessageReaction>,
    String
  >
  get reactions => $composableBuilder(
    column: $table.reactions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replyCount => $composableBuilder(
    column: $table.replyCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastReplyAt =>
      $composableBuilder(
        column: $table.lastReplyAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<QuotedMessage?, QuotedMessage, String>
  get quoted => $composableBuilder(
    column: $table.quoted,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<MessageMention>,
    List<MessageMention>,
    String
  >
  get mentions => $composableBuilder(
    column: $table.mentions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<MessageAttachment>,
    List<MessageAttachment>,
    String
  >
  get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnOrderings<String> get reactions => $composableBuilder(
    column: $table.reactions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replyCount => $composableBuilder(
    column: $table.replyCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReplyAt => $composableBuilder(
    column: $table.lastReplyAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoted => $composableBuilder(
    column: $table.quoted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mentions => $composableBuilder(
    column: $table.mentions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
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

  GeneratedColumnWithTypeConverter<List<MessageReaction>, String>
  get reactions =>
      $composableBuilder(column: $table.reactions, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get replyCount => $composableBuilder(
    column: $table.replyCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastReplyAt =>
      $composableBuilder(
        column: $table.lastReplyAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<QuotedMessage?, String> get quoted =>
      $composableBuilder(column: $table.quoted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<MessageMention>, String> get mentions =>
      $composableBuilder(column: $table.mentions, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<MessageAttachment>, String>
  get attachments => $composableBuilder(
    column: $table.attachments,
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
                Value<List<MessageReaction>> reactions = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> replyCount = const Value.absent(),
                Value<DateTime?> lastReplyAt = const Value.absent(),
                Value<QuotedMessage?> quoted = const Value.absent(),
                Value<List<MessageMention>> mentions = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<List<MessageAttachment>> attachments =
                    const Value.absent(),
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
                reactions: reactions,
                parentId: parentId,
                replyCount: replyCount,
                lastReplyAt: lastReplyAt,
                quoted: quoted,
                mentions: mentions,
                pinned: pinned,
                attachments: attachments,
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
                Value<List<MessageReaction>> reactions = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> replyCount = const Value.absent(),
                Value<DateTime?> lastReplyAt = const Value.absent(),
                Value<QuotedMessage?> quoted = const Value.absent(),
                Value<List<MessageMention>> mentions = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<List<MessageAttachment>> attachments =
                    const Value.absent(),
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
                reactions: reactions,
                parentId: parentId,
                replyCount: replyCount,
                lastReplyAt: lastReplyAt,
                quoted: quoted,
                mentions: mentions,
                pinned: pinned,
                attachments: attachments,
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
      Value<int> mentionCount,
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
      Value<int> mentionCount,
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

  ColumnFilters<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
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

  ColumnOrderings<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
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

  GeneratedColumn<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
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
                Value<int> mentionCount = const Value.absent(),
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
                mentionCount: mentionCount,
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
                Value<int> mentionCount = const Value.absent(),
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
                mentionCount: mentionCount,
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
typedef $$CachedIssuesTableCreateCompanionBuilder =
    CachedIssuesCompanion Function({
      required String id,
      required String spaceId,
      required String key,
      required String title,
      Value<String?> description,
      required String status,
      required String priority,
      Value<String?> assigneeId,
      Value<String?> assigneeName,
      Value<String?> assigneeAvatarUrl,
      Value<String?> sprintId,
      Value<String?> parentId,
      Value<int?> storyPoints,
      required String position,
      required double sortKey,
      required int statusRank,
      Value<DateTime?> closedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedIssuesTableUpdateCompanionBuilder =
    CachedIssuesCompanion Function({
      Value<String> id,
      Value<String> spaceId,
      Value<String> key,
      Value<String> title,
      Value<String?> description,
      Value<String> status,
      Value<String> priority,
      Value<String?> assigneeId,
      Value<String?> assigneeName,
      Value<String?> assigneeAvatarUrl,
      Value<String?> sprintId,
      Value<String?> parentId,
      Value<int?> storyPoints,
      Value<String> position,
      Value<double> sortKey,
      Value<int> statusRank,
      Value<DateTime?> closedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedIssuesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedIssuesTable> {
  $$CachedIssuesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeAvatarUrl => $composableBuilder(
    column: $table.assigneeAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sprintId => $composableBuilder(
    column: $table.sprintId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storyPoints => $composableBuilder(
    column: $table.storyPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusRank => $composableBuilder(
    column: $table.statusRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get closedAt =>
      $composableBuilder(
        column: $table.closedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CachedIssuesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedIssuesTable> {
  $$CachedIssuesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeAvatarUrl => $composableBuilder(
    column: $table.assigneeAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sprintId => $composableBuilder(
    column: $table.sprintId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storyPoints => $composableBuilder(
    column: $table.storyPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusRank => $composableBuilder(
    column: $table.statusRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedIssuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedIssuesTable> {
  $$CachedIssuesTableAnnotationComposer({
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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assigneeAvatarUrl => $composableBuilder(
    column: $table.assigneeAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sprintId =>
      $composableBuilder(column: $table.sprintId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get storyPoints => $composableBuilder(
    column: $table.storyPoints,
    builder: (column) => column,
  );

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  GeneratedColumn<int> get statusRank => $composableBuilder(
    column: $table.statusRank,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedIssuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedIssuesTable,
          CachedIssue,
          $$CachedIssuesTableFilterComposer,
          $$CachedIssuesTableOrderingComposer,
          $$CachedIssuesTableAnnotationComposer,
          $$CachedIssuesTableCreateCompanionBuilder,
          $$CachedIssuesTableUpdateCompanionBuilder,
          (
            CachedIssue,
            BaseReferences<_$AppDatabase, $CachedIssuesTable, CachedIssue>,
          ),
          CachedIssue,
          PrefetchHooks Function()
        > {
  $$CachedIssuesTableTableManager(_$AppDatabase db, $CachedIssuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedIssuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedIssuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedIssuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> spaceId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> assigneeName = const Value.absent(),
                Value<String?> assigneeAvatarUrl = const Value.absent(),
                Value<String?> sprintId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int?> storyPoints = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<double> sortKey = const Value.absent(),
                Value<int> statusRank = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedIssuesCompanion(
                id: id,
                spaceId: spaceId,
                key: key,
                title: title,
                description: description,
                status: status,
                priority: priority,
                assigneeId: assigneeId,
                assigneeName: assigneeName,
                assigneeAvatarUrl: assigneeAvatarUrl,
                sprintId: sprintId,
                parentId: parentId,
                storyPoints: storyPoints,
                position: position,
                sortKey: sortKey,
                statusRank: statusRank,
                closedAt: closedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String spaceId,
                required String key,
                required String title,
                Value<String?> description = const Value.absent(),
                required String status,
                required String priority,
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> assigneeName = const Value.absent(),
                Value<String?> assigneeAvatarUrl = const Value.absent(),
                Value<String?> sprintId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int?> storyPoints = const Value.absent(),
                required String position,
                required double sortKey,
                required int statusRank,
                Value<DateTime?> closedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedIssuesCompanion.insert(
                id: id,
                spaceId: spaceId,
                key: key,
                title: title,
                description: description,
                status: status,
                priority: priority,
                assigneeId: assigneeId,
                assigneeName: assigneeName,
                assigneeAvatarUrl: assigneeAvatarUrl,
                sprintId: sprintId,
                parentId: parentId,
                storyPoints: storyPoints,
                position: position,
                sortKey: sortKey,
                statusRank: statusRank,
                closedAt: closedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedIssuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedIssuesTable,
      CachedIssue,
      $$CachedIssuesTableFilterComposer,
      $$CachedIssuesTableOrderingComposer,
      $$CachedIssuesTableAnnotationComposer,
      $$CachedIssuesTableCreateCompanionBuilder,
      $$CachedIssuesTableUpdateCompanionBuilder,
      (
        CachedIssue,
        BaseReferences<_$AppDatabase, $CachedIssuesTable, CachedIssue>,
      ),
      CachedIssue,
      PrefetchHooks Function()
    >;
typedef $$OutboxMessagesTableCreateCompanionBuilder =
    OutboxMessagesCompanion Function({
      required String id,
      required String spaceId,
      required String channelId,
      required String body,
      Value<String?> parentId,
      Value<String?> quotedMessageId,
      Value<QuotedMessage?> quoted,
      Value<List<String>> attachmentIds,
      Value<List<MessageAttachment>> attachments,
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
      Value<String?> parentId,
      Value<String?> quotedMessageId,
      Value<QuotedMessage?> quoted,
      Value<List<String>> attachmentIds,
      Value<List<MessageAttachment>> attachments,
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

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quotedMessageId => $composableBuilder(
    column: $table.quotedMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<QuotedMessage?, QuotedMessage, String>
  get quoted => $composableBuilder(
    column: $table.quoted,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get attachmentIds => $composableBuilder(
    column: $table.attachmentIds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<MessageAttachment>,
    List<MessageAttachment>,
    String
  >
  get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotedMessageId => $composableBuilder(
    column: $table.quotedMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoted => $composableBuilder(
    column: $table.quoted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentIds => $composableBuilder(
    column: $table.attachmentIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
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

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get quotedMessageId => $composableBuilder(
    column: $table.quotedMessageId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<QuotedMessage?, String> get quoted =>
      $composableBuilder(column: $table.quoted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get attachmentIds =>
      $composableBuilder(
        column: $table.attachmentIds,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<MessageAttachment>, String>
  get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => column,
  );

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
                Value<String?> parentId = const Value.absent(),
                Value<String?> quotedMessageId = const Value.absent(),
                Value<QuotedMessage?> quoted = const Value.absent(),
                Value<List<String>> attachmentIds = const Value.absent(),
                Value<List<MessageAttachment>> attachments =
                    const Value.absent(),
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
                parentId: parentId,
                quotedMessageId: quotedMessageId,
                quoted: quoted,
                attachmentIds: attachmentIds,
                attachments: attachments,
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
                Value<String?> parentId = const Value.absent(),
                Value<String?> quotedMessageId = const Value.absent(),
                Value<QuotedMessage?> quoted = const Value.absent(),
                Value<List<String>> attachmentIds = const Value.absent(),
                Value<List<MessageAttachment>> attachments =
                    const Value.absent(),
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
                parentId: parentId,
                quotedMessageId: quotedMessageId,
                quoted: quoted,
                attachmentIds: attachmentIds,
                attachments: attachments,
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
  $$CachedIssuesTableTableManager get cachedIssues =>
      $$CachedIssuesTableTableManager(_db, _db.cachedIssues);
  $$OutboxMessagesTableTableManager get outboxMessages =>
      $$OutboxMessagesTableTableManager(_db, _db.outboxMessages);
}
