import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/settings/app_settings.dart';
import '../../features/settings/settings_screen.dart';
import '../../shared/utils/relative_time.dart';
import '../../shared/widgets/async_value_view.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    final language =
        ref.watch(settingsControllerProvider).value?.language ?? AppLanguage.vi;
    final text = _HomeText(language);
    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          IconButton(
            tooltip: text.refresh,
            onPressed: () => ref.invalidate(vehiclesProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: text.settings,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            tooltip: text.addVehicle,
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(appActionsProvider).syncSelectedVehicleWidget();
          });
          if (items.isEmpty) return _EmptyHome(text: text);
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
  const _EmptyHome({required this.text});

  final _HomeText text;

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
              text.emptyTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(text.emptyDescription, textAlign: TextAlign.center),
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
    final photo = vehicle.imagePath.isEmpty ? null : File(vehicle.imagePath);
    final hasPhoto = photo != null && photo.existsSync();
    final imageOverlayColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0x99000000)
        : const Color(0x99FFFFFF);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: Ink(
        decoration: BoxDecoration(
          image: hasPhoto
              ? DecorationImage(image: FileImage(photo), fit: BoxFit.cover)
              : null,
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id),
            ),
          ),
          child: Stack(
            children: [
              if (hasPhoto)
                Positioned.fill(child: ColoredBox(color: imageOverlayColor)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _VehicleNameWithPlate(
                      name: vehicle.name,
                      licensePlate: vehicle.licensePlate,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatKmValue(vehicle.currentKm)} km hiện tại • ${vehicle.dailyKm.toStringAsFixed(1)} km/ngày',
                    ),
                    const SizedBox(height: 12),
                    reminders.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const Text('Chưa có hạng mục bảo dưỡng.');
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

class _HomeText {
  const _HomeText(this.language);

  final AppLanguage language;

  bool get _en => language == AppLanguage.en;

  String get title => _en ? 'Vehicle care' : 'Bảo dưỡng xe';
  String get refresh => _en ? 'Refresh' : 'Tải lại';
  String get settings => _en ? 'Settings' : 'Cài đặt';
  String get addVehicle => _en ? 'Add vehicle' : 'Thêm xe';
  String get emptyTitle => _en ? 'No vehicles' : 'Chưa có xe';
  String get emptyDescription => _en
      ? 'Add your first vehicle to create oil and parts maintenance reminders.'
      : 'Thêm xe đầu tiên để tạo lịch nhắc thay nhớt và phụ tùng.';
}

class _VehicleNameWithPlate extends StatelessWidget {
  const _VehicleNameWithPlate({
    required this.name,
    required this.licensePlate,
    required this.style,
  });

  final String name;
  final String licensePlate;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final plate = licensePlate.trim();
    if (plate.isEmpty) {
      return Text(name, style: style);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: name),
          TextSpan(
            text: ' ($plate)',
            style: style?.copyWith(
              fontSize: (style?.fontSize ?? 22) * 0.82,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

String _formatKmValue(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}
