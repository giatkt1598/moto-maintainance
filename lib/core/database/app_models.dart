enum VehicleProfile {
  scooter,
  manualClutch,
  underbone,
  electricMotorbike,
  bicycle,
  other;

  String get label {
    return switch (this) {
      VehicleProfile.scooter => 'Xe ga',
      VehicleProfile.manualClutch => 'Xe tay côn',
      VehicleProfile.underbone => 'Xe số',
      VehicleProfile.electricMotorbike => 'Xe máy điện',
      VehicleProfile.bicycle => 'Xe đạp',
      VehicleProfile.other => 'Khác',
    };
  }
}

enum ReminderStatus { ok, dueSoon, due, overdue, missingDailyKm }

class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.licensePlate,
    required this.imagePath,
    required this.profile,
    required this.currentKm,
    required this.dailyKm,
    required this.groupingWindowDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String licensePlate;
  final String imagePath;
  final VehicleProfile profile;
  final double currentKm;
  final double dailyKm;
  final int groupingWindowDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.vehicleId,
    required this.name,
    required this.description,
    required this.intervalMinKm,
    required this.intervalMaxKm,
    required this.intervalMinDays,
    required this.intervalMaxDays,
    required this.lastServiceKm,
    required this.lastServiceDate,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String vehicleId;
  final String name;
  final String description;
  final int intervalMinKm;
  final int intervalMaxKm;
  final int intervalMinDays;
  final int intervalMaxDays;
  final double lastServiceKm;
  final DateTime? lastServiceDate;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get midpointKm => ((intervalMinKm + intervalMaxKm) / 2).round();
  int get midpointDays => ((intervalMinDays + intervalMaxDays) / 2).round();
  bool get hasKmInterval => intervalMaxKm > 0;
  bool get hasTimeInterval => intervalMaxDays > 0;
}

class ServiceLog {
  const ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.itemId,
    required this.itemName,
    required this.serviceKm,
    required this.serviceDate,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String itemId;
  final String itemName;
  final double serviceKm;
  final DateTime serviceDate;
  final String note;
  final DateTime createdAt;
}

class ItemReminder {
  const ItemReminder({
    required this.item,
    required this.status,
    required this.nextDueKm,
    required this.overdueKm,
    required this.remainingKm,
    required this.estimatedDueDate,
    required this.overdueDate,
  });

  final MaintenanceItem item;
  final ReminderStatus status;
  final double nextDueKm;
  final double overdueKm;
  final double remainingKm;
  final DateTime? estimatedDueDate;
  final DateTime? overdueDate;
}

class ServiceBatch {
  const ServiceBatch({
    required this.vehicle,
    required this.reminders,
    required this.scheduledDate,
  });

  final Vehicle vehicle;
  final List<ItemReminder> reminders;
  final DateTime? scheduledDate;
}
