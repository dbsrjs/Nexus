# Nexus — 앱 (app)

Nexus 의 Flutter 클라이언트. 한 코드베이스로 **Windows · Android · Web** 을 만든다
(iOS 는 macOS 없이 빌드할 수 없어 동결).

설계: [`../docs/앱-설계.md`](../docs/앱-설계.md) · 구조 둘러보기: [`../docs/코드-둘러보기.md`](../docs/코드-둘러보기.md) §5

## 실행

서버(`npm run server:dev`)가 먼저 떠 있어야 한다 — [루트 README](../README.md) 참고.

```bash
flutter pub get
dart run build_runner build        # freezed · json_serializable · drift 코드 생성

flutter run -d windows --dart-define=API_BASE=http://127.0.0.1:3000
flutter run -d chrome  --web-port=5173 --dart-define=API_BASE=http://127.0.0.1:3000
flutter run -d <에뮬레이터> --dart-define=API_BASE=http://10.0.2.2:3000
```

- **기본 검증 대상은 Windows** 다. Android · Web 은 슬라이스 경계에서 확인한다
- 웹 포트는 **5173 고정** — 서버 `CORS_ORIGINS` 가 이 주소만 허용한다
- Android 에뮬레이터에게 `127.0.0.1` 은 자기 자신이다 — `10.0.2.2` 를 쓴다
- Windows 데스크톱 빌드에는 **개발자 모드**가 켜져 있어야 한다(플러그인이 심볼릭 링크를 쓴다)
- Windows 앱은 **창을 닫으면 트레이로 숨는다**(알림을 계속 받으려고). 끝내려면 트레이 아이콘 메뉴의 「종료」. 트레이 아이콘을 못 올린 환경이면 그냥 닫힌다
- 웹 알림은 보안 컨텍스트(https · `localhost`)에서만 뜬다 — `127.0.0.1` 이 아니라 `localhost:5173` 으로 열 것
- Flutter 버전 하한은 CI 가 고정한 **3.44.9**. SDK 차이로 `pubspec.lock` 이 바뀌면 커밋하지 않는다

## 검사

```bash
flutter analyze
flutter test
npm --prefix .. run app:flow       # 통합 테스트 — Windows 앱을 실서버에 붙여 끝까지 돈다(서버 필요)
npm --prefix .. run app:flow:headless  # 같은 흐름을 창 없이(flutter_tester) — CI 가 이것을 돈다
```

**화면은 `lib/ui/` 의 자체 부품만 쓴다** — `lib/` 에서 material · cupertino 를 import 하면
`test/no_platform_ui_test.dart` 가 실패한다. 부품 갤러리는 디버그 빌드의 `/dev/ui`
(`--dart-define=NX_START=/dev/ui` 로 바로 연다).

모델(freezed · drift)을 고쳤으면 `build_runner` 를 다시 돌리고 생성물(`.g.dart` · `.freezed.dart`)도 함께 커밋한다.
