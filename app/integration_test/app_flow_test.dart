import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexus_app/core/env.dart';
import 'package:nexus_app/data/auth_storage.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/chat/thread_screen.dart';
import 'package:nexus_app/features/settings/settings_controller.dart';
import 'package:nexus_app/features/settings/theme_controller.dart';
import 'package:nexus_app/features/shell/app_shell.dart';
import 'package:nexus_app/features/space/space_controller.dart';
import 'package:nexus_app/features/space/space_menu.dart';
import 'package:nexus_app/main.dart';
import 'package:nexus_app/shared/widgets/back_button.dart';
import 'package:nexus_app/ui/ui.dart';

/// **화면을 실제 서버에 붙여 끝까지 돈다.** 단위 · 위젯 테스트는 화면 하나씩만
/// 보고, 라우트 사이를 오가는 것은 아무도 보지 않았다 — 2026-08-22 UI
/// 리디자인이 심은 라우터 결함이 열흘 뒤 사람 눈에 띌 때까지 남아 있던 이유다
/// (CLAUDE.md §5 빚).
///
/// 사전 조건: `npm run db:up` · `npm run server:dev`
/// 실행: `npm run app:flow` (Windows 데스크톱, 약 30초)
///
/// **CI 에서는 돌지 않는다.** CI 는 ubuntu 인데 앱에 `linux/` 플랫폼이 없다.
/// 들이는 것은 플랫폼을 하나 늘리는 결정이라 «마지막» 단계의 테넌트 격리 통합
/// 테스트와 함께 정한다. 그때까지는 화면을 건드린 변경마다 사람이 돌린다.
///
/// **사용자의 개발 앱을 건드리지 않는다.** 토큰 저장소와 drift 를 메모리 구현으로
/// 덮어쓴다 — 같은 앱 id 라 보안 저장소를 공유하므로, 그대로 두면 이 테스트가
/// 사용자의 로그인 세션과 캐시를 덮어쓴다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('로그인 → 스페이스 → 채널 → 전송 · 실시간 → 스레드 → 이슈 · 파일 · 저장소 → 설정', (
    tester,
  ) async {
    final fx = await _Fixture.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStorageProvider.overrideWithValue(
            AuthStorage(storage: _MemoryStorage()),
          ),
          settingsStorageProvider.overrideWithValue(
            SettingsStorage(storage: _MemoryStorage()),
          ),
          initialThemeModeProvider.overrideWithValue(ThemePreference.dark),
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: const NexusApp(),
      ),
    );

    // ── 로그인 ────────────────────────────────
    await tester.pumpUntil(find.widgetWithText(NxField, '이메일'));
    await tester.enterText(find.widgetWithText(NxField, '이메일'), fx.email);
    await tester.enterText(
      find.widgetWithText(NxField, '비밀번호'),
      _password,
    );
    await tester.tap(find.widgetWithText(NxButton, '로그인'));

    // ── 스페이스 고르기 → 셸 ──────────────────
    await tester.pumpUntil(find.text(fx.spaceName));
    await tester.tap(find.text(fx.spaceName));
    await tester.pumpUntil(find.text(fx.channelName));

    // ── 채널 → 서버에 있던 메시지 ─────────────
    await tester.tap(find.text(fx.channelName));
    await tester.pumpUntil(_body(fx.seedBody));

    // ── 입력창으로 전송 → 서버에 들어갔는지 ───
    final sent = 'sent from app ${fx.stamp}';
    await tester.enterText(find.byType(NxField).last, sent);
    await tester.pump();
    await tester.tap(
      find.byWidgetPredicate((w) => w is NxIconButton && w.label == '보내기'),
    );
    await tester.pumpUntil(_body(sent));
    await tester.pumpUntilTrue(() => fx.channelHas(sent), '보낸 메시지가 서버에 없다');

    // ── 실시간 — 다른 사람이 보낸 것이 새로고침 없이 뜬다 ──
    final live = 'live from bob ${fx.stamp}';
    await fx.bobSays(live);
    await tester.pumpUntil(_body(live));

    // ── 스레드 (셸 밖으로 덮어 연다) → 돌아온다 ──
    await tester.tap(find.text('답글 1개'));
    await tester.pumpUntil(_body(fx.replyBody));
    expect(find.text('스레드'), findsOneWidget);
    // 뿌리 메시지에는 「답글 N개」가 없다 — 누르면 같은 스레드가 한 겹 더 열렸다.
    // 스레드 화면 안에서만 찾는다 — 덮어 여는 동안에는 아래의 채널도 아직 무대에 있다.
    expect(
      find.descendant(
        of: find.byType(ThreadScreen),
        matching: find.text('답글 1개'),
      ),
      findsNothing,
    );
    // 자체 머리 줄의 뒤로 가기(NxBackButton) — tester.pageBack 은 Material · Cupertino 버튼만 찾는다.
    await tester.tap(find.byType(NxBackButton));
    await tester.pumpUntil(_body(live));

    // ── 셸 안의 작업 화면들 ──────────────────
    await tester.tap(find.text('이슈 보드'));
    await tester.pumpUntil(find.text(fx.issueTitle));

    // 끌어 옮기기(15단계 D15) — 키보드 길로 백로그 → 진행. 서버의 자리까지 바뀌어야 한다.
    Focus.of(tester.element(find.text(fx.issueTitle))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpUntilTrue(
      () async => await fx.issueStatus() == 'doing',
      '끌어 옮긴 이슈의 상태가 서버에 반영되지 않았다',
    );

    await tester.tap(find.text('파일'));
    await tester.pumpUntil(find.text('아직 올라온 파일이 없습니다.'));

    // 저장소 화면은 GitHub 계정을 연결하지 않아도 떠야 한다 — 연결 안내를 보인다.
    await tester.tap(find.text('저장소'));
    await tester.pumpUntil(find.widgetWithText(ShellHeader, '저장소'));
    await tester.pumpUntil(find.text('GitHub 연결'));

    // 셸 안에서 채널로 돌아온다 — 셸 페이지 키가 겹치면 여기서 죽는다.
    await tester.tap(find.text(fx.channelName));
    await tester.pumpUntil(_body(sent));

    // ── 14단계: 남이 이름을 바꾸면 새로고침 없이 바뀐다(user:updated → drift) ──
    final bobRenamed = 'Bob Renamed ${fx.stamp}';
    await fx.bobRenames(bobRenamed);
    await tester.pumpUntil(find.text(bobRenamed));

    // ── 14단계: 설정 창 — 계정 메뉴 → 이름 바꾸기 → 닫기 ──
    await tester.tap(
      find.byWidgetPredicate((w) => w is NxTooltip && w.message == 'AppFlow A'),
    );
    await tester.pumpUntil(find.text('설정'));
    // 메뉴가 펼쳐지는 동안은 누른 자리가 항목에 닿지 않는다.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('설정'));
    await tester.pumpUntil(find.text('표시 이름'));
    final aliceRenamed = 'Alice Renamed ${fx.stamp}';
    await tester.enterText(
      find.widgetWithText(NxField, 'AppFlow A'),
      aliceRenamed,
    );
    // 저장 버튼은 바뀐 이름을 본 다음 프레임에 켜진다. 그 전에 누르면 꺼진 버튼이다.
    await tester.pump();
    await tester.tap(find.widgetWithText(NxButton, '저장'));
    await tester.pumpUntil(find.text('이름을 바꿨습니다'));

    // 사진 올리기 — 파일 대화상자는 자동화할 수 없어 **그 뒤의 앱 코드**를 부른다.
    // 대화상자가 돌려주는 것(이름 · 바이트)을 그대로 넘기는 경로다.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NexusApp)),
    );
    final photo = await File('assets/logo/nexus-mark-512.png').readAsBytes();
    final withPhoto = await container
        .read(settingsApiProvider)
        .uploadAvatar(bytes: photo, filename: 'nexus-mark-512.png');
    expect(withPhoto.avatarUrl, startsWith('/users/'));

    // 화면 → 라이트. 계정 메뉴에서 옮겨 온 테마가 실제로 바뀌는지.
    await tester.tap(find.text('화면'));
    await tester.pumpUntil(find.text('라이트'));
    await tester.tap(find.text('라이트'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(themeModeProvider), ThemePreference.light);
    // 앱 뿌리의 자체 테마가 바뀐다(NxRoot).
    expect(
      tester.widget<NxTheme>(find.byType(NxTheme).first).data.brightness,
      Brightness.light,
    );

    // 알림 → 채널 음소거 → 목록 아이콘이 바뀐다.
    await tester.tap(find.text('알림'));
    final muteSwitch = find.byWidgetPredicate(
      (w) => w is NxSwitch && w.label == '${fx.channelName} 음소거',
    );
    await tester.pumpUntil(muteSwitch);
    await tester.tap(muteSwitch);
    await tester.pumpUntilTrue(() => fx.aliceMuted(), '음소거가 서버에 반영되지 않았다');

    // Esc 로 닫으면 들어오기 전 채널로 돌아간다. 내 메시지의 작성자명이 새 이름이다.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpUntil(_body(sent));
    await tester.pumpUntil(find.text(aliceRenamed));
    expect(
      find.byWidgetPredicate((w) => w is NxIcon && w.icon == NxIcons.mutedBell),
      findsOneWidget,
    );

    // ── 16단계: 스페이스 메뉴 → 초대하기 → 코드 만들기 → 멤버 → 내보내기 ──
    await tester.tap(find.byType(SpaceMenu));
    await tester.pumpUntil(find.text('초대하기'));
    // 메뉴가 펼쳐지는 동안은 누른 자리가 항목에 닿지 않는다.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('초대하기'));
    await tester.pumpUntil(find.widgetWithText(NxButton, '초대 코드 만들기'));
    await tester.tap(find.widgetWithText(NxButton, '초대 코드 만들기'));
    await tester.pumpUntil(find.widgetWithText(NxButton, '복사'));
    // 만든 코드가 「쓸 수 있는 초대」 목록에도 있다(초대 취소 버튼).
    await tester.pumpUntil(find.widgetWithText(NxButton, '취소'));

    // 「멤버」는 역할 고르기에도 있다 — 왼쪽 목록의 줄을 누른다.
    await tester.tap(find.widgetWithText(NxRow, '멤버'));
    final bobActions = find.bySemanticsLabel('$bobRenamed의 동작');
    await tester.pumpUntil(bobActions);
    await tester.tap(bobActions);
    await tester.pumpUntil(find.text('내보내기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('내보내기'));
    await tester.pumpUntil(find.widgetWithText(NxButton, '내보내기'));
    await tester.tap(find.widgetWithText(NxButton, '내보내기'));
    await tester.pumpUntilTrue(() async => !(await fx.bobIsMember()), '내보내기가 서버에 반영되지 않았다');
    await tester.pumpUntilGone(find.text(bobRenamed));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpUntil(find.byType(SpaceMenu));

    expect(tester.takeException(), isNull);
  });
}

