import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/database/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../features/maintenance_items/maintenance_item_form_screen.dart';
import '../../features/reminders/reminder_calculator.dart';
import '../../features/service_logs/service_logs_screen.dart';
import '../../shared/utils/relative_time.dart';
import '../../shared/widgets/async_value_view.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleValue = ref.watch(vehicleProvider(vehicleId));
    return AsyncValueView(
      value: vehicleValue,
      data: (vehicle) {
        if (vehicle == null) {
          return const Scaffold(body: Center(child: Text('Không tìm thấy xe')));
        }
        return Scaffold(
          appBar: AppBar(
            title: _VehicleTitle(
              name: vehicle.name,
              licensePlate: vehicle.licensePlate,
            ),
            actions: [
              IconButton(
                tooltip: 'Lịch sử',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ServiceLogsScreen(vehicleId: vehicle.id),
                  ),
                ),
                icon: const Icon(Icons.history),
              ),
              IconButton(
                tooltip: 'Sửa thông tin phương tiện',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleFormScreen(vehicle: vehicle),
                  ),
                ),
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehicleProvider(vehicle.id));
              ref.invalidate(maintenanceItemsProvider(vehicle.id));
              ref.invalidate(itemRemindersProvider(vehicle.id));
              ref.invalidate(serviceBatchesProvider(vehicle.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vehicle.imagePath.isNotEmpty) ...[
                  _VehiclePhoto(imagePath: vehicle.imagePath),
                  const SizedBox(height: 16),
                ],
                _VehicleSummary(vehicle: vehicle),
                const SizedBox(height: 16),
                _BatchSection(vehicle: vehicle),
                const SizedBox(height: 16),
                _MaintenanceSection(vehicle: vehicle),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VehiclePhoto extends StatelessWidget {
  const _VehiclePhoto({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    if (!file.existsSync()) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(file, fit: BoxFit.cover),
      ),
    );
  }
}

class _VehicleTitle extends StatelessWidget {
  const _VehicleTitle({required this.name, required this.licensePlate});

  final String name;
  final String licensePlate;

  @override
  Widget build(BuildContext context) {
    final style =
        (Theme.of(context).appBarTheme.titleTextStyle ??
                Theme.of(context).textTheme.titleLarge)
            ?.copyWith(fontSize: 18);
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
              fontSize: (style.fontSize ?? 18) * 0.82,
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

class _VehicleSummary extends ConsumerStatefulWidget {
  const _VehicleSummary({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_VehicleSummary> createState() => _VehicleSummaryState();
}

class _VehicleSummaryState extends ConsumerState<_VehicleSummary> {
  late final TextEditingController _kmController;
  late final FocusNode _kmFocusNode;
  bool _editingKm = false;
  bool _savingKm = false;

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(
      text: _formatKmValue(widget.vehicle.currentKm),
    );
    _kmFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _VehicleSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingKm &&
        oldWidget.vehicle.currentKm != widget.vehicle.currentKm) {
      _kmController.text = _formatKmValue(widget.vehicle.currentKm);
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    _kmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final reminders = ref.watch(itemRemindersProvider(vehicle.id));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (vehicle.licensePlate.isNotEmpty) ...[
            //   Text(
            //     vehicle.licensePlate,
            //     style: Theme.of(context).textTheme.titleMedium,
            //   ),
            //   const SizedBox(height: 8),
            // ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Km hiện tại',
                    value: _formatKmValue(vehicle.currentKm),
                    editing: _editingKm,
                    saving: _savingKm,
                    controller: _kmController,
                    focusNode: _kmFocusNode,
                    onTap: _startEditKm,
                    onSave: _saveCurrentKm,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: reminders.when(
                    data: (items) =>
                        _Metric(label: 'Đến hạn', value: _dueAfterText(items)),
                    loading: () =>
                        const _Metric(label: 'Đến hạn', value: 'Đang tính'),
                    error: (_, _) => const _Metric(
                      label: 'Đến hạn',
                      value: 'Chưa tính được',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    label: 'Km/ngày',
                    value: vehicle.dailyKm.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startEditKm() {
    setState(() => _editingKm = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_kmFocusNode.hasFocus) {
        _kmFocusNode.requestFocus();
      }
      _kmController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _kmController.text.length,
      );
    });
  }

  Future<void> _saveCurrentKm() async {
    if (_savingKm) return;
    final newKm = _tryParseDouble(_kmController.text);
    if (newKm == null || newKm < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập số km hợp lệ')));
      return;
    }
    if (newKm == widget.vehicle.currentKm) {
      setState(() => _editingKm = false);
      return;
    }

    setState(() => _savingKm = true);
    try {
      final vehicle = widget.vehicle;
      await ref
          .read(appActionsProvider)
          .updateVehicle(
            id: vehicle.id,
            name: vehicle.name,
            licensePlate: vehicle.licensePlate,
            imagePath: vehicle.imagePath,
            currentKm: newKm,
            dailyKm: vehicle.dailyKm,
            groupingWindowDays: vehicle.groupingWindowDays,
          );
      if (mounted) {
        setState(() {
          _editingKm = false;
          _savingKm = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _savingKm = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không lưu được số km: $error')));
      }
    }
  }

  String _dueAfterText(List<ItemReminder> reminders) {
    if (reminders.isEmpty) return 'Chưa có lịch';
    final date = reminders.first.estimatedDueDate;
    if (date == null) return 'Cần nhập km/ngày';

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = target.difference(start).inDays;

    if (days <= 0) return 'Hôm nay';
    if (days < 30) return '$days ngày nữa';
    if (days < 365) {
      final months = (days / 30).round().clamp(1, 12);
      return '$months tháng nữa';
    }
    final years = (days / 365).round().clamp(1, 999);
    return '$years năm nữa';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.onTap,
    this.editing = false,
    this.saving = false,
    this.controller,
    this.focusNode,
    this.onSave,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool editing;
  final bool saving;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: editing ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            if (editing)
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: Theme.of(context).textTheme.titleSmall,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onSave?.call(),
                onTapOutside: (_) => onSave?.call(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BatchSection extends ConsumerWidget {
  const _BatchSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(serviceBatchesProvider(vehicle.id));
    return AsyncValueView(
      value: batches,
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch cần làm', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có hạng mục đến hạn trong cửa sổ nhắc nhở.',
                  ),
                ),
              )
            else
              ...items.map(
                (batch) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BatchCard(vehicle: vehicle, batch: batch),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BatchCard extends ConsumerWidget {
  const _BatchCard({required this.vehicle, required this.batch});

  final Vehicle vehicle;
  final ServiceBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateText = batch.scheduledDate == null
        ? 'Cần nhập km/ngày'
        : relativeDateLabel(batch.scheduledDate!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(appActionsProvider)
                        .markCompleted(
                          vehicle: vehicle,
                          items: batch.reminders
                              .map((item) => item.item)
                              .toList(),
                          note: 'Làm theo batch',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã đánh dấu hoàn tất batch'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Đã hoàn thành'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...batch.reminders.map(
              (reminder) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(reminder.item.name),
                subtitle: Text(
                  '${reminderStatusLabel(reminder.status)} • ${_itemCycleText(reminder.item)} • ${_dueLimitText(reminder)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceSection extends ConsumerWidget {
  const _MaintenanceSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(itemRemindersProvider(vehicle.id));
    return AsyncValueView(
      value: reminders,
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hạng mục bảo trì',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Thêm hạng mục',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MaintenanceItemFormScreen(vehicle: vehicle),
                  ),
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có hạng mục nào.'),
              ),
            )
          else
            ...items.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MaintenanceTile(vehicle: vehicle, reminder: reminder),
              ),
            ),
        ],
      ),
    );
  }
}

class _MaintenanceTile extends ConsumerWidget {
  const _MaintenanceTile({required this.vehicle, required this.reminder});

  final Vehicle vehicle;
  final ItemReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = reminder.item;
    final date = reminder.estimatedDueDate;
    final dateText = date == null ? 'Chưa tính ngày' : relativeDateLabel(date);
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final dueStyle = titleStyle?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
    );
    final detailStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final lastServiceText =
        '${_formatKmValue(item.lastServiceKm)} km'
        '${item.lastServiceDate == null ? '' : ' (${relativeDateLabel(item.lastServiceDate!)})'}';
    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.48,
        dismissible: DismissiblePane(
          closeOnCancel: true,
          confirmDismiss: () async {
            await _markCompleted(context, ref, item);
            return false;
          },
          onDismissed: () {},
        ),
        children: [
          _CompleteSlidableAction(
            onPressed: (_) => _markCompleted(context, ref, item),
          ),
        ],
      ),
      child: Card(
        child: ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    MaintenanceItemFormScreen(vehicle: vehicle, item: item),
              ),
            );
          },
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: item.name),
                TextSpan(text: ' ($dateText)', style: dueStyle),
              ],
            ),
            style: titleStyle,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_itemCycleText(item), style: detailStyle),
              const SizedBox(height: 2),
              Text('Lần cuối $lastServiceText', style: detailStyle),
            ],
          ),

          leading: Icon(
            _statusIcon(reminder.status),
            color: _statusColor(context, reminder.status),
          ),
        ),
      ),
    );
  }

  Future<void> _markCompleted(
    BuildContext context,
    WidgetRef ref,
    MaintenanceItem item,
  ) async {
    await ref
        .read(appActionsProvider)
        .markCompleted(vehicle: vehicle, items: [item]);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã hoàn thành ${item.name}')));
    }
  }
}

