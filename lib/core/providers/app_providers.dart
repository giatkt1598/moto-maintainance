import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reminders/reminder_calculator.dart';
import '../database/app_database.dart';
import '../database/app_models.dart';
import '../notifications/notification_service.dart';
import '../settings/app_settings.dart';
import '../widget/vehicle_widget_bridge.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = AppDatabase();
  await database.initialize();
  ref.onDispose(database.close);
  return database;
});

final notificationServiceProvider = FutureProvider<NotificationService>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  final service = NotificationService(database);
  await service.initialize();
  return service;
});

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return database.getVehicles();
});

final vehicleProvider = FutureProvider.family<Vehicle?, String>((
  ref,
  id,
) async {
  final database = await ref.watch(databaseProvider.future);
  return database.getVehicle(id);
});

final maintenanceItemsProvider =
    FutureProvider.family<List<MaintenanceItem>, String>((
      ref,
      vehicleId,
    ) async {
      final database = await ref.watch(databaseProvider.future);
      return database.getItems(vehicleId);
    });

final serviceLogsProvider = FutureProvider.family<List<ServiceLog>, String>((
  ref,
  vehicleId,
) async {
  final database = await ref.watch(databaseProvider.future);
  return database.watchLogs(vehicleId).first;
});

final mileageLogsProvider = FutureProvider.family<List<MileageLog>, String>((
  ref,
  vehicleId,
) async {
  final database = await ref.watch(databaseProvider.future);
  return database.watchMileageLogs(vehicleId).first;
});

final itemRemindersProvider = FutureProvider.family<List<ItemReminder>, String>(
  (ref, vehicleId) async {
    final vehicle = await ref.watch(vehicleProvider(vehicleId).future);
    final items = await ref.watch(maintenanceItemsProvider(vehicleId).future);
    if (vehicle == null) return const [];
    return const ReminderCalculator().calculateItemReminders(vehicle, items);
  },
);

final serviceBatchesProvider =
    FutureProvider.family<List<ServiceBatch>, String>((ref, vehicleId) async {
      final vehicle = await ref.watch(vehicleProvider(vehicleId).future);
      final items = await ref.watch(maintenanceItemsProvider(vehicleId).future);
      if (vehicle == null) return const [];
      return const ReminderCalculator().groupBatches(vehicle, items);
    });

final appActionsProvider = Provider<AppActions>((ref) => AppActions(ref));

final selectedWidgetVehicleIdProvider = FutureProvider<String?>((ref) {
  return VehicleWidgetBridge.getSelectedVehicleId();
});

class AppActions {
  AppActions(this._ref);

  final Ref _ref;

  Future<String> createVehicle({
    required String name,
    required String licensePlate,
    required String imagePath,
    required VehicleProfile profile,
    required double currentKm,
    required double dailyKm,
    required int groupingWindowDays,
  }) async {
    final database = await _ref.read(databaseProvider.future);
    final id = await database.createVehicle(
      name: name,
      licensePlate: licensePlate,
      imagePath: imagePath,
      profile: profile,
      currentKm: currentKm,
      dailyKm: dailyKm,
      groupingWindowDays: groupingWindowDays,
    );
    await _reschedule(id);
    _invalidateVehicle(id);
    _ref.invalidate(vehiclesProvider);
    await _syncWidgetIfSelected(id);
    return id;
  }

  Future<void> updateVehicle({
    required String id,
    required String name,
    required String licensePlate,
    required String imagePath,
    required double currentKm,
    required double dailyKm,
    required int groupingWindowDays,
  }) async {
    final database = await _ref.read(databaseProvider.future);
    await database.updateVehicle(
      id: id,
      name: name,
      licensePlate: licensePlate,
      imagePath: imagePath,
      currentKm: currentKm,
      dailyKm: dailyKm,
      groupingWindowDays: groupingWindowDays,
    );
    await _reschedule(id);
    _invalidateVehicle(id);
    _ref.invalidate(vehiclesProvider);
    await _syncWidgetIfSelected(id);
  }

  Future<void> deleteVehicle(String id) async {
    final database = await _ref.read(databaseProvider.future);
    final notifications = await _ref.read(notificationServiceProvider.future);
    final selectedWidgetVehicleId =
        await VehicleWidgetBridge.getSelectedVehicleId();
    await notifications.cancelVehicle(id);
    await database.deleteVehicle(id);
    _invalidateVehicle(id);
    _ref.invalidate(vehiclesProvider);
    if (selectedWidgetVehicleId == id) {
      await VehicleWidgetBridge.setSelectedVehicleId(null);
      await VehicleWidgetBridge.clearVehicleWidget();
      _ref.invalidate(selectedWidgetVehicleIdProvider);
    }
  }

  Future<void> syncNotificationsForSettings(bool enabled) async {
    final database = await _ref.read(databaseProvider.future);
    final notifications = await _ref.read(notificationServiceProvider.future);
    final vehicles = await database.getVehicles();
    if (!enabled) {
      for (final vehicle in vehicles) {
        await notifications.cancelVehicle(vehicle.id);
      }
      return;
    }

    for (final vehicle in vehicles) {
      final items = await database.getItems(vehicle.id);
      await notifications.rescheduleVehicle(vehicle, items);
    }
  }

