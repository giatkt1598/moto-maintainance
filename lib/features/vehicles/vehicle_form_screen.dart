import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/database/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/local_image_store.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _licensePlate;
  late final TextEditingController _currentKm;
  late final TextEditingController _dailyKm;
  late final TextEditingController _groupDays;
  late VehicleProfile _profile;
  String _imagePath = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _name = TextEditingController(text: vehicle?.name ?? '');
    _licensePlate = TextEditingController(text: vehicle?.licensePlate ?? '');
    _currentKm = TextEditingController(text: '${vehicle?.currentKm ?? 0}');
    _dailyKm = TextEditingController(text: '${vehicle?.dailyKm ?? 30}');
    _groupDays = TextEditingController(
      text: '${vehicle?.groupingWindowDays ?? 7}',
    );
    _profile = vehicle?.profile ?? VehicleProfile.scooter;
    _imagePath = vehicle?.imagePath ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _licensePlate.dispose();
    _currentKm.dispose();
    _dailyKm.dispose();
    _groupDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.vehicle != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Sửa xe' : 'Thêm xe'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Xóa xe',
              onPressed: _saving ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ImagePickerField(
              imagePath: _imagePath,
              onPick: _pickImage,
              onRemove: () => setState(() => _imagePath = ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên xe'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licensePlate,
              decoration: const InputDecoration(labelText: 'Biển số xe'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<VehicleProfile>(
              initialValue: _profile,
              decoration: const InputDecoration(labelText: 'Profile'),
              items: VehicleProfile.values
                  .map(
                    (profile) => DropdownMenuItem(
                      value: profile,
                      child: Text(profile.label),
                    ),
                  )
                  .toList(),
              onChanged: editing
                  ? null
                  : (value) => setState(() => _profile = value ?? _profile),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentKm,
              decoration: const InputDecoration(labelText: 'Số km hiện tại'),
              keyboardType: TextInputType.number,
              validator: _positiveInt,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dailyKm,
              decoration: const InputDecoration(
                labelText: 'Số km đi hằng ngày',
              ),
              keyboardType: TextInputType.number,
              validator: _nonNegativeDouble,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _groupDays,
              decoration: const InputDecoration(
                labelText: 'Gom lịch trong bao nhiêu ngày',
              ),
              keyboardType: TextInputType.number,
              validator: _positiveInt,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(editing ? 'Lưu xe' : 'Tạo xe'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final actions = ref.read(appActionsProvider);
    final vehicle = widget.vehicle;
    try {
      if (vehicle == null) {
        await actions.createVehicle(
          name: _name.text.trim(),
          licensePlate: _licensePlate.text.trim(),
          imagePath: _imagePath,
          profile: _profile,
          currentKm: int.parse(_currentKm.text),
          dailyKm: double.parse(_dailyKm.text),
          groupingWindowDays: int.parse(_groupDays.text),
        );
      } else {
        await actions.updateVehicle(
          id: vehicle.id,
          name: _name.text.trim(),
          licensePlate: _licensePlate.text.trim(),
          imagePath: _imagePath,
          currentKm: int.parse(_currentKm.text),
          dailyKm: double.parse(_dailyKm.text),
          groupingWindowDays: int.parse(_groupDays.text),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final savedPath = await saveVehicleImage(picked.path);
    if (mounted) {
      setState(() => _imagePath = savedPath);
    }
  }

  Future<void> _confirmDelete() async {
    final vehicle = widget.vehicle;
    if (vehicle == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa xe máy?'),
        content: Text(
          'Xe "${vehicle.name}" và toàn bộ hạng mục, lịch sử bảo trì sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(appActionsProvider).deleteVehicle(vehicle.id);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  final String imagePath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: hasImage
                  ? Image.file(File(imagePath), fit: BoxFit.cover)
                  : Center(
                      child: Icon(
                        Icons.two_wheeler,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_camera_back_outlined),
              label: Text(hasImage ? 'Đổi ảnh xe' : 'Chọn ảnh xe'),
            ),
            const SizedBox(width: 8),
            if (hasImage)
              IconButton(
                tooltip: 'Gỡ ảnh',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ],
    );
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

String? _nonNegativeDouble(String? value) {
  final parsed = double.tryParse(value ?? '');
  if (parsed == null || parsed < 0) return 'Nhập số hợp lệ';
  return null;
}
