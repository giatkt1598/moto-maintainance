import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/background/daily_mileage_service.dart';
import 'core/background/daily_mileage_worker.dart';
import 'core/settings/app_settings.dart';
import 'core/widget/vehicle_widget_bridge.dart';
import 'features/vehicles/home_screen.dart';
import 'features/vehicles/vehicle_detail_screen.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDailyMileageWorker();
  await const DailyMileageService().applyIfNeeded();
  runApp(const ProviderScope(child: MotoMaintainanceApp()));
}

final appNavigatorKey = GlobalKey<NavigatorState>();

class MotoMaintainanceApp extends ConsumerStatefulWidget {
  const MotoMaintainanceApp({super.key});

  @override
  ConsumerState<MotoMaintainanceApp> createState() =>
      _MotoMaintainanceAppState();
}

class _MotoMaintainanceAppState extends ConsumerState<MotoMaintainanceApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingWidgetVehicle();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _openPendingWidgetVehicle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsControllerProvider).value ?? AppSettings.defaults();
    return MaterialApp(
      navigatorKey: appNavigatorKey,
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

  Future<void> _openPendingWidgetVehicle() async {
    final vehicleId = await VehicleWidgetBridge.consumePendingOpenVehicleId();
    if (vehicleId == null) return;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => VehicleDetailScreen(vehicleId: vehicleId),
      ),
    );
  }
}