const _password = 'app-flow-check-1234';

/// 메시지 본문 찾기. 본문은 마크다운이라 `RichText` 로 그려지는데 `find.text` 는
/// 기본으로 `RichText` 를 보지 않는다.
Finder _body(String text) => find.text(text, findRichText: true);

/// 서버에 테스트용 계정 · 스페이스 · 메시지 · 답글 · 이슈를 API 로 만든다.
/// 이름은 영문이다 — slug 가 한글을 떨어뜨려 이름이 겹친다(CLAUDE.md §2).
class _Fixture {
  _Fixture._(this._dio, this.stamp);

  final Dio _dio;
  final String stamp;

  late final String email;
  late final String spaceName;
  late final String channelName;
  late final String seedBody;
  late final String replyBody;
  late final String issueTitle;

  late String _spaceId;
  late String _channelId;
  late String _aliceToken;
  late String _bobToken;

  static Future<_Fixture> create() async {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final dio = Dio(
      BaseOptions(baseUrl: Env.apiRoot, validateStatus: (_) => true),
    );
    final fx = _Fixture._(dio, stamp);
    await fx._build();
    return fx;
  }

  Future<void> _build() async {
    email = 'appflow-a-$stamp@example.com';
    _aliceToken = await _signup(email, 'AppFlow A');
    _bobToken = await _signup('appflow-b-$stamp@example.com', 'AppFlow B');

    spaceName = 'app flow $stamp';
    final space = await _post('/spaces', _aliceToken, {'name': spaceName});
    _spaceId = space['id'] as String;

    final invite = await _post('/spaces/$_spaceId/invites', _aliceToken, {
      'role': 'member',
    });
    await _post('/invites/${invite['code']}/accept', _bobToken, {});

    // 기본 채널 `dev`(개발)를 쓴다. `general` 은 이름이 카테고리 「일반」과 같아
    // 채널 목록에서 글자로 찾으면 카테고리 머리를 누르게 된다.
    final channels =
        await _get('/spaces/$_spaceId/channels', _aliceToken) as List;
    final channel = channels.cast<Map>().firstWhere((c) => c['key'] == 'dev');
    _channelId = channel['id'] as String;
    channelName = channel['name'] as String;

    seedBody = 'seed message $stamp';
    final seed = await _post(_messagesPath, _aliceToken, {'body': seedBody});
    replyBody = 'thread reply $stamp';
    await _post(_messagesPath, _bobToken, {
      'body': replyBody,
      'parentId': seed['id'],
    });

    issueTitle = 'flow issue $stamp';
    await _post('/spaces/$_spaceId/issues', _aliceToken, {'title': issueTitle});
  }

