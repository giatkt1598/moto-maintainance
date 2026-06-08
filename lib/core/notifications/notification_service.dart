import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/reminder_calculator.dart';
import '../database/app_database.dart';
import '../database/app_models.dart';

class NotificationService {
  NotificationService(this._database);

  final AppDatabase _database;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  Future<void> rescheduleVehicle(
    Vehicle vehicle,
    List<MaintenanceItem> items,
  ) async {
    await initialize();
    final oldIds = await _database.getNotificationIds(vehicle.id);
    for (final id in oldIds) {
      await _plugin.cancel(id: id);
    }

    final batches = const ReminderCalculator().groupBatches(vehicle, items);
    final records = <ScheduledReminderRecord>[];
    for (var i = 0; i < batches.length; i++) {
      final batch = batches[i];
      if (batch.scheduledDate == null) continue;
      final notificationId = _stableNotificationId(vehicle.id, i);
      final scheduledAt = _atEight(batch.scheduledDate!);
      final title = '${vehicle.name}: đến lịch bảo dưỡng';
      final names = batch.reminders.map((item) => item.item.name).join(', ');
      final body = 'Nên làm chung: $names';

      if (scheduledAt.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'maintenance_reminders',
              'Bảo dưỡng xe',
              channelDescription: 'Nhắc thay thế và kiểm tra phụ tùng định kỳ',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      records.add(
        ScheduledReminderRecord(
          notificationId: notificationId,
          scheduledAt: scheduledAt,
          title: title,
          body: body,
        ),
      );
    }

    await _database.replaceScheduledReminders(
      vehicleId: vehicle.id,
      records: records,
    );
  }

  Future<void> cancelVehicle(String vehicleId) async {
    await initialize();
    final oldIds = await _database.getNotificationIds(vehicleId);
    for (final id in oldIds) {
      await _plugin.cancel(id: id);
    }
    await _database.replaceScheduledReminders(
      vehicleId: vehicleId,
      records: const [],
    );
  }

  int _stableNotificationId(String vehicleId, int index) {
    return (vehicleId.hashCode ^ index.hashCode).abs() % 2147483647;
  }

  DateTime _atEight(DateTime date) =>
      DateTime(date.year, date.month, date.day, 8);
}