class _CompleteSlidableAction extends StatelessWidget {
  const _CompleteSlidableAction({required this.onPressed});

  final SlidableActionCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: onPressed,
      autoClose: true,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Đã hoàn thành',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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

String _itemCycleText(MaintenanceItem item) {
  final parts = <String>[];
  if (item.hasKmInterval) {
    parts.add(_formatKmRange(item.intervalMinKm, item.intervalMaxKm));
  }
  if (item.hasTimeInterval) {
    parts.add(_formatDayRange(item.intervalMinDays, item.intervalMaxDays));
  }
  return parts.isEmpty ? 'Chưa có chu kỳ' : parts.join(' hoặc ');
}

String _dueLimitText(ItemReminder reminder) {
  final parts = <String>[];
  if (reminder.item.hasKmInterval) {
    parts.add('quá hạn ${_formatKmValue(reminder.overdueKm)} km');
  }
  if (reminder.overdueDate != null) {
    parts.add('quá hạn ${relativeDateLabel(reminder.overdueDate!)}');
  }
  return parts.join(' • ');
}

String _formatDays(int days) {
  if (days <= 0) return '0 ngày';
  if (days % 365 == 0) return '${days ~/ 365} năm';
  if (days % 30 == 0) return '${days ~/ 30} tháng';
  return '$days ngày';
}

String _formatKmRange(int minKm, int maxKm) {
  if (minKm == maxKm) return '$maxKm km';
  return '$minKm-$maxKm km';
}

String _formatDayRange(int minDays, int maxDays) {
  if (minDays == maxDays) return _formatDays(maxDays);
  return '${_formatDays(minDays)}-${_formatDays(maxDays)}';
}

double? _tryParseDouble(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.'));
}

String _formatKmValue(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}
