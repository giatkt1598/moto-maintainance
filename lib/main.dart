import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/background/daily_mileage_service.dart';
import 'core/background/daily_mileage_worker.dart';
import 'core/settings/app_settings.dart';
import 'features/vehicles/home_screen.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDailyMileageWorker();
  await const DailyMileageService().applyIfNeeded();
  runApp(const ProviderScope(child: MotoMaintainanceApp()));
}

class MotoMaintainanceApp extends ConsumerWidget {
  const MotoMaintainanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsControllerProvider).value ?? AppSettings.defaults();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bảo dưỡng xe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.language.locale,
      supportedLocales: AppLanguage.values
          .map((language) => language.locale)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
