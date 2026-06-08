import '../../core/database/app_models.dart';

class ReminderCalculator {
  const ReminderCalculator();

  List<ItemReminder> calculateItemReminders(
    Vehicle vehicle,
    List<MaintenanceItem> items, {
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    return items.where((item) => item.isEnabled).map((item) {
      final hasKm = item.hasKmInterval;
      final hasTime = item.hasTimeInterval;
      final nextDueKm = hasKm
          ? item.lastServiceKm + item.midpointKm
          : item.lastServiceKm;
      final overdueKm = hasKm
          ? item.lastServiceKm + item.intervalMaxKm
          : item.lastServiceKm;
      final remainingKm = hasKm ? nextDueKm - vehicle.currentKm : 0;
      final kmOverdue = hasKm && vehicle.currentKm >= overdueKm;
      final kmDue = hasKm && remainingKm <= 0;
      final DateTime? kmDueDate = hasKm && vehicle.dailyKm > 0
          ? today.add(
              Duration(
                days: remainingKm <= 0
                    ? 0
                    : (remainingKm / vehicle.dailyKm).ceil(),
              ),
            )
          : null;
      final baseDate = item.lastServiceDate == null
          ? null
          : _dateOnly(item.lastServiceDate!);
      final timeDueDate = hasTime && baseDate != null
          ? baseDate.add(Duration(days: item.midpointDays))
          : null;
      final overdueDate = hasTime && baseDate != null
          ? baseDate.add(Duration(days: item.intervalMaxDays))
          : null;
      DateTime? estimatedDueDate;
      ReminderStatus status;

      estimatedDueDate = _earliestDate(kmDueDate, timeDueDate);
      final timeOverdue = overdueDate != null && !today.isBefore(overdueDate);
      final timeDue = timeDueDate != null && !today.isBefore(timeDueDate);

      if (hasKm && !hasTime && vehicle.dailyKm <= 0) {
        status = ReminderStatus.missingDailyKm;
      } else {
        if (kmOverdue || timeOverdue) {
          status = ReminderStatus.overdue;
        } else if (kmDue || timeDue) {
          status = ReminderStatus.due;
        } else if (estimatedDueDate != null &&
            estimatedDueDate.difference(today).inDays <=
                vehicle.groupingWindowDays) {
          status = ReminderStatus.dueSoon;
        } else {
          status = ReminderStatus.ok;
        }
      }

      return ItemReminder(
        item: item,
        status: status,
        nextDueKm: nextDueKm,
        overdueKm: overdueKm,
        remainingKm: remainingKm,
        estimatedDueDate: estimatedDueDate,
        overdueDate: overdueDate,
      );
    }).toList()..sort((a, b) {
      final aDate = a.estimatedDueDate;
      final bDate = b.estimatedDueDate;
      if (aDate == null && bDate == null) {
        return a.nextDueKm.compareTo(b.nextDueKm);
      }
      if (aDate == null) {
        return 1;
      }
      if (bDate == null) {
        return -1;
      }
      return aDate.compareTo(bDate);
    });
  }

  List<ServiceBatch> groupBatches(
    Vehicle vehicle,
    List<MaintenanceItem> items, {
    DateTime? now,
  }) {
    final reminders = calculateItemReminders(
      vehicle,
      items,
      now: now,
    ).where((reminder) => reminder.status != ReminderStatus.ok).toList();
    final batches = <ServiceBatch>[];
    final undated = reminders
        .where((item) => item.estimatedDueDate == null)
        .toList();
    final dated = reminders
        .where((item) => item.estimatedDueDate != null)
        .toList();

    if (undated.isNotEmpty) {
      batches.add(
        ServiceBatch(vehicle: vehicle, reminders: undated, scheduledDate: null),
      );
    }

    var index = 0;
    while (index < dated.length) {
      final first = dated[index];
      final windowEnd = first.estimatedDueDate!.add(
        Duration(days: vehicle.groupingWindowDays),
      );
      final group = <ItemReminder>[first];
      index++;

      while (index < dated.length) {
        final next = dated[index];
        if (next.estimatedDueDate!.isAfter(windowEnd)) break;
        group.add(next);
        index++;
      }

      batches.add(
        ServiceBatch(
          vehicle: vehicle,
          reminders: group,
          scheduledDate: first.estimatedDueDate,
        ),
      );
    }

    return batches;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime? _earliestDate(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isBefore(second) ? first : second;
  }
}

String reminderStatusLabel(ReminderStatus status) {
  return switch (status) {
    ReminderStatus.ok => 'Đúng lịch',
    ReminderStatus.dueSoon => 'Sắp đến hạn',
    ReminderStatus.due => 'Đến hạn',
    ReminderStatus.overdue => 'Quá hạn',
    ReminderStatus.missingDailyKm => 'Cần nhập km/ngày',
  };
}
