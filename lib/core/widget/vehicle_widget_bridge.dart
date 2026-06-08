import 'package:flutter/services.dart';

import '../../shared/utils/relative_time.dart';
import '../database/app_models.dart';

class VehicleWidgetBridge {
  const VehicleWidgetBridge._();

  static const _channel = MethodChannel('moto_maintainance/vehicle_widget');

  static Future<String?> getSelectedVehicleId() async {
    final id = await _channel.invokeMethod<String>('getSelectedVehicleId');
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static Future<void> setSelectedVehicleId(String? vehicleId) {
    return _channel.invokeMethod<void>('setSelectedVehicleId', {
      'vehicleId': vehicleId,
    });
  }

  static Future<void> updateVehicleWidget(VehicleWidgetPayload payload) {
    return _channel.invokeMethod<void>('updateVehicleWidget', payload.toMap());
  }

  static Future<void> clearVehicleWidget() {
    return _channel.invokeMethod<void>('clearVehicleWidget');
  }

  static Future<String?> consumePendingOpenVehicleId() async {
    final id = await _channel.invokeMethod<String>(
      'consumePendingOpenVehicleId',
    );
    if (id == null || id.isEmpty) return null;
    return id;
  }
}

class VehicleWidgetPayload {
  const VehicleWidgetPayload({
    required this.vehicleId,
    required this.title,
    required this.subtitle,
    required this.reminderText,
    required this.reminderKind,
    required this.itemName,
    required this.dueAtMillis,
    required this.status,
    required this.imagePath,
  });

  final String vehicleId;
  final String title;
  final String subtitle;
  final String reminderText;
  final String reminderKind;
  final String itemName;
  final int? dueAtMillis;
  final String status;
  final String imagePath;

  Map<String, Object?> toMap() {
    return {
      'vehicleId': vehicleId,
      'title': title,
      'subtitle': subtitle,
      'reminderText': reminderText,
      'reminderKind': reminderKind,
      'itemName': itemName,
      'dueAtMillis': dueAtMillis,
      'status': status,
      'imagePath': imagePath,
    };
  }
}

VehicleWidgetPayload buildVehicleWidgetPayload(
  Vehicle vehicle,
  List<ItemReminder> reminders,
) {
  final title = vehicle.licensePlate.trim().isEmpty
      ? vehicle.name
      : '${vehicle.name} (${vehicle.licensePlate.trim()})';
  final subtitle =
      '${_formatKmValue(vehicle.currentKm)} km hiện tại • ${vehicle.dailyKm.toStringAsFixed(1)} km/ngày';

  if (reminders.isEmpty) {
    return VehicleWidgetPayload(
      vehicleId: vehicle.id,
      title: title,
      subtitle: subtitle,
      reminderText: 'Chưa có hạng mục bảo dưỡng.',
      reminderKind: 'noItems',
      itemName: '',
      dueAtMillis: null,
      status: ReminderStatus.ok.name,
      imagePath: vehicle.imagePath,
    );
  }

  final first = reminders.first;
  final dueDate = first.estimatedDueDate;
  final reminderText = dueDate == null
      ? 'Cần nhập km/ngày để tính bảo dưỡng tiếp theo • ${first.item.name}'
      : 'Bảo dưỡng tiếp theo: ${relativeDateLabel(dueDate)} • ${first.item.name}';

  return VehicleWidgetPayload(
    vehicleId: vehicle.id,
    title: title,
    subtitle: subtitle,
    reminderText: reminderText,
    reminderKind: dueDate == null ? 'missingDailyKm' : 'dueDate',
    itemName: first.item.name,
    dueAtMillis: dueDate?.millisecondsSinceEpoch,
    status: first.status.name,
    imagePath: vehicle.imagePath,
  );
}

String _formatKmValue(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}
