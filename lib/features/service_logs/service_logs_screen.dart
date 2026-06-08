import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_value_view.dart';

class ServiceLogsScreen extends ConsumerWidget {
  const ServiceLogsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(serviceLogsProvider(vehicleId));
    final mileageLogs = ref.watch(mileageLogsProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử bảo dưỡng')),
      body: AsyncValueView(
        value: logs,
        data: (serviceItems) => AsyncValueView(
          value: mileageLogs,
          data: (mileageItems) {
            final items = <_HistoryEntry>[
              ...serviceItems.map(_HistoryEntry.service),
              ...mileageItems.map(_HistoryEntry.mileage),
            ]..sort((a, b) => b.date.compareTo(a.date));

            if (items.isEmpty) {
              return const Center(child: Text('Chưa có lịch sử.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Card(child: items[index].buildTile(context));
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryEntry {
  _HistoryEntry.service(ServiceLog log)
    : serviceLog = log,
      mileageLog = null,
      date = log.serviceDate;

  _HistoryEntry.mileage(MileageLog log)
    : serviceLog = null,
      mileageLog = log,
      date = log.createdAt;

  final ServiceLog? serviceLog;
  final MileageLog? mileageLog;
  final DateTime date;

  Widget buildTile(BuildContext context) {
    final service = serviceLog;
    if (service != null) {
      return ListTile(
        leading: const Icon(Icons.build_outlined),
        title: Text(service.itemName),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy').format(service.serviceDate)} • ${_formatKmValue(service.serviceKm)} km'
          '${service.note.isEmpty ? '' : ' • ${service.note}'}',
        ),
      );
    }

    final mileage = mileageLog!;
    final isIncrease = mileage.deltaKm > 0;
    final deltaText =
        '${isIncrease ? '+' : ''}${_formatKmValue(mileage.deltaKm)} km';
    return ListTile(
      leading: Icon(
        isIncrease ? Icons.add_road : Icons.remove_road,
        color: isIncrease
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
      title: Text('Cập nhật km hiện tại ($deltaText)'),
      subtitle: Text(
        '${DateFormat('dd/MM/yyyy').format(mileage.createdAt)} • '
        '${_formatKmValue(mileage.previousKm)} km -> ${_formatKmValue(mileage.currentKm)} km',
      ),
    );
  }
}

String _formatKmValue(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}
