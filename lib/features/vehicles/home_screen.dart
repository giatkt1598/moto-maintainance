import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/relative_time.dart';
import '../../shared/widgets/async_value_view.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảo trì xe máy'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => ref.invalidate(vehiclesProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Thêm xe',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AsyncValueView(
        value: vehicles,
        data: (items) {
          if (items.isEmpty) return const _EmptyHome();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _VehicleCard(vehicle: items[index]),
          );
        },
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.two_wheeler,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có xe',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm xe đầu tiên để tạo lịch nhắc thay nhớt và phụ tùng.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(itemRemindersProvider(vehicle.id));
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicle.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(label: Text(vehicle.profile.label)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${vehicle.currentKm} km hiện tại • ${vehicle.dailyKm.toStringAsFixed(1)} km/ngày',
              ),
              const SizedBox(height: 12),
              reminders.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('Chưa có hạng mục bảo trì.');
                  }
                  final first = items.first;
                  final date = first.estimatedDueDate;
                  final label = date == null
                      ? 'Cần nhập km/ngày để tính bảo dưỡng tiếp theo'
                      : 'Bảo dưỡng tiếp theo: ${relativeDateLabel(date)}';
                  return Row(
                    children: [
                      Icon(
                        _statusIcon(first.status),
                        color: _statusColor(context, first.status),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$label • ${first.item.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Có lỗi: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _statusIcon(ReminderStatus status) {
  return switch (status) {
    ReminderStatus.ok => Icons.check_circle,
    ReminderStatus.dueSoon => Icons.schedule,
    ReminderStatus.due => Icons.notifications_active,
    ReminderStatus.overdue => Icons.warning,
    ReminderStatus.missingDailyKm => Icons.help,
  };
}

Color _statusColor(BuildContext context, ReminderStatus status) {
  return switch (status) {
    ReminderStatus.ok => Colors.green,
    ReminderStatus.dueSoon => Theme.of(context).colorScheme.primary,
    ReminderStatus.due => Colors.orange,
    ReminderStatus.overdue => Theme.of(context).colorScheme.error,
    ReminderStatus.missingDailyKm => Colors.grey,
  };
}
