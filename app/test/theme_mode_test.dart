import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/features/settings/theme_controller.dart';

/// 실제 안전 저장소를 건드리지 않는다. `implements` 로 만들어 private 필드를
/// 상속하지 않는다.
class _FakeSettingsStorage implements SettingsStorage {
  ThemeMode? written;
  int writeCount = 0;

  @override
  Future<ThemeMode> readThemeMode() async => ThemeMode.system;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    written = mode;
    writeCount++;
  }
}

ProviderContainer _container({
  ThemeMode initial = ThemeMode.system,
  required _FakeSettingsStorage storage,
}) {
  final container = ProviderContainer(
    overrides: [
      initialThemeModeProvider.overrideWithValue(initial),
      settingsStorageProvider.overrideWithValue(storage),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('테마 모드', () {
    test('기본은 시스템이다 — OS 설정을 따른다', () {
      final container = _container(storage: _FakeSettingsStorage());
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('앱을 켤 때 읽은 값에서 시작한다', () {
      // main() 이 runApp 앞에서 읽어 override 로 넣는 값이다. 이것이 없으면
      // 첫 프레임이 시스템 테마로 그려졌다가 바뀌어 깜빡인다.
      final container = _container(
        initial: ThemeMode.light,
        storage: _FakeSettingsStorage(),
      );
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('바꾸면 곧바로 반영되고 저장된다', () async {
      final storage = _FakeSettingsStorage();
      final container = _container(storage: storage);

      container.read(themeModeProvider.notifier).set(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(storage.written, ThemeMode.dark);
    });

    test('같은 값을 다시 고르면 저장하지 않는다', () {
      final storage = _FakeSettingsStorage();
      final container = _container(
        initial: ThemeMode.dark,
        storage: storage,
      );

      container.read(themeModeProvider.notifier).set(ThemeMode.dark);

      expect(storage.writeCount, 0);
    });

    test('셋을 오가도 마지막 값이 남는다', () {
      final storage = _FakeSettingsStorage();
      final container = _container(storage: storage);
      final notifier = container.read(themeModeProvider.notifier);

      notifier.set(ThemeMode.light);
      notifier.set(ThemeMode.dark);
      notifier.set(ThemeMode.system);

      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(storage.written, ThemeMode.system);
      expect(storage.writeCount, 3);
    });
  });
}