  String get _messagesPath => '/spaces/$_spaceId/channels/$_channelId/messages';

  Future<void> bobSays(String body) =>
      _post(_messagesPath, _bobToken, {'body': body});

  Future<void> bobRenames(String name) =>
      _patch('/me', _bobToken, {'name': name});

  /// bob 이 아직 픽스처 스페이스의 멤버인가(16단계 — 내보내기).
  Future<bool> bobIsMember() async {
    final spaces = await _get('/spaces', _bobToken) as List;
    return spaces.cast<Map>().any((s) => s['id'] == _spaceId);
  }

  Future<bool> aliceMuted() async {
    final channels =
        await _get('/spaces/$_spaceId/channels', _aliceToken) as List;
    return channels.cast<Map>().any(
      (c) => c['id'] == _channelId && c['muted'] == true,
    );
  }

  /// 픽스처 이슈의 서버 상태(`backlog` · `doing` …).
  Future<String?> issueStatus() async {
    final res = await _get('/spaces/$_spaceId/issues', _aliceToken) as Map;
    final items = res['issues'] as List;
    for (final i in items.cast<Map>()) {
      if (i['title'] == issueTitle) return i['status'] as String?;
    }
    return null;
  }

  Future<bool> channelHas(String body) async {
    final page = await _get(_messagesPath, _aliceToken);
    final items = (page is Map ? page['items'] : page) as List;
    return items.any((m) => (m as Map)['body'] == body);
  }

