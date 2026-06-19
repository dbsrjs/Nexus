# ONE 워크스페이스 — 사내 메신저 통합 솔루션

채팅 · 개발 이슈 보드 · 업무일지/근태 · AI 코드 분석 · 권한 관리를 하나로 통합한 사내 워크스페이스.
**하나의 공유 웹 UI**를 **웹 · PC(Electron) · 모바일(Capacitor)** 세 플랫폼으로 패키징한다.

## 아키텍처

```
공유 웹 UI (www/)                ← 화면·로직은 여기 한 곳에서만 유지
   ├─ 웹            : 정적 서버로 그대로 서빙
   ├─ PC (desktop/) : Electron 으로 감싼 네이티브 창 + 트레이 + 알림
   └─ 모바일(mobile/): Capacitor 로 감싼 설치형 Android/iOS 앱
```

## 폴더 구조

| 폴더 | 설명 |
|---|---|
| `www/` | **공유 웹 앱**. 단일 `index.html`(React 18 + 인브라우저 Babel). `vendor/`에 React·Babel을 로컬 번들(오프라인 동작). `manifest.webmanifest` + `sw.js`로 PWA 설치/오프라인 지원 |
| `desktop/` | Electron PC 앱 (`main.js`, `preload.js`). `../www`를 로드 |
| `mobile/` | Capacitor 모바일 앱. `copy-web.js`가 `../www`를 `mobile/www`로 동기화 |
| `design-source/` | 임포트한 원본 Claude Design 파일(`통합 워크스페이스.dc.html` + `support.js`) — 참고용 |
| `docs/백엔드-설계.md` | 백엔드(NestJS) 설계서 — 다음 단계 |

## 실행 / 빌드

### 1) 웹 (가장 빠른 미리보기)
```bash
npm run web          # → http://localhost:5173 (python http.server)
```
또는 `www/index.html`을 정적 서버로 서빙(서비스워커 때문에 file:// 보다 http 권장).

### 2) PC 앱 (Electron) — 이 Windows에서 바로 가능
```bash
cd desktop
npm install          # 최초 1회 (Electron 바이너리 다운로드)
npm start            # 앱 실행
npm run dist         # NSIS 설치본(.exe) 빌드 → desktop/dist/
```

### 3) 모바일 앱 (Capacitor)
```bash
cd mobile
npm install
npm run sync         # ../www 동기화 + cap sync
npx cap add android  # Android 네이티브 프로젝트 생성(최초 1회)
npm run android:open # Android Studio로 열기 → 빌드/실행
```
- **Android**: APK 빌드에는 **Android Studio + JDK 17** 필요.
- **iOS**: **macOS + Xcode + CocoaPods** 필수(Windows 빌드 불가). Mac에서 `npx cap add ios` 후 `npm run ios:open`.

## UI 한 번 고치면 3곳 반영

1. `www/`의 코드를 수정한다(예: `www/index.html`).
2. **웹/PC**: Electron은 `../www`를 직접 로드하므로 재시작/새로고침이면 끝.
3. **모바일**: `cd mobile && npm run sync` 로 `www`를 다시 복사한 뒤 앱을 다시 빌드.

## 현재 상태 / 다음 단계

- ✅ 디자인 임포트 → 독립 React 웹앱 구현 (목업 데이터 기반, 동작 검증 완료)
- ✅ PC(Electron) · 모바일(Capacitor) 패키징 스캐폴딩
- ⬜ **백엔드(NestJS + 온프렘 + PostgreSQL/Redis/MinIO)** — `docs/백엔드-설계.md` 참조. 인증·채팅 실시간·파일 영구보관·이슈·근태·권한·GitLab 연동. (AI 분석·Redmine·SSO는 보류)
- ⬜ `www`의 목업 데이터를 실제 백엔드 API로 교체
