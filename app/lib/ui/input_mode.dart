import 'package:flutter/foundation.dart';

/// **터치가 주인인 플랫폼인가**(Android · iOS). 폭이 아니라 입력 방식의 판정이라, 반응형
/// 폭 분기를 셸 한 곳에 두는 규칙(§3)과 무관하다.
///
/// 메뉴(터치면 동작 카드) · 보드 끌기(터치면 길게 눌러) · 입력창(물리 키보드면 Enter 전송
/// 안내) · 메시지 호버 도구 막대가 같은 두 줄을 각자 들고 있었다. 데스크톱 터치 화면 같은
/// 경우를 다르게 다루기로 하면 여기 한 곳만 고친다.
bool get nxTouchFirst =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
