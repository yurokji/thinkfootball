import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';

void main() {
  late Box box;

  setUpAll(() async {
    Hive.init('./test_hive');
  });

  setUp(() async {
    box = await Hive.openBox('test_settings_${DateTime.now().millisecondsSinceEpoch}');
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('SettingsNotifier', () {
    test('initializes with defaults', () {
      final notifier = SettingsNotifier(box);
      expect(notifier.state.themeMode, ThemeMode.dark);
      expect(notifier.state.imageQuality, 'High');
      expect(notifier.state.autoCrop, true);
      expect(notifier.state.ocrLanguage, 'latin');
    });

    test('setThemeMode persists and updates state', () {
      final notifier = SettingsNotifier(box);
      notifier.setThemeMode(ThemeMode.light);

      expect(notifier.state.themeMode, ThemeMode.light);
      expect(box.get('themeMode'), 'light');
    });

    test('setImageQuality persists and updates state', () {
      final notifier = SettingsNotifier(box);
      notifier.setImageQuality('Medium');

      expect(notifier.state.imageQuality, 'Medium');
      expect(box.get('imageQuality'), 'Medium');
    });

    test('setAutoCrop persists and updates state', () {
      final notifier = SettingsNotifier(box);
      notifier.setAutoCrop(false);

      expect(notifier.state.autoCrop, false);
      expect(box.get('autoCrop'), false);
    });

    test('setOcrLanguage persists and updates state', () {
      final notifier = SettingsNotifier(box);
      notifier.setOcrLanguage('korean');

      expect(notifier.state.ocrLanguage, 'korean');
      expect(box.get('ocrLanguage'), 'korean');
    });

    test('loads persisted values on init', () async {
      await box.put('themeMode', 'light');
      await box.put('imageQuality', 'Medium');
      await box.put('autoCrop', false);
      await box.put('ocrLanguage', 'japanese');

      final notifier = SettingsNotifier(box);
      expect(notifier.state.themeMode, ThemeMode.light);
      expect(notifier.state.imageQuality, 'Medium');
      expect(notifier.state.autoCrop, false);
      expect(notifier.state.ocrLanguage, 'japanese');
    });

    test('system theme mode persists correctly', () {
      final notifier = SettingsNotifier(box);
      notifier.setThemeMode(ThemeMode.system);

      expect(notifier.state.themeMode, ThemeMode.system);
      expect(box.get('themeMode'), 'system');
    });
  });

  group('AppSettings', () {
    test('copyWith returns new instance with changed fields', () {
      const original = AppSettings();
      final modified = original.copyWith(themeMode: ThemeMode.light, ocrLanguage: 'korean');

      expect(modified.themeMode, ThemeMode.light);
      expect(modified.ocrLanguage, 'korean');
      expect(modified.imageQuality, 'High'); // unchanged
      expect(modified.autoCrop, true); // unchanged
    });

    test('copyWith with no args returns equivalent copy', () {
      const original = AppSettings(imageQuality: 'Medium');
      final copy = original.copyWith();

      expect(copy.imageQuality, 'Medium');
      expect(copy.themeMode, ThemeMode.dark);
    });
  });
}
