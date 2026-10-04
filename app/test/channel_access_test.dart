import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/domain/models/channel_access.dart';
import 'package:nexus_app/domain/models/space.dart';

/// 16-2 — 채널 목록의 `canSend` · 스페이스의 `sprintsEnabled` 가 서버 → 모델 → drift 를
/// 잃지 않고 지나간다. 캐시에서 빠지면 오프라인에서 읽기 전용 입력창 · 스프린트 갈래가 틀린다.
void main() {
  test('★ 서버가 canSend 를 주지 않으면(옛 응답) 보낼 수 있다고 본다', () {
    final c = Channel.fromJson({'id': 'c1', 'key': 'k', 'name': 'n'});
    expect(c.canSend, isTrue);
    expect(Channel.fromJson({'id': 'c1', 'key': 'k', 'name': 'n', 'canSend': false}).canSend, isFalse);
  });

  test('스페이스는 스프린트가 기본 꺼져 있다(D31)', () {
    final s = Space.fromJson({'id': 's', 'slug': 's', 'name': 'n', 'role': 'member'});
    expect(s.sprintsEnabled, isFalse);
  });

  test('권한 줄 · 명단 줄 파싱', () {
    final p = RolePermission.fromJson({'role': 'guest', 'canView': false, 'canSend': false, 'explicit': true});
    expect((p.role, p.canView, p.canSend, p.explicit), (SpaceRole.guest, false, false, true));
    final m = ChannelMemberView.fromJson({'userId': 'u', 'name': '가영', 'avatarUrl': null, 'role': 'admin'});
    expect((m.userId, m.role), ('u', SpaceRole.admin));
  });

  group('drift', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('★ cached_channels.can_send 가 왕복한다', () async {
      await db.replaceChannels('s1', [
        CachedChannelsCompanion.insert(id: 'a', spaceId: 's1', key: 'a', name: 'a', canSend: const Value(false)),
        CachedChannelsCompanion.insert(id: 'b', spaceId: 's1', key: 'b', name: 'b'),
      ]);
      final rows = await db.watchChannels('s1').first;
      expect(rows.firstWhere((c) => c.id == 'a').canSend, isFalse);
      expect(rows.firstWhere((c) => c.id == 'b').canSend, isTrue);
    });

    test('★ cached_spaces.sprints_enabled 가 왕복한다', () async {
      await db.replaceSpaces([
        CachedSpacesCompanion.insert(
          id: 's1',
          slug: 's1',
          name: '하나',
          role: 'owner',
          sprintsEnabled: const Value(true),
        ),
        CachedSpacesCompanion.insert(id: 's2', slug: 's2', name: '둘', role: 'member'),
      ]);
      final rows = await db.watchSpaces().first;
      expect(rows.firstWhere((s) => s.id == 's1').sprintsEnabled, isTrue);
      expect(rows.firstWhere((s) => s.id == 's2').sprintsEnabled, isFalse);
    });
  });
}
