import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'app_models.dart';

part 'profile_seed.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(_openConnection());

  final _uuid = const Uuid();

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  Future<void> initialize() async {
    await customStatement('PRAGMA foreign_keys = ON');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS vehicles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        license_plate TEXT NOT NULL DEFAULT '',
        image_path TEXT NOT NULL DEFAULT '',
        profile TEXT NOT NULL,
        current_km REAL NOT NULL,
        daily_km REAL NOT NULL,
        grouping_window_days INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await _addColumnIfMissing(
      'vehicles',
      'license_plate',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      'vehicles',
      'image_path',
      "TEXT NOT NULL DEFAULT ''",
    );
    await customStatement('''
      CREATE TABLE IF NOT EXISTS maintenance_items (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        interval_min_km INTEGER NOT NULL,
        interval_max_km INTEGER NOT NULL,
        interval_min_days INTEGER NOT NULL DEFAULT 0,
        interval_max_days INTEGER NOT NULL DEFAULT 0,
        last_service_km REAL NOT NULL,
        last_service_date INTEGER,
        is_enabled INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await _addColumnIfMissing(
      'maintenance_items',
      'interval_min_days',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      'maintenance_items',
      'interval_max_days',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement('''
      CREATE TABLE IF NOT EXISTS service_logs (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        service_km REAL NOT NULL,
        service_date INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS mileage_logs (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        previous_km REAL NOT NULL,
        current_km REAL NOT NULL,
        delta_km REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS scheduled_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        notification_id INTEGER NOT NULL,
        scheduled_at INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Stream<List<Vehicle>> watchVehicles() {
    return customSelect(
      'SELECT * FROM vehicles WHERE is_active = 1 ORDER BY updated_at DESC',
      readsFrom: const {},
    ).watch().map((rows) => rows.map(_vehicleFromRow).toList());
  }

  Future<List<Vehicle>> getVehicles() async {
    final rows = await customSelect(
      'SELECT * FROM vehicles WHERE is_active = 1 ORDER BY updated_at DESC',
    ).get();
    return rows.map(_vehicleFromRow).toList();
  }

  Future<Vehicle?> getVehicle(String id) async {
    final rows = await customSelect(
      'SELECT * FROM vehicles WHERE id = ? LIMIT 1',
      variables: [Variable.withString(id)],
    ).get();
    return rows.isEmpty ? null : _vehicleFromRow(rows.first);
  }

  Stream<Vehicle?> watchVehicle(String id) {
    return customSelect(
      'SELECT * FROM vehicles WHERE id = ? LIMIT 1',
      variables: [Variable.withString(id)],
      readsFrom: const {},
    ).watchSingleOrNull().map(
      (row) => row == null ? null : _vehicleFromRow(row),
    );
  }

  Stream<List<MaintenanceItem>> watchItems(String vehicleId) {
    return customSelect(
      'SELECT * FROM maintenance_items WHERE vehicle_id = ? ORDER BY is_enabled DESC, name ASC',
      variables: [Variable.withString(vehicleId)],
      readsFrom: const {},
    ).watch().map((rows) => rows.map(_itemFromRow).toList());
  }

  Future<List<MaintenanceItem>> getItems(String vehicleId) async {
    final rows = await customSelect(
      'SELECT * FROM maintenance_items WHERE vehicle_id = ? ORDER BY is_enabled DESC, name ASC',
      variables: [Variable.withString(vehicleId)],
    ).get();
    return rows.map(_itemFromRow).toList();
  }

  Future<MaintenanceItem?> getItem(String itemId) async {
    final rows = await customSelect(
      'SELECT * FROM maintenance_items WHERE id = ? LIMIT 1',
      variables: [Variable.withString(itemId)],
    ).get();
    return rows.isEmpty ? null : _itemFromRow(rows.first);
  }

  Stream<List<ServiceLog>> watchLogs(String vehicleId) {
    return customSelect(
      'SELECT * FROM service_logs WHERE vehicle_id = ? ORDER BY service_date DESC, created_at DESC',
      variables: [Variable.withString(vehicleId)],
      readsFrom: const {},
    ).watch().map((rows) => rows.map(_logFromRow).toList());
  }

  Stream<List<MileageLog>> watchMileageLogs(String vehicleId) {
    return customSelect(
      'SELECT * FROM mileage_logs WHERE vehicle_id = ? ORDER BY created_at DESC',
      variables: [Variable.withString(vehicleId)],
      readsFrom: const {},
    ).watch().map((rows) => rows.map(_mileageLogFromRow).toList());
  }

  Future<String> createVehicle({
    required String name,
    required String licensePlate,
    required String imagePath,
    required VehicleProfile profile,
    required double currentKm,
    required double dailyKm,
    required int groupingWindowDays,
  }) async {
    final now = DateTime.now();
    final vehicleId = _uuid.v4();
    await transaction(() async {
      await customInsert(
        '''
        INSERT INTO vehicles (
          id, name, license_plate, image_path, profile, current_km, daily_km, grouping_window_days, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
        ''',
        variables: [
          Variable.withString(vehicleId),
          Variable.withString(name),
          Variable.withString(licensePlate),
          Variable.withString(imagePath),
          Variable.withString(profile.name),
          Variable.withReal(currentKm),
          Variable.withReal(dailyKm),
          Variable.withInt(groupingWindowDays),
          Variable.withInt(_millis(now)),
          Variable.withInt(_millis(now)),
        ],
      );
      for (final seed in profile.seedItems) {
        await _insertItem(
          vehicleId: vehicleId,
          name: seed.name,
          description: seed.description,
          intervalMinKm: seed.intervalMinKm,
          intervalMaxKm: seed.intervalMaxKm,
          intervalMinDays: seed.intervalMinDays,
          intervalMaxDays: seed.intervalMaxDays,
          lastServiceKm: currentKm,
          lastServiceDate: now,
        );
      }
    });
    return vehicleId;
  }

  Future<void> updateVehicle({
    required String id,
    required String name,
    required String licensePlate,
    required String imagePath,
    required double currentKm,
    required double dailyKm,
    required int groupingWindowDays,
  }) async {
    final current = await getVehicle(id);
    final now = DateTime.now();
    await transaction(() async {
      if (current != null && current.currentKm != currentKm) {
        final deltaKm = currentKm - current.currentKm;
        await customInsert(
          '''
          INSERT INTO mileage_logs (
            id, vehicle_id, previous_km, current_km, delta_km, created_at
          ) VALUES (?, ?, ?, ?, ?, ?)
          ''',
          variables: [
            Variable.withString(_uuid.v4()),
            Variable.withString(id),
            Variable.withReal(current.currentKm),
            Variable.withReal(currentKm),
            Variable.withReal(deltaKm),
            Variable.withInt(_millis(now)),
          ],
        );
      }
      await customUpdate(
        '''
        UPDATE vehicles
        SET name = ?, license_plate = ?, image_path = ?, current_km = ?, daily_km = ?, grouping_window_days = ?, updated_at = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withString(name),
          Variable.withString(licensePlate),
          Variable.withString(imagePath),
          Variable.withReal(currentKm),
          Variable.withReal(dailyKm),
          Variable.withInt(groupingWindowDays),
          Variable.withInt(_millis(now)),
          Variable.withString(id),
        ],
      );
    });
  }

  Future<void> deleteVehicle(String id) async {
    await customUpdate(
      'DELETE FROM vehicles WHERE id = ?',
      variables: [Variable.withString(id)],
    );
  }

  Future<String> createItem({
    required String vehicleId,
    required String name,
    required String description,
    required int intervalMinKm,
    required int intervalMaxKm,
    required int intervalMinDays,
    required int intervalMaxDays,
    required double lastServiceKm,
    DateTime? lastServiceDate,
  }) {
    return _insertItem(
      vehicleId: vehicleId,
      name: name,
      description: description,
      intervalMinKm: intervalMinKm,
      intervalMaxKm: intervalMaxKm,
      intervalMinDays: intervalMinDays,
      intervalMaxDays: intervalMaxDays,
      lastServiceKm: lastServiceKm,
      lastServiceDate: lastServiceDate,
    );
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required String description,
    required int intervalMinKm,
    required int intervalMaxKm,
    required int intervalMinDays,
    required int intervalMaxDays,
    required double lastServiceKm,
    DateTime? lastServiceDate,
    required bool isEnabled,
  }) async {
    await customUpdate(
      '''
      UPDATE maintenance_items
      SET name = ?, description = ?, interval_min_km = ?, interval_max_km = ?,
          interval_min_days = ?, interval_max_days = ?,
          last_service_km = ?, last_service_date = ?, is_enabled = ?, updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(name),
        Variable.withString(description),
        Variable.withInt(intervalMinKm),
        Variable.withInt(intervalMaxKm),
        Variable.withInt(intervalMinDays),
        Variable.withInt(intervalMaxDays),
        Variable.withReal(lastServiceKm),
        _nullableMillis(lastServiceDate),
        Variable.withInt(isEnabled ? 1 : 0),
        Variable.withInt(_millis(DateTime.now())),
        Variable.withString(id),
      ],
    );
  }

  Future<void> deleteItem(String id) async {
    await customUpdate(
      'DELETE FROM maintenance_items WHERE id = ?',
      variables: [Variable.withString(id)],
    );
  }

  Future<void> markItemsCompleted({
    required Vehicle vehicle,
    required List<MaintenanceItem> items,
    required String note,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      for (final item in items) {
        await customInsert(
          '''
          INSERT INTO service_logs (
            id, vehicle_id, item_id, item_name, service_km, service_date, note, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          variables: [
            Variable.withString(_uuid.v4()),
            Variable.withString(vehicle.id),
            Variable.withString(item.id),
            Variable.withString(item.name),
            Variable.withReal(vehicle.currentKm),
            Variable.withInt(_millis(now)),
            Variable.withString(note),
            Variable.withInt(_millis(now)),
          ],
        );
        await customUpdate(
          '''
          UPDATE maintenance_items
          SET last_service_km = ?, last_service_date = ?, updated_at = ?
          WHERE id = ?
          ''',
          variables: [
            Variable.withReal(vehicle.currentKm),
            Variable.withInt(_millis(now)),
            Variable.withInt(_millis(now)),
            Variable.withString(item.id),
          ],
        );
      }
    });
  }

  Future<void> replaceScheduledReminders({
    required String vehicleId,
    required List<ScheduledReminderRecord> records,
  }) async {
    await transaction(() async {
      await customUpdate(
        'DELETE FROM scheduled_reminders WHERE vehicle_id = ?',
        variables: [Variable.withString(vehicleId)],
      );
      for (final record in records) {
        await customInsert(
          '''
          INSERT INTO scheduled_reminders (vehicle_id, notification_id, scheduled_at, title, body)
          VALUES (?, ?, ?, ?, ?)
          ''',
          variables: [
            Variable.withString(vehicleId),
            Variable.withInt(record.notificationId),
            Variable.withInt(_millis(record.scheduledAt)),
            Variable.withString(record.title),
            Variable.withString(record.body),
          ],
        );
      }
    });
  }

  Future<List<int>> getNotificationIds(String vehicleId) async {
    final rows = await customSelect(
      'SELECT notification_id FROM scheduled_reminders WHERE vehicle_id = ?',
      variables: [Variable.withString(vehicleId)],
    ).get();
    return rows.map((row) => row.read<int>('notification_id')).toList();
  }

  Future<List<String>> applyDailyMileageIfNeeded({DateTime? now}) async {
    final today = _dateKey(now ?? DateTime.now());
    final lastRun = await _getMeta('last_daily_mileage_date');
    if (lastRun == null) {
      await _setMeta('last_daily_mileage_date', today);
      return const [];
    }
    if (lastRun == today) return const [];

    final lastDate = _parseDateKey(lastRun);
    final todayDate = _parseDateKey(today);
    final days = todayDate.difference(lastDate).inDays;
    if (days <= 0) {
      await _setMeta('last_daily_mileage_date', today);
      return const [];
    }

    final candidates = await customSelect(
      'SELECT id FROM vehicles WHERE is_active = 1 AND daily_km > 0',
    ).get();
    final vehicleIds = candidates.map((row) => row.read<String>('id')).toList();
    if (vehicleIds.isEmpty) {
      await _setMeta('last_daily_mileage_date', today);
      return const [];
    }

    await transaction(() async {
      await customUpdate(
        '''
        UPDATE vehicles
        SET current_km = current_km + (daily_km * ?),
            updated_at = ?
        WHERE is_active = 1 AND daily_km > 0
        ''',
        variables: [
          Variable.withInt(days),
          Variable.withInt(_millis(DateTime.now())),
        ],
      );
      await _setMeta('last_daily_mileage_date', today);
    });

    return vehicleIds;
  }

  Future<String> _insertItem({
    required String vehicleId,
    required String name,
    required String description,
    required int intervalMinKm,
    required int intervalMaxKm,
    required int intervalMinDays,
    required int intervalMaxDays,
    required double lastServiceKm,
    DateTime? lastServiceDate,
  }) async {
    final now = DateTime.now();
    final itemId = _uuid.v4();
    await customInsert(
      '''
      INSERT INTO maintenance_items (
        id, vehicle_id, name, description, interval_min_km, interval_max_km,
        interval_min_days, interval_max_days, last_service_km, last_service_date,
        is_enabled, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      ''',
      variables: [
        Variable.withString(itemId),
        Variable.withString(vehicleId),
        Variable.withString(name),
        Variable.withString(description),
        Variable.withInt(intervalMinKm),
        Variable.withInt(intervalMaxKm),
        Variable.withInt(intervalMinDays),
        Variable.withInt(intervalMaxDays),
        Variable.withReal(lastServiceKm),
        _nullableMillis(lastServiceDate),
        Variable.withInt(_millis(now)),
        Variable.withInt(_millis(now)),
      ],
    );
    return itemId;
  }

  Vehicle _vehicleFromRow(QueryRow row) {
    return Vehicle(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      licensePlate: row.read<String>('license_plate'),
      imagePath: row.read<String>('image_path'),
      profile: VehicleProfile.values.byName(row.read<String>('profile')),
      currentKm: _readDouble(row, 'current_km'),
      dailyKm: row.read<double>('daily_km'),
      groupingWindowDays: row.read<int>('grouping_window_days'),
      isActive: row.read<int>('is_active') == 1,
      createdAt: _fromMillis(row.read<int>('created_at')),
      updatedAt: _fromMillis(row.read<int>('updated_at')),
    );
  }

  MaintenanceItem _itemFromRow(QueryRow row) {
    return MaintenanceItem(
      id: row.read<String>('id'),
      vehicleId: row.read<String>('vehicle_id'),
      name: row.read<String>('name'),
      description: row.read<String>('description'),
      intervalMinKm: row.read<int>('interval_min_km'),
      intervalMaxKm: row.read<int>('interval_max_km'),
      intervalMinDays: row.read<int>('interval_min_days'),
      intervalMaxDays: row.read<int>('interval_max_days'),
      lastServiceKm: _readDouble(row, 'last_service_km'),
      lastServiceDate: _fromNullableMillis(
        row.readNullable<int>('last_service_date'),
      ),
      isEnabled: row.read<int>('is_enabled') == 1,
      createdAt: _fromMillis(row.read<int>('created_at')),
      updatedAt: _fromMillis(row.read<int>('updated_at')),
    );
  }

  ServiceLog _logFromRow(QueryRow row) {
    return ServiceLog(
      id: row.read<String>('id'),
      vehicleId: row.read<String>('vehicle_id'),
      itemId: row.read<String>('item_id'),
      itemName: row.read<String>('item_name'),
      serviceKm: _readDouble(row, 'service_km'),
      serviceDate: _fromMillis(row.read<int>('service_date')),
      note: row.read<String>('note'),
      createdAt: _fromMillis(row.read<int>('created_at')),
    );
  }

  MileageLog _mileageLogFromRow(QueryRow row) {
    return MileageLog(
      id: row.read<String>('id'),
      vehicleId: row.read<String>('vehicle_id'),
      previousKm: _readDouble(row, 'previous_km'),
      currentKm: _readDouble(row, 'current_km'),
      deltaKm: _readDouble(row, 'delta_km'),
      createdAt: _fromMillis(row.read<int>('created_at')),
    );
  }

  Future<void> _addColumnIfMissing(
    String table,
    String column,
    String definition,
  ) async {
    final columns = await customSelect('PRAGMA table_info($table)').get();
    final exists = columns.any((row) => row.read<String>('name') == column);
    if (!exists) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }

  Future<String?> _getMeta(String key) async {
    final rows = await customSelect(
      'SELECT value FROM app_meta WHERE key = ? LIMIT 1',
      variables: [Variable.withString(key)],
    ).get();
    return rows.isEmpty ? null : rows.first.read<String>('value');
  }

  Future<void> _setMeta(String key, String value) async {
    await customInsert(
      '''
      INSERT INTO app_meta (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      variables: [Variable.withString(key), Variable.withString(value)],
    );
  }
}

class ScheduledReminderRecord {
  const ScheduledReminderRecord({
    required this.notificationId,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  final int notificationId;
  final DateTime scheduledAt;
  final String title;
  final String body;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'moto_maintainance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

int _millis(DateTime date) => date.millisecondsSinceEpoch;

Variable<int> _nullableMillis(DateTime? date) =>
    Variable.withInt(date?.millisecondsSinceEpoch ?? 0);

DateTime _fromMillis(int millis) => DateTime.fromMillisecondsSinceEpoch(millis);

DateTime? _fromNullableMillis(int? millis) {
  if (millis == null || millis == 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

double _readDouble(QueryRow row, String key) {
  final value = row.data[key];
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String _dateKey(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime _parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return DateTime.now();
  final year = int.tryParse(parts[0]) ?? DateTime.now().year;
  final month = int.tryParse(parts[1]) ?? DateTime.now().month;
  final day = int.tryParse(parts[2]) ?? DateTime.now().day;
  return DateTime(year, month, day);
}
