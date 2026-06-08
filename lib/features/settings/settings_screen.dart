import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/settings/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsValue = ref.watch(settingsControllerProvider);
    final settings = settingsValue.value ?? AppSettings.defaults();
    final controller = ref.read(settingsControllerProvider.notifier);
    final text = _SettingsText(settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(text.darkMode),
                  subtitle: Text(text.darkModeDescription),
                  value: settings.darkMode,
                  onChanged: settingsValue.isLoading
                      ? null
                      : (value) => controller.setDarkMode(value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(text.notifications),
                  subtitle: Text(text.notificationsDescription),
                  value: settings.notificationsEnabled,
                  onChanged: settingsValue.isLoading
                      ? null
                      : (value) async {
                          await controller.setNotificationsEnabled(value);
                          await ref
                              .read(appActionsProvider)
                              .syncNotificationsForSettings(value);
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(text.languageLabel),
                  subtitle: Text(settings.language.label),
                  trailing: DropdownButton<AppLanguage>(
                    value: settings.language,
                    underline: const SizedBox.shrink(),
                    items: AppLanguage.values
                        .map(
                          (language) => DropdownMenuItem(
                            value: language,
                            child: Text(language.label),
                          ),
                        )
                        .toList(),
                    onChanged: settingsValue.isLoading
                        ? null
                        : (value) {
                            if (value == null) return;
                            controller.setLanguage(value);
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsText {
  const _SettingsText(this.language);

  final AppLanguage language;

  bool get _en => language == AppLanguage.en;

  String get title => _en ? 'Settings' : 'Cài đặt';
  String get darkMode => _en ? 'DarkMode' : 'DarkMode';
  String get darkModeDescription =>
      _en ? 'Switch between light and dark theme' : 'Đổi giao diện sáng/tối';
  String get notifications => _en ? 'Enable notifications' : 'Bật thông báo';
  String get notificationsDescription => _en
      ? 'Notify scheduled maintenance reminders'
      : 'Nhắc lịch bảo dưỡng đã lên lịch';
  String get languageLabel => _en ? 'Language' : 'Ngôn ngữ';
}