  Future<String> _signup(String email, String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': _password,
        'name': name,
        'client': 'native',
      },
    );
    _expect(res, 201);
    return res.data!['accessToken'] as String;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<dynamic>(
      path,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    _expect(res, 201, 200);
    return res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : const {};
  }

  Future<void> _patch(
    String path,
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.patch<dynamic>(
      path,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    _expect(res, 200);
  }

  Future<dynamic> _get(String path, String token) async {
    final res = await _dio.get<dynamic>(
      path,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    _expect(res, 200);
    return res.data;
  }

  /// **서버가 없으면 여기서 멈춘다** — 화면을 한참 기다리다 엉뚱한 곳에서
  /// 실패하지 않게 준비 단계에서 원인을 말한다.
  void _expect(Response<dynamic> res, int want, [int? alt]) {
    if (res.statusCode == want || res.statusCode == alt) return;
    throw StateError(
      '${res.requestOptions.method} ${res.requestOptions.path} → ${res.statusCode} '
      '${res.data}\n(서버가 떠 있는가? npm run db:up && npm run server:dev)',
    );
  }
}

extension on WidgetTester {
  /// `pumpAndSettle` 은 쓰지 않는다 — 스피너 · 소켓 재연결 타이머가 있어
  /// 끝내 가라앉지 않는다. 찾는 것이 보일 때까지 짧게 돌린다.
  Future<void> pumpUntil(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure(
      '시간 안에 나타나지 않았다: $finder\n화면에 보이는 글자: ${_visibleTexts()}',
    );
  }

  /// 실패했을 때 무엇이 대신 떠 있었는지. 없는 것만 말하면 어디서 길을 잃었는지 모른다.
  List<String> _visibleTexts() => [
    for (final e in find.byType(RichText).evaluate())
      (e.widget as RichText).text.toPlainText(),
  ].where((t) => t.trim().isNotEmpty).take(60).toList();

  /// 보이던 것이 사라질 때까지.
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isEmpty) return;
    }
    throw TestFailure('시간 안에 사라지지 않았다: $finder');
  }

  /// 화면 밖의 조건(서버 상태)을 기다린다. 도는 동안 프레임도 계속 돌린다.
  Future<void> pumpUntilTrue(
    Future<bool> Function() condition,
    String reason, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (await condition()) return;
      await pump(const Duration(milliseconds: 200));
    }
    throw TestFailure(reason);
  }
}

/// 보안 저장소의 메모리 대역. 쓰는 메서드만 흉내 내고, 나머지를 부르면
/// `noSuchMethod` 로 터져 모르는 경로가 조용히 지나가지 않게 한다.
class _MemoryStorage implements FlutterSecureStorage {
  final _values = <String, String>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #read:
        return Future<String?>.value(_values[key]);
      case #write:
        final value = invocation.namedArguments[#value] as String?;
        if (value == null) {
          _values.remove(key);
        } else {
          _values[key!] = value;
        }
        return Future<void>.value();
      case #delete:
        _values.remove(key);
        return Future<void>.value();
      case #deleteAll:
        _values.clear();
        return Future<void>.value();
      case #containsKey:
        return Future<bool>.value(_values.containsKey(key));
    }
    return super.noSuchMethod(invocation);
  }
}
