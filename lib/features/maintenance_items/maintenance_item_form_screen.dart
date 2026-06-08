import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_models.dart';
import '../../core/providers/app_providers.dart';

class MaintenanceItemFormScreen extends ConsumerStatefulWidget {
  const MaintenanceItemFormScreen({
    super.key,
    required this.vehicle,
    this.item,
  });

  final Vehicle vehicle;
  final MaintenanceItem? item;

  @override
  ConsumerState<MaintenanceItemFormScreen> createState() =>
      _MaintenanceItemFormScreenState();
}

class _MaintenanceItemFormScreenState
    extends ConsumerState<MaintenanceItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _minKm;
  late final TextEditingController _maxKm;
  late final TextEditingController _minTime;
  late final TextEditingController _maxTime;
  late final TextEditingController _lastKm;
  late _TimeUnit _timeUnit;
  late DateTime _lastServiceDate;
  late bool _useKmCycle;
  late bool _useTimeCycle;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _minKm = TextEditingController(
      text: item == null || item.intervalMinKm > 0
          ? '${item?.intervalMinKm ?? 1500}'
          : '',
    );
    _maxKm = TextEditingController(
      text: item == null || item.intervalMaxKm > 0
          ? '${item?.intervalMaxKm ?? 2000}'
          : '',
    );
    _timeUnit = _TimeUnit.fromDays(item?.intervalMaxDays ?? 0);
    _minTime = TextEditingController(
      text: item != null && item.intervalMinDays > 0
          ? '${(item.intervalMinDays / _timeUnit.days).round()}'
          : '',
    );
    _maxTime = TextEditingController(
      text: item != null && item.intervalMaxDays > 0
          ? '${(item.intervalMaxDays / _timeUnit.days).round()}'
          : '',
    );
    _lastKm = TextEditingController(
      text: '${item?.lastServiceKm ?? widget.vehicle.currentKm}',
    );
    _lastServiceDate = item?.lastServiceDate ?? DateTime.now();
    _useKmCycle = item?.hasKmInterval ?? true;
    _useTimeCycle = item?.hasTimeInterval ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _minKm.dispose();
    _maxKm.dispose();
    _minTime.dispose();
    _maxTime.dispose();
    _lastKm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Sửa hạng mục' : 'Thêm hạng mục')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên hạng mục'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chu kỳ theo km'),
              value: _useKmCycle,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) =>
                  setState(() => _useKmCycle = value ?? _useKmCycle),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minKm,
                    enabled: _useKmCycle,
                    decoration: const InputDecoration(labelText: 'Min km'),
                    keyboardType: TextInputType.number,
                    validator: _optionalPositiveInt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxKm,
                    enabled: _useKmCycle,
                    decoration: const InputDecoration(labelText: 'Max km'),
                    keyboardType: TextInputType.number,
                    validator: _optionalPositiveInt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chu kỳ theo thời gian'),
              value: _useTimeCycle,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) =>
                  setState(() => _useTimeCycle = value ?? _useTimeCycle),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minTime,
                    enabled: _useTimeCycle,
                    decoration: const InputDecoration(labelText: 'Min'),
                    keyboardType: TextInputType.number,
                    validator: _optionalPositiveInt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxTime,
                    enabled: _useTimeCycle,
                    decoration: const InputDecoration(labelText: 'Max'),
                    keyboardType: TextInputType.number,
                    validator: _optionalPositiveInt,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 112,
                  child: DropdownButtonFormField<_TimeUnit>(
                    initialValue: _timeUnit,
                    decoration: const InputDecoration(labelText: 'Đơn vị'),
                    items: _TimeUnit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.label),
                          ),
                        )
                        .toList(),
                    onChanged: _useTimeCycle
                        ? (value) =>
                              setState(() => _timeUnit = value ?? _timeUnit)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastKm,
              decoration: const InputDecoration(
                labelText: 'Km lần cuối đã thay/kiểm tra',
              ),
              keyboardType: TextInputType.number,
              validator: _positiveInt,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày thay/kiểm tra gần nhất'),
              subtitle: Text(_formatDate(_lastServiceDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickLastServiceDate,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving || _deleting ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(editing ? 'Lưu hạng mục' : 'Thêm hạng mục'),
            ),
            if (editing) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: _saving || _deleting ? null : _confirmDelete,
                icon: _deleting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: const Text('Xóa hạng mục'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final minKm = _useKmCycle ? _parseOptionalInt(_minKm.text) : 0;
    final maxKm = _useKmCycle ? _parseOptionalInt(_maxKm.text) : 0;
    final minTime = _useTimeCycle ? _parseOptionalInt(_minTime.text) : 0;
    final maxTime = _useTimeCycle ? _parseOptionalInt(_maxTime.text) : 0;
    final hasKm = _useKmCycle;
    final hasTime = _useTimeCycle;

    if (!hasKm && !hasTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập ít nhất một chu kỳ km hoặc thời gian'),
        ),
      );
      return;
    }
    if (hasKm && (minKm <= 0 || maxKm <= 0 || maxKm < minKm)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max km phải lớn hơn hoặc bằng min km')),
      );
      return;
    }
    if (hasTime && (minTime <= 0 || maxTime <= 0 || maxTime < minTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Max thời gian phải lớn hơn hoặc bằng min'),
        ),
      );
      return;
    }

    final minDays = hasTime ? minTime * _timeUnit.days : 0;
    final maxDays = hasTime ? maxTime * _timeUnit.days : 0;

    setState(() => _saving = true);
    final actions = ref.read(appActionsProvider);
    final item = widget.item;
    try {
      if (item == null) {
        await actions.createItem(
          vehicleId: widget.vehicle.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          intervalMinKm: minKm,
          intervalMaxKm: maxKm,
          intervalMinDays: minDays,
          intervalMaxDays: maxDays,
          lastServiceKm: int.parse(_lastKm.text),
          lastServiceDate: _lastServiceDate,
        );
      } else {
        await actions.updateItem(
          MaintenanceItem(
            id: item.id,
            vehicleId: item.vehicleId,
            name: _name.text.trim(),
            description: _description.text.trim(),
            intervalMinKm: minKm,
            intervalMaxKm: maxKm,
            intervalMinDays: minDays,
            intervalMaxDays: maxDays,
            lastServiceKm: int.parse(_lastKm.text),
            lastServiceDate: _lastServiceDate,
            isEnabled: item.isEnabled,
            createdAt: item.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLastServiceDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _lastServiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() => _lastServiceDate = selected);
  }

  Future<void> _confirmDelete() async {
    final item = widget.item;
    if (item == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hạng mục?'),
        content: Text('Hạng mục "${item.name}" sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(appActionsProvider).deleteItem(item);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Bắt buộc nhập';
  return null;
}

String? _positiveInt(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed < 0) return 'Nhập số hợp lệ';
  return null;
}

String? _optionalPositiveInt(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 0) return 'Nhập số hợp lệ';
  return null;
}

int _parseOptionalInt(String value) {
  return int.tryParse(value.trim()) ?? 0;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

enum _TimeUnit {
  day('ngày', 1),
  month('tháng', 30),
  year('năm', 365);

  const _TimeUnit(this.label, this.days);

  final String label;
  final int days;

  static _TimeUnit fromDays(int days) {
    if (days > 0 && days % year.days == 0) return year;
    if (days > 0 && days % month.days == 0) return month;
    return _TimeUnit.day;
  }
}
