import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SettingsNotifier extends Notifier<AppSettings> {
  late final SharedPreferences _prefs;

  @override
  AppSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadFromPrefs();
  }

  AppSettings _loadFromPrefs() {
    final themeName = _prefs.getString('themeMode') ?? 'dark';
    final quality = _prefs.getString('imageQuality') ?? 'High';
    final autoCrop = _prefs.getBool('autoCrop') ?? true;
    final locale = _prefs.getString('locale') ?? 'en';
    final ocrLang = _prefs.getString('ocrLanguage') ?? _defaultOcrForLocale(locale);

    return AppSettings(
      themeMode: themeName == 'light' ? ThemeMode.light : (themeName == 'system' ? ThemeMode.system : ThemeMode.dark),
      imageQuality: quality,
      autoCrop: autoCrop,
      ocrLanguage: ocrLang,
      locale: locale,
    );
  }

  void setThemeMode(ThemeMode mode) {
    final name = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.system ? 'system' : 'dark');
    _prefs.setString('themeMode', name);
    state = state.copyWith(themeMode: mode);
  }

  void setImageQuality(String quality) {
    _prefs.setString('imageQuality', quality);
    state = state.copyWith(imageQuality: quality);
  }

  void setAutoCrop(bool value) {
    _prefs.setBool('autoCrop', value);
    state = state.copyWith(autoCrop: value);
  }

  void setOcrLanguage(String language) {
    _prefs.setString('ocrLanguage', language);
    state = state.copyWith(ocrLanguage: language);
  }

  void setLocale(String locale) {
    _prefs.setString('locale', locale);
    // OCR 언어를 사용자가 수동 설정한 적 없으면 locale에 맞춰 자동 변경
    if (!_prefs.containsKey('ocrLanguage')) {
      state = state.copyWith(locale: locale, ocrLanguage: _defaultOcrForLocale(locale));
    } else {
      state = state.copyWith(locale: locale);
    }
  }
}

String _defaultOcrForLocale(String locale) {
  switch (locale) {
    case 'ko': return 'korean';
    case 'ja': return 'japanese';
    case 'zh': return 'chinese';
    case 'hi': return 'devanagari';
    default: return 'latin';
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden at startup');
});

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
