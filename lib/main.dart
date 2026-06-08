import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/background/daily_mileage_service.dart';
import 'core/background/daily_mileage_worker.dart';
import 'features/vehicles/home_screen.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDailyMileageWorker();
  await const DailyMileageService().applyIfNeeded();
  runApp(const ProviderScope(child: MotoMaintainanceApp()));
}

class MotoMaintainanceApp extends StatelessWidget {
  const MotoMaintainanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bảo trì xe máy',
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
