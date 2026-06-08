import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_value_view.dart';

class ServiceLogsScreen extends ConsumerWidget {
  const ServiceLogsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(serviceLogsProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử bảo trì')),
      body: AsyncValueView(
        value: logs,
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có lịch sử.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = items[index];
              return Card(
                child: ListTile(
                  title: Text(log.itemName),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(log.serviceDate)} • ${log.serviceKm} km'
                    '${log.note.isEmpty ? '' : ' • ${log.note}'}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
