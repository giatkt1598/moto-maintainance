package com.example.moto_maintainance

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import java.io.File
import java.util.Calendar
import java.util.concurrent.TimeUnit

class VehicleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val CHANNEL_NAME = "moto_maintainance/vehicle_widget"
        const val PREFS_NAME = "vehicle_widget"
        const val KEY_SELECTED_VEHICLE_ID = "selected_vehicle_id"
        const val KEY_HAS_DATA = "has_data"
        const val KEY_VEHICLE_ID = "vehicle_id"
        const val KEY_TITLE = "title"
        const val KEY_SUBTITLE = "subtitle"
        const val KEY_REMINDER = "reminder"
        const val KEY_REMINDER_KIND = "reminder_kind"
        const val KEY_ITEM_NAME = "item_name"
        const val KEY_DUE_AT_MILLIS = "due_at_millis"
        const val KEY_STATUS = "status"
        const val KEY_IMAGE_PATH = "image_path"
        const val EXTRA_OPEN_VEHICLE_ID = "open_vehicle_id"
        const val KEY_PENDING_OPEN_VEHICLE_ID = "pending_open_vehicle_id"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, VehicleWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.vehicle_widget)
            val hasData = prefs.getBoolean(KEY_HAS_DATA, false)

            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context, prefs.getString(KEY_VEHICLE_ID, null)))

            if (!hasData) {
                views.setViewVisibility(R.id.widget_image, View.GONE)
                views.setTextViewText(R.id.widget_title, "")
                views.setTextViewText(
                    R.id.widget_subtitle,
                    "Chọn xe trong Cài đặt để hiển thị widget",
                )
                views.setTextViewText(R.id.widget_reminder, "Chưa chọn xe")
                views.setTextColor(R.id.widget_reminder, Color.rgb(156, 163, 175))
                manager.updateAppWidget(appWidgetId, views)
                return
            }

            val imagePath = prefs.getString(KEY_IMAGE_PATH, "").orEmpty()
            val bitmap = decodeWidgetBitmap(imagePath)
            if (bitmap == null) {
                views.setViewVisibility(R.id.widget_image, View.GONE)
            } else {
                views.setImageViewBitmap(R.id.widget_image, bitmap)
                views.setViewVisibility(R.id.widget_image, View.VISIBLE)
            }

            views.setTextViewText(
                R.id.widget_title,
                prefs.getString(KEY_TITLE, "").orEmpty(),
            )
            views.setTextViewText(
                R.id.widget_subtitle,
                prefs.getString(KEY_SUBTITLE, "").orEmpty(),
            )
            views.setTextViewText(
                R.id.widget_reminder,
                reminderText(
                    kind = prefs.getString(KEY_REMINDER_KIND, "").orEmpty(),
                    fallback = prefs.getString(KEY_REMINDER, "").orEmpty(),
                    itemName = prefs.getString(KEY_ITEM_NAME, "").orEmpty(),
                    dueAtMillis = prefs.getLong(KEY_DUE_AT_MILLIS, 0L),
                ),
            )
            views.setTextColor(
                R.id.widget_reminder,
                statusColor(prefs.getString(KEY_STATUS, "ok").orEmpty()),
            )

            manager.updateAppWidget(appWidgetId, views)
        }

        private fun openAppIntent(context: Context, vehicleId: String?): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                if (!vehicleId.isNullOrEmpty()) {
                    putExtra(EXTRA_OPEN_VEHICLE_ID, vehicleId)
                }
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            return PendingIntent.getActivity(context, 0, intent, flags)
        }

        private fun statusColor(status: String): Int {
            return when (status) {
                "dueSoon" -> Color.rgb(147, 197, 253)
                "due" -> Color.rgb(251, 191, 36)
                "overdue" -> Color.rgb(248, 113, 113)
                "missingDailyKm" -> Color.rgb(156, 163, 175)
                else -> Color.rgb(74, 222, 128)
            }
        }

        private fun reminderText(
            kind: String,
            fallback: String,
            itemName: String,
            dueAtMillis: Long,
        ): String {
            return when (kind) {
                "noItems" -> "Chưa có hạng mục bảo dưỡng."
                "missingDailyKm" -> "Cần nhập km/ngày để tính bảo dưỡng tiếp theo • $itemName"
                "dueDate" -> {
                    if (dueAtMillis <= 0L) {
                        fallback
                    } else {
                        "Bảo dưỡng tiếp theo: ${relativeDateLabel(dueAtMillis)} • $itemName"
                    }
                }
                else -> fallback
            }
        }

        private fun relativeDateLabel(targetMillis: Long): String {
            val today = dateOnly(Calendar.getInstance())
            val target = dateOnly(Calendar.getInstance().apply {
                timeInMillis = targetMillis
            })
            val days = TimeUnit.MILLISECONDS.toDays(target.timeInMillis - today.timeInMillis).toInt()

            if (days == 0) return "Hôm nay"
            if (days == 1) return "Ngày mai"
            if (days == -1) return "Hôm qua"

            return if (days > 0) {
                "${relativeUnit(days)} nữa"
            } else {
                "${relativeUnit(kotlin.math.abs(days))} trước"
            }
        }

        private fun relativeUnit(days: Int): String {
            if (days < 30) return "$days ngày"
            if (days < 365) {
                val months = (days / 30.0).let { kotlin.math.round(it).toInt() }.coerceIn(1, 12)
                return "$months tháng"
            }
            val years = (days / 365.0).let { kotlin.math.round(it).toInt() }.coerceIn(1, 999)
            return "$years năm"
        }

        private fun dateOnly(calendar: Calendar): Calendar {
            return calendar.apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
        }

        private fun decodeWidgetBitmap(path: String): Bitmap? {
            if (path.isEmpty()) return null
            val file = File(path)
            if (!file.exists()) return null

            val bounds = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, bounds)

            val maxDimension = maxOf(bounds.outWidth, bounds.outHeight)
            var sampleSize = 1
            while (maxDimension / sampleSize > 720) {
                sampleSize *= 2
            }

            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
            }
            return BitmapFactory.decodeFile(path, options)
        }
    }
}
