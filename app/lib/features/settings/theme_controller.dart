import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_storage.dart';

final settingsStorageProvider =
    Provider<SettingsStorage>((_) => SettingsStorage());

/// 앱을 켤 때 저장소에서 읽은 값. `main()` 이 `runApp` 전에 덮어쓴다.
///
/// **이 provider 가 있는 이유는 깜빡임 때문이다.** 컨트롤러가 스스로 저장소를
/// 읽으면 그것이 비동기라 화면이 시스템 테마로 한 번 그려졌다가 저장된 값으로
/// 바뀐다. 읽기를 `runApp` 앞으로 옮기면 첫 프레임부터 맞는 테마로 뜬다.
///
/// 테스트는 이것을 덮어써서 저장소를 건드리지 않는다.
final initialThemeModeProvider = Provider<ThemeMode>((_) => ThemeMode.system);

/// 지금 테마. **기본은 시스템**이다 — OS 설정을 따르는 것이 사용자가 이미
/// 고른 취향을 존중하는 길이다.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  /// 고른 값을 곧바로 반영하고 저장은 뒤따르게 한다. 저장이 느리거나
  /// 실패해도 화면이 기다리지 않는다.
  void set(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
    ref.read(settingsStorageProvider).writeThemeMode(mode);
  }
}
