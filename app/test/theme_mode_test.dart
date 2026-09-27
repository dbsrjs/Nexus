import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/features/settings/theme_controller.dart';

/// 실제 안전 저장소를 건드리지 않는다. `implements` 로 만들어 private 필드를
/// 상속하지 않는다.
class _FakeSettingsStorage implements SettingsStorage {
  ThemePreference? written;
  int writeCount = 0;

  @override
  Future<ThemePreference> readThemePreference() async => ThemePreference.system;

  @override
  Future<void> writeThemePreference(ThemePreference mode) async {
    written = mode;
    writeCount++;
  }
}

ProviderContainer _container({
  ThemePreference initial = ThemePreference.system,
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
      expect(container.read(themeModeProvider), ThemePreference.system);
    });

    test('앱을 켤 때 읽은 값에서 시작한다', () {
      // main() 이 runApp 앞에서 읽어 override 로 넣는 값이다. 이것이 없으면
      // 첫 프레임이 시스템 테마로 그려졌다가 바뀌어 깜빡인다.
      final container = _container(
        initial: ThemePreference.light,
        storage: _FakeSettingsStorage(),
      );
      expect(container.read(themeModeProvider), ThemePreference.light);
    });

    test('바꾸면 곧바로 반영되고 저장된다', () async {
      final storage = _FakeSettingsStorage();
      final container = _container(storage: storage);

      container.read(themeModeProvider.notifier).set(ThemePreference.dark);

      expect(container.read(themeModeProvider), ThemePreference.dark);
      expect(storage.written, ThemePreference.dark);
    });

    test('같은 값을 다시 고르면 저장하지 않는다', () {
      final storage = _FakeSettingsStorage();
      final container = _container(
        initial: ThemePreference.dark,
        storage: storage,
      );

      container.read(themeModeProvider.notifier).set(ThemePreference.dark);

      expect(storage.writeCount, 0);
    });

    test('셋을 오가도 마지막 값이 남는다', () {
      final storage = _FakeSettingsStorage();
      final container = _container(storage: storage);
      final notifier = container.read(themeModeProvider.notifier);

      notifier.set(ThemePreference.light);
      notifier.set(ThemePreference.dark);
      notifier.set(ThemePreference.system);

      expect(container.read(themeModeProvider), ThemePreference.system);
      expect(storage.written, ThemePreference.system);
      expect(storage.writeCount, 3);
    });
  });
}
