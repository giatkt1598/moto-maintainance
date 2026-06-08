import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  vi('Tiếng Việt', Locale('vi')),
  en('English', Locale('en'));

  const AppLanguage(this.label, this.locale);

  final String label;
  final Locale locale;
}

class AppSettings {
  const AppSettings({
    required this.darkMode,
    required this.notificationsEnabled,
    required this.language,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      darkMode: false,
      notificationsEnabled: true,
      language: AppLanguage.vi,
    );
  }

  final bool darkMode;
  final bool notificationsEnabled;
  final AppLanguage language;

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  AppSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    AppLanguage? language,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  static const _darkModeKey = 'settings.dark_mode';
  static const _notificationsKey = 'settings.notifications_enabled';
  static const _languageKey = 'settings.language';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    final languageName = prefs.getString(_languageKey);
    return AppSettings(
      darkMode: prefs.getBool(_darkModeKey) ?? defaults.darkMode,
      notificationsEnabled:
          prefs.getBool(_notificationsKey) ?? defaults.notificationsEnabled,
      language: _languageFromName(languageName) ?? defaults.language,
    );
  }

  Future<void> setDarkMode(bool enabled) async {
    await _update((settings) => settings.copyWith(darkMode: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _update(
      (settings) => settings.copyWith(notificationsEnabled: enabled),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _update((settings) => settings.copyWith(language: language));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }

  Future<void> _update(
    AppSettings Function(AppSettings settings) update,
  ) async {
    final current = state.value ?? await future;
    state = AsyncData(update(current));
  }

  AppLanguage? _languageFromName(String? name) {
    if (name == null) return null;
    for (final language in AppLanguage.values) {
      if (language.name == name) return language;
    }
    return null;
  }
}

Future<bool> areNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(SettingsController._notificationsKey) ??
      AppSettings.defaults().notificationsEnabled;
}
