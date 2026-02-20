import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String imageQuality; // 'High', 'Medium'
  final bool autoCrop;
  final String ocrLanguage; // 'latin', 'korean', 'japanese', 'chinese', 'devanagari'
  final String locale; // 'en', 'ko', 'ja'

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.imageQuality = 'High',
    this.autoCrop = true,
    this.ocrLanguage = 'latin',
    this.locale = 'en',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? imageQuality,
    bool? autoCrop,
    String? ocrLanguage,
    String? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      imageQuality: imageQuality ?? this.imageQuality,
      autoCrop: autoCrop ?? this.autoCrop,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Box _box;

  SettingsNotifier(this._box) : super(const AppSettings()) {
    _load();
  }

  void _load() {
    final themeName = _box.get('themeMode', defaultValue: 'dark') as String;
    final quality = _box.get('imageQuality', defaultValue: 'High') as String;
    final autoCrop = _box.get('autoCrop', defaultValue: true) as bool;
    final ocrLang = _box.get('ocrLanguage', defaultValue: 'latin') as String;
    final locale = _box.get('locale', defaultValue: 'en') as String;

    state = AppSettings(
      themeMode: themeName == 'light' ? ThemeMode.light : (themeName == 'system' ? ThemeMode.system : ThemeMode.dark),
      imageQuality: quality,
      autoCrop: autoCrop,
      ocrLanguage: ocrLang,
      locale: locale,
    );
  }

  void setThemeMode(ThemeMode mode) {
    final name = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.system ? 'system' : 'dark');
    _box.put('themeMode', name);
    state = state.copyWith(themeMode: mode);
  }

  void setImageQuality(String quality) {
    _box.put('imageQuality', quality);
    state = state.copyWith(imageQuality: quality);
  }

  void setAutoCrop(bool value) {
    _box.put('autoCrop', value);
    state = state.copyWith(autoCrop: value);
  }

  void setOcrLanguage(String language) {
    _box.put('ocrLanguage', language);
    state = state.copyWith(ocrLanguage: language);
  }

  void setLocale(String locale) {
    _box.put('locale', locale);
    state = state.copyWith(locale: locale);
  }
}

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box('settings');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return SettingsNotifier(box);
});
