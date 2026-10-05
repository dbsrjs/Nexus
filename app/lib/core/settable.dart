import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **밖에서 값을 정해 넣는 상태 하나** — 지금 연 스페이스 · 채널 · 스레드 · 이슈, 보드의
/// 범위처럼 라우트나 화면이 값을 실어 주고 provider 는 들고만 있는 것.
///
/// 같은 모양(`build() => 처음 값; set(v) => state = v`)의 Notifier 여섯이 이름만 달리해
/// 있었다. Riverpod 3 에서 `StateProvider` 는 legacy 라 Notifier 로 쓴다.
class SettableNotifier<T> extends Notifier<T> {
  SettableNotifier(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}
