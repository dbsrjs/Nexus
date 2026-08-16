import 'package:drift/drift.dart';

import '../../domain/models/channel.dart';
import '../../domain/models/space.dart';
import '../api/api_failure.dart';
import '../api/channels_api.dart';
import '../api/spaces_api.dart';
import '../local/app_database.dart';

/// 스페이스·채널 목록의 캐시. 메시지와 같은 규칙이다 —
/// **화면은 drift 를 구독하고, REST 는 캐시를 갱신할 뿐이다.**
///
/// 이 둘까지 캐시해야 오프라인 읽기가 성립한다. 대화만 캐시해 두면 스페이스
/// 선택 화면에서 막혀 그 대화에 도달할 수 없다.
class WorkspaceRepository {
  WorkspaceRepository({
    required SpacesApi spacesApi,
    required ChannelsApi channelsApi,
    required AppDatabase db,
  })  : _spacesApi = spacesApi,
        _channelsApi = channelsApi,
        _db = db;

  final SpacesApi _spacesApi;
  final ChannelsApi _channelsApi;
  final AppDatabase _db;

  // ── 스페이스 ─────────────────────────────────

  Stream<List<Space>> watchSpaces() => _db.watchSpaces().map(
        (rows) => rows
            .map((r) => Space(
                  id: r.id,
                  slug: r.slug,
                  name: r.name,
                  role: SpaceRole.values.firstWhere(
                    (v) => v.wire == r.role,
                    orElse: () => SpaceRole.member,
                  ),
                  iconUrl: r.iconUrl,
                ))
            .toList(growable: false),
      );

  Future<bool> refreshSpaces() async {
    try {
      final spaces = await _spacesApi.list();
      await _db.replaceSpaces([
        for (final s in spaces)
          CachedSpacesCompanion.insert(
            id: s.id,
            slug: s.slug,
            name: s.name,
            role: s.role.wire,
            iconUrl: Value(s.iconUrl),
          ),
      ]);
      return true;
    } on ApiException {
      return false;
    }
  }

  // ── 채널 ────────────────────────────────────

  Stream<List<Channel>> watchChannels(String spaceId) =>
      _db.watchChannels(spaceId).map(
            (rows) => rows
                .map((r) => Channel(
                      id: r.id,
                      key: r.key,
                      name: r.name,
                      topic: r.topic,
                      categoryId: r.categoryId,
                      isPrivate: r.isPrivate,
                      position: r.position,
                      unreadCount: r.unreadCount,
                      mentionCount: r.mentionCount,
                    ))
                .toList(growable: false),
          );

  Future<bool> refreshChannels(String spaceId) async {
    try {
      final channels = await _channelsApi.list(spaceId);
      // 병합이 아니라 교체다 — 권한이 회수된 채널이 캐시에 남으면 클릭 시 404 다.
      await _db.replaceChannels(spaceId, [
        for (final c in channels)
          CachedChannelsCompanion.insert(
            id: c.id,
            spaceId: spaceId,
            key: c.key,
            name: c.name,
            topic: Value(c.topic),
            categoryId: Value(c.categoryId),
            isPrivate: Value(c.isPrivate),
            position: Value(c.position),
            unreadCount: Value(c.unreadCount),
            mentionCount: Value(c.mentionCount),
          ),
      ]);
      return true;
    } on ApiException {
      return false;
    }
  }

  // ── 카테고리 ─────────────────────────────────

  Stream<List<Category>> watchCategories(String spaceId) =>
      _db.watchCategories(spaceId).map(
            (rows) => rows
                .map((r) => Category(
                      id: r.id,
                      name: r.name,
                      position: r.position,
                    ))
                .toList(growable: false),
          );

  /// 실패해도 던지지 않는다 — 오프라인이면 캐시에 있던 카테고리가 그대로 남고,
  /// 화면은 마지막으로 본 묶음을 계속 보여 준다.
  /// **빈 목록으로 덮어쓰지 않는 것이 핵심이다** (app_database.dart 의
  /// CachedCategories 주석 참고).
  Future<bool> refreshCategories(String spaceId) async {
    try {
      final categories = await _channelsApi.listCategories(spaceId);
      await _db.replaceCategories(spaceId, [
        for (final c in categories)
          CachedCategoriesCompanion.insert(
            id: c.id,
            spaceId: spaceId,
            name: c.name,
            position: Value(c.position),
          ),
      ]);
      return true;
    } on ApiException {
      return false;
    }
  }
}
