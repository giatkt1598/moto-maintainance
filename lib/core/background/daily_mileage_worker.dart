import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'daily_mileage_service.dart';

const dailyMileageTaskName = 'daily_mileage_update';

@pragma('vm:entry-point')
void dailyMileageCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == dailyMileageTaskName) {
      await const DailyMileageService().applyIfNeeded();
    }
    return true;
  });
}

Future<void> initializeDailyMileageWorker() async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

  try {
    await Workmanager().initialize(dailyMileageCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      dailyMileageTaskName,
      dailyMileageTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilAfterMidnight(),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } on PlatformException {
    // Workmanager không có native channel trên một số target debug như desktop.
    // Catch-up trong main vẫn xử lý cộng km khi app được mở.
  }
}

Duration _delayUntilAfterMidnight() {
  final now = DateTime.now();
  final nextRun = DateTime(now.year, now.month, now.day + 1, 0, 5);
  return nextRun.difference(now);
}