  Future<void> createItem({
    required String vehicleId,
    required String name,
    required String description,
    required int intervalMinKm,
    required int intervalMaxKm,
    required int intervalMinDays,
    required int intervalMaxDays,
    required double lastServiceKm,
    required DateTime lastServiceDate,
  }) async {
    final database = await _ref.read(databaseProvider.future);
    await database.createItem(
      vehicleId: vehicleId,
      name: name,
      description: description,
      intervalMinKm: intervalMinKm,
      intervalMaxKm: intervalMaxKm,
      intervalMinDays: intervalMinDays,
      intervalMaxDays: intervalMaxDays,
      lastServiceKm: lastServiceKm,
      lastServiceDate: lastServiceDate,
    );
    await _reschedule(vehicleId);
    _invalidateVehicle(vehicleId);
    await _syncWidgetIfSelected(vehicleId);
  }

  Future<void> updateItem(MaintenanceItem item) async {
    final database = await _ref.read(databaseProvider.future);
    await database.updateItem(
      id: item.id,
      name: item.name,
      description: item.description,
      intervalMinKm: item.intervalMinKm,
      intervalMaxKm: item.intervalMaxKm,
      intervalMinDays: item.intervalMinDays,
      intervalMaxDays: item.intervalMaxDays,
      lastServiceKm: item.lastServiceKm,
      lastServiceDate: item.lastServiceDate,
      isEnabled: item.isEnabled,
    );
    await _reschedule(item.vehicleId);
    _invalidateVehicle(item.vehicleId);
    await _syncWidgetIfSelected(item.vehicleId);
  }

  Future<void> deleteItem(MaintenanceItem item) async {
    final database = await _ref.read(databaseProvider.future);
    await database.deleteItem(item.id);
    await _reschedule(item.vehicleId);
    _invalidateVehicle(item.vehicleId);
    await _syncWidgetIfSelected(item.vehicleId);
  }

  Future<void> markCompleted({
    required Vehicle vehicle,
    required List<MaintenanceItem> items,
    String note = '',
  }) async {
    if (items.isEmpty) return;
    final database = await _ref.read(databaseProvider.future);
    await database.markItemsCompleted(
      vehicle: vehicle,
      items: items,
      note: note,
    );
    await _reschedule(vehicle.id);
    _invalidateVehicle(vehicle.id);
    await _syncWidgetIfSelected(vehicle.id);
  }

  Future<void> setWidgetVehicle(String? vehicleId) async {
    await VehicleWidgetBridge.setSelectedVehicleId(vehicleId);
    _ref.invalidate(selectedWidgetVehicleIdProvider);
    if (vehicleId == null || vehicleId.isEmpty) {
      await VehicleWidgetBridge.clearVehicleWidget();
      return;
    }
    await syncSelectedVehicleWidget();
  }

  Future<void> syncSelectedVehicleWidget() async {
    try {
      final selectedVehicleId =
          await VehicleWidgetBridge.getSelectedVehicleId();
      if (selectedVehicleId == null) {
        await VehicleWidgetBridge.clearVehicleWidget();
        return;
      }

      final database = await _ref.read(databaseProvider.future);
      final vehicle = await database.getVehicle(selectedVehicleId);
      if (vehicle == null) {
        await VehicleWidgetBridge.setSelectedVehicleId(null);
        await VehicleWidgetBridge.clearVehicleWidget();
        _ref.invalidate(selectedWidgetVehicleIdProvider);
        return;
      }

      final items = await database.getItems(vehicle.id);
      final reminders = const ReminderCalculator().calculateItemReminders(
        vehicle,
        items,
      );
      await VehicleWidgetBridge.updateVehicleWidget(
        buildVehicleWidgetPayload(vehicle, reminders),
      );
    } catch (_) {
      // Widget Android là phần phụ trợ; không để lỗi platform làm hỏng luồng app.
    }
  }

  Future<void> _reschedule(String vehicleId) async {
    final database = await _ref.read(databaseProvider.future);
    final vehicle = await database.getVehicle(vehicleId);
    if (vehicle == null) return;
    try {
      final settings = await _ref.read(settingsControllerProvider.future);
      final notifications = await _ref.read(notificationServiceProvider.future);
      if (!settings.notificationsEnabled) {
        await notifications.cancelVehicle(vehicleId);
        return;
      }
      final items = await database.getItems(vehicleId);
      await notifications.rescheduleVehicle(vehicle, items);
    } catch (_) {
      // Không để lỗi notification làm hỏng thao tác lưu dữ liệu bảo dưỡng.
    }
  }

  void _invalidateVehicle(String vehicleId) {
    _ref.invalidate(vehicleProvider(vehicleId));
    _ref.invalidate(maintenanceItemsProvider(vehicleId));
    _ref.invalidate(itemRemindersProvider(vehicleId));
    _ref.invalidate(serviceBatchesProvider(vehicleId));
    _ref.invalidate(serviceLogsProvider(vehicleId));
    _ref.invalidate(mileageLogsProvider(vehicleId));
  }

  Future<void> _syncWidgetIfSelected(String vehicleId) async {
    try {
      final selectedVehicleId =
          await VehicleWidgetBridge.getSelectedVehicleId();
      if (selectedVehicleId == vehicleId) {
        await syncSelectedVehicleWidget();
      }
    } catch (_) {
      // Bỏ qua lỗi platform widget để thao tác chính vẫn hoàn tất.
    }
  }
}
