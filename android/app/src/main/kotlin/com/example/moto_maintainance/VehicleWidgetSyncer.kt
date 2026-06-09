package com.example.moto_maintainance

import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.util.Calendar
import java.util.Locale
import kotlin.math.ceil
import kotlin.math.roundToInt

object VehicleWidgetSyncer {
    fun sync(context: Context) {
        val prefs = context.getSharedPreferences(
            VehicleWidgetProvider.PREFS_NAME,
            Context.MODE_PRIVATE,
        )
        val selectedVehicleId = prefs.getString(
            VehicleWidgetProvider.KEY_SELECTED_VEHICLE_ID,
            null,
        )
        if (selectedVehicleId.isNullOrEmpty()) {
            clearWidgetData(context)
            return
        }

        val databaseFile = File(context.applicationInfo.dataDir, "app_flutter/moto_maintainance.sqlite")
        if (!databaseFile.exists()) return

        val payload = SQLiteDatabase.openDatabase(
            databaseFile.path,
            null,
            SQLiteDatabase.OPEN_READONLY,
        ).use { db ->
            val vehicle = db.queryVehicle(selectedVehicleId)
            if (vehicle == null) {
                prefs.edit()
                    .remove(VehicleWidgetProvider.KEY_SELECTED_VEHICLE_ID)
                    .apply()
                null
            } else {
                val reminders = db.queryItems(vehicle.id)
                    .filter { it.isEnabled }
                    .map { calculateReminder(vehicle, it) }
                    .sortedWith(compareBy<WidgetReminder> { it.estimatedDueAt ?: Long.MAX_VALUE }
                        .thenBy { it.nextDueKm })
                buildPayload(vehicle, reminders.firstOrNull())
            }
        }

        if (payload == null) {
            clearWidgetData(context)
            return
        }

        prefs.edit()
            .putBoolean(VehicleWidgetProvider.KEY_HAS_DATA, true)
            .putString(VehicleWidgetProvider.KEY_VEHICLE_ID, payload.vehicleId)
            .putString(VehicleWidgetProvider.KEY_TITLE, payload.title)
            .putString(VehicleWidgetProvider.KEY_SUBTITLE, payload.subtitle)
            .putString(VehicleWidgetProvider.KEY_REMINDER, payload.reminderText)
            .putString(VehicleWidgetProvider.KEY_REMINDER_KIND, payload.reminderKind)
            .putString(VehicleWidgetProvider.KEY_ITEM_NAME, payload.itemName)
            .putLong(VehicleWidgetProvider.KEY_DUE_AT_MILLIS, payload.dueAtMillis ?: 0L)
            .putString(VehicleWidgetProvider.KEY_STATUS, payload.status)
            .putString(VehicleWidgetProvider.KEY_IMAGE_PATH, payload.imagePath)
            .apply()
        VehicleWidgetProvider.updateAll(context)
    }

    private fun clearWidgetData(context: Context) {
        context.getSharedPreferences(
            VehicleWidgetProvider.PREFS_NAME,
            Context.MODE_PRIVATE,
        ).edit()
            .putBoolean(VehicleWidgetProvider.KEY_HAS_DATA, false)
            .remove(VehicleWidgetProvider.KEY_VEHICLE_ID)
            .remove(VehicleWidgetProvider.KEY_TITLE)
            .remove(VehicleWidgetProvider.KEY_SUBTITLE)
            .remove(VehicleWidgetProvider.KEY_REMINDER)
            .remove(VehicleWidgetProvider.KEY_REMINDER_KIND)
            .remove(VehicleWidgetProvider.KEY_ITEM_NAME)
            .remove(VehicleWidgetProvider.KEY_DUE_AT_MILLIS)
            .remove(VehicleWidgetProvider.KEY_STATUS)
            .remove(VehicleWidgetProvider.KEY_IMAGE_PATH)
            .apply()
        VehicleWidgetProvider.updateAll(context)
    }

