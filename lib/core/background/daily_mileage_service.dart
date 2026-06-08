import '../database/app_database.dart';
import '../notifications/notification_service.dart';
import '../settings/app_settings.dart';

class DailyMileageService {
  const DailyMileageService();

  Future<void> applyIfNeeded() async {
    final database = AppDatabase();
    try {
      await database.initialize();
      final changedVehicleIds = await database.applyDailyMileageIfNeeded();
      if (changedVehicleIds.isEmpty) return;
      if (!await areNotificationsEnabled()) return;

      final notifications = NotificationService(database);
      for (final vehicleId in changedVehicleIds) {
        final vehicle = await database.getVehicle(vehicleId);
        if (vehicle == null) continue;
        final items = await database.getItems(vehicleId);
        try {
          await notifications.rescheduleVehicle(vehicle, items);
        } catch (_) {
          // Không để lỗi notification chặn việc cộng km tự động.
        }
      }
    } finally {
      await database.close();
    }
  }
}
