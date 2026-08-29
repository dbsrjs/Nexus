---
name: nexus-android-verify
description: Use when verifying a Nexus Flutter change on the Android emulator or a physical device — building the APK, installing it, launching it, and capturing a screenshot to confirm the UI actually renders.
---

# Nexus 앱을 Android 에서 눈으로 확인

## Overview

Nexus 는 검증 플랫폼을 Windows 데스크톱으로 좁혀 뒀다(빌드 23초 + 즉시 실행).
Android 는 **슬라이스 경계 + 플랫폼 민감 변경**(보안 저장소·키보드·`10.0.2.2`·
반응형 레이아웃 경계)일 때만 쓴다. `flutter run` 을 그대로 띄우면 안 된다 —
stdin 이 EOF 라 곧바로 종료된다. build → install 로 간다.

## 절차

```bash
# 1) 에뮬레이터 기동 (부팅까지 1~2분)
%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe -avd nexus_pixel

# 2) 빌드 · 설치 · 실행
cd app
flutter build apk --debug --dart-define=API_BASE=http://10.0.2.2:3000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.nexus.nexus_app -c android.intent.category.LAUNCHER 1

# 3) 화면 캡처
adb shell screencap -p /sdcard/s.png
adb pull /sdcard/s.png <로컬 경로>
```

## 함정 셋 — 전부 실제로 겪은 것

| 증상 | 원인·대응 |
|---|---|
| `API_BASE` 를 안 주거나 `127.0.0.1` 로 주면 서버에 못 붙음 | 에뮬레이터에게 `127.0.0.1` 은 자기 자신이다. **반드시 `http://10.0.2.2:3000`** |
| PowerShell 에서 `adb exec-out screencap -p > 파일` 로 받은 이미지가 깨짐 | `exec-out` 이 BOM 을 삽입한다. **`screencap` 으로 기기에 저장 후 `adb pull`** 로 가져올 것 |
| 검증 문구에 한글을 쓰면 `adb shell input text` 가 `NullPointerException` | 한글을 못 넣는다. **실기기 검증용 문구는 영문으로** 쓴다 |

## 반응형 분기 확인 시 (선택)

```bash
adb shell wm size 2560x1440   # 또는 800x1280(tablet) 등
adb shell wm density 240
# 확인 후 반드시 되돌린다
adb shell wm size reset
adb shell wm density reset
```

**되돌리지 않고 세션을 끝내면 다음 확인이 왜곡된다** — 잊지 말 것.

## 관련

Windows 개발 루프가 기본값인 이유와 플랫폼별 우선순위는
`docs/앱-설계.md §0-1` 과 저장소 `CLAUDE.md` "검증 플랫폼" 절이 원본이다.