    private fun SQLiteDatabase.queryVehicle(vehicleId: String): WidgetVehicle? {
        return rawQuery(
            """
            SELECT id, name, license_plate, image_path, current_km, daily_km, grouping_window_days
            FROM vehicles
            WHERE id = ? AND is_active = 1
            LIMIT 1
            """.trimIndent(),
            arrayOf(vehicleId),
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            WidgetVehicle(
                id = cursor.string("id"),
                name = cursor.string("name"),
                licensePlate = cursor.string("license_plate"),
                imagePath = cursor.string("image_path"),
                currentKm = cursor.double("current_km"),
                dailyKm = cursor.double("daily_km"),
                groupingWindowDays = cursor.int("grouping_window_days"),
            )
        }
    }

    private fun SQLiteDatabase.queryItems(vehicleId: String): List<WidgetItem> {
        return rawQuery(
            """
            SELECT name, interval_min_km, interval_max_km, interval_min_days, interval_max_days,
                   last_service_km, last_service_date, is_enabled
            FROM maintenance_items
            WHERE vehicle_id = ?
            ORDER BY is_enabled DESC, name ASC
            """.trimIndent(),
            arrayOf(vehicleId),
        ).use { cursor ->
            buildList {
                while (cursor.moveToNext()) {
                    add(
                        WidgetItem(
                            name = cursor.string("name"),
                            intervalMinKm = cursor.int("interval_min_km"),
                            intervalMaxKm = cursor.int("interval_max_km"),
                            intervalMinDays = cursor.int("interval_min_days"),
                            intervalMaxDays = cursor.int("interval_max_days"),
                            lastServiceKm = cursor.double("last_service_km"),
                            lastServiceDate = cursor.nullableLong("last_service_date"),
                            isEnabled = cursor.int("is_enabled") == 1,
                        ),
                    )
                }
            }
        }
    }

    private fun calculateReminder(vehicle: WidgetVehicle, item: WidgetItem): WidgetReminder {
        val today = dateOnly(System.currentTimeMillis())
        val hasKm = item.intervalMaxKm > 0
        val hasTime = item.intervalMaxDays > 0
        val midpointKm = ((item.intervalMinKm + item.intervalMaxKm) / 2.0).roundToInt()
        val midpointDays = ((item.intervalMinDays + item.intervalMaxDays) / 2.0).roundToInt()
        val nextDueKm = if (hasKm) item.lastServiceKm + midpointKm else item.lastServiceKm
        val overdueLimitKm = if (hasKm) item.lastServiceKm + item.intervalMaxKm else item.lastServiceKm
        val overdueKm = if (hasKm) vehicle.currentKm - overdueLimitKm else 0.0
        val remainingKm = if (hasKm) nextDueKm - vehicle.currentKm else 0.0
        val kmOverdue = hasKm && overdueKm > 0
        val kmDue = hasKm && remainingKm <= 0
        val kmDueAt = if (hasKm && vehicle.dailyKm > 0) {
            addDays(today, if (remainingKm <= 0) 0 else ceil(remainingKm / vehicle.dailyKm).toInt())
        } else {
            null
        }

        val baseDate = item.lastServiceDate?.takeIf { it > 0 }?.let { dateOnly(it) }
        val timeDueAt = if (hasTime && baseDate != null) addDays(baseDate, midpointDays) else null
        val overdueAt = if (hasTime && baseDate != null) addDays(baseDate, item.intervalMaxDays) else null
        val estimatedDueAt = earliest(kmDueAt, timeDueAt)
        val timeDue = timeDueAt != null && today >= timeDueAt
        val timeOverdueDays = if (overdueAt == null) 0 else daysBetween(overdueAt, today)

        val status = if (hasKm && !hasTime && vehicle.dailyKm <= 0) {
            "missingDailyKm"
        } else if (kmOverdue || timeOverdueDays > 0) {
            "overdue"
        } else if (kmDue || timeDue) {
            "due"
        } else if (estimatedDueAt != null &&
            daysBetween(today, estimatedDueAt) <= vehicle.groupingWindowDays
        ) {
            "dueSoon"
        } else {
            "ok"
        }

        return WidgetReminder(
            item = item,
            status = status,
            nextDueKm = nextDueKm,
            estimatedDueAt = estimatedDueAt,
        )
    }

    private fun buildPayload(vehicle: WidgetVehicle, reminder: WidgetReminder?): WidgetPayload {
        val title = if (vehicle.licensePlate.trim().isEmpty()) {
            vehicle.name
        } else {
            "${vehicle.name} (${vehicle.licensePlate.trim()})"
        }
        val subtitle = "${formatKm(vehicle.currentKm)} km hiện tại • ${String.format(Locale.US, "%.1f", vehicle.dailyKm)} km/ngày"
        if (reminder == null) {
            return WidgetPayload(
                vehicleId = vehicle.id,
                title = title,
                subtitle = subtitle,
                reminderText = "Chưa có hạng mục bảo dưỡng.",
                reminderKind = "noItems",
                itemName = "",
                dueAtMillis = null,
                status = "ok",
                imagePath = vehicle.imagePath,
            )
        }

        val dueAt = reminder.estimatedDueAt
        val text = if (dueAt == null) {
            "Cần nhập km/ngày để tính bảo dưỡng tiếp theo • ${reminder.item.name}"
        } else {
            "Bảo dưỡng tiếp theo: ${relativeDateLabel(dueAt)} • ${reminder.item.name}"
        }
        return WidgetPayload(
            vehicleId = vehicle.id,
            title = title,
            subtitle = subtitle,
            reminderText = text,
            reminderKind = if (dueAt == null) "missingDailyKm" else "dueDate",
            itemName = reminder.item.name,
            dueAtMillis = dueAt,
            status = reminder.status,
            imagePath = vehicle.imagePath,
        )
    }

    private fun relativeDateLabel(targetMillis: Long): String {
        val today = dateOnly(System.currentTimeMillis())
        val target = dateOnly(targetMillis)
        val days = daysBetween(today, target)
        if (days == 0) return "Hôm nay"
        if (days == 1) return "Ngày mai"
        if (days == -1) return "Hôm qua"
        return if (days > 0) "${relativeUnit(days)} nữa" else "${relativeUnit(kotlin.math.abs(days))} trước"
    }

    private fun relativeUnit(days: Int): String {
        if (days < 30) return "$days ngày"
        if (days < 365) return "${(days / 30.0).roundToInt().coerceIn(1, 12)} tháng"
        return "${(days / 365.0).roundToInt().coerceIn(1, 999)} năm"
    }

    private fun dateOnly(millis: Long): Long {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = millis
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return calendar.timeInMillis
    }

    private fun addDays(millis: Long, days: Int): Long {
        return Calendar.getInstance().apply {
            timeInMillis = millis
            add(Calendar.DAY_OF_YEAR, days)
        }.timeInMillis
    }

    private fun daysBetween(start: Long, end: Long): Int {
        return ((end - start) / 86_400_000L).toInt()
    }

    private fun earliest(first: Long?, second: Long?): Long? {
        if (first == null) return second
        if (second == null) return first
        return minOf(first, second)
    }

    private fun formatKm(value: Double): String {
        return if (value == value.toLong().toDouble()) value.toLong().toString() else value.toString()
    }

    private fun Cursor.string(column: String): String = getString(getColumnIndexOrThrow(column))
    private fun Cursor.int(column: String): Int = getInt(getColumnIndexOrThrow(column))
    private fun Cursor.double(column: String): Double = getDouble(getColumnIndexOrThrow(column))
    private fun Cursor.nullableLong(column: String): Long? {
        val index = getColumnIndexOrThrow(column)
        return if (isNull(index)) null else getLong(index)
    }

    private data class WidgetVehicle(
        val id: String,
        val name: String,
        val licensePlate: String,
        val imagePath: String,
        val currentKm: Double,
        val dailyKm: Double,
        val groupingWindowDays: Int,
    )

    private data class WidgetItem(
        val name: String,
        val intervalMinKm: Int,
        val intervalMaxKm: Int,
        val intervalMinDays: Int,
        val intervalMaxDays: Int,
        val lastServiceKm: Double,
        val lastServiceDate: Long?,
        val isEnabled: Boolean,
    )

    private data class WidgetReminder(
        val item: WidgetItem,
        val status: String,
        val nextDueKm: Double,
        val estimatedDueAt: Long?,
    )

    private data class WidgetPayload(
        val vehicleId: String,
        val title: String,
        val subtitle: String,
        val reminderText: String,
        val reminderKind: String,
        val itemName: String,
        val dueAtMillis: Long?,
        val status: String,
        val imagePath: String,
    )
}
