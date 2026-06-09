package com.example.moto_maintainance

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(context, appWidgetManager, appWidgetId)
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
            val compact = isCompact(manager, appWidgetId)
            val views = RemoteViews(
                context.packageName,
                if (compact) R.layout.vehicle_widget else R.layout.vehicle_widget_expanded,
            )
            val hasData = prefs.getBoolean(KEY_HAS_DATA, false)

            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context, prefs.getString(KEY_VEHICLE_ID, null)))

            if (!hasData) {
                views.setViewVisibility(R.id.widget_image, View.GONE)
                views.setTextViewText(R.id.widget_title, "")
                views.setTextViewText(
                    R.id.widget_subtitle,
                    "Chọn xe trong Cài đặt",
                )
                views.setTextViewText(R.id.widget_reminder, "")
                views.setViewVisibility(R.id.widget_reminder, View.GONE)
                views.setViewVisibility(R.id.widget_status_icon, View.GONE)
                views.setTextColor(R.id.widget_subtitle, Color.rgb(156, 163, 175))
                views.setTextColor(R.id.widget_reminder, Color.rgb(156, 163, 175))
                manager.updateAppWidget(appWidgetId, views)
                return
            }

            val imagePath = prefs.getString(KEY_IMAGE_PATH, "").orEmpty()
            val bitmap = decodeWidgetBitmap(imagePath)
            if (bitmap == null) {
                views.setViewVisibility(R.id.widget_image, View.GONE)
            } else {
                views.setImageViewBitmap(R.id.widget_image, trimTransparentPadding(bitmap))
                views.setViewVisibility(R.id.widget_image, View.VISIBLE)
            }

            views.setTextViewText(
                R.id.widget_title,
                if (compact) {
                    titleLine(
                        title = prefs.getString(KEY_TITLE, "").orEmpty(),
                        subtitle = prefs.getString(KEY_SUBTITLE, "").orEmpty(),
                    )
                } else {
                    prefs.getString(KEY_TITLE, "").orEmpty()
                },
            )
            val reminder = reminderText(
                kind = prefs.getString(KEY_REMINDER_KIND, "").orEmpty(),
                fallback = prefs.getString(KEY_REMINDER, "").orEmpty(),
                itemName = prefs.getString(KEY_ITEM_NAME, "").orEmpty(),
                dueAtMillis = prefs.getLong(KEY_DUE_AT_MILLIS, 0L),
            )
            if (compact) {
                views.setTextViewText(R.id.widget_subtitle, reminder)
                views.setTextViewText(R.id.widget_reminder, "")
                views.setViewVisibility(R.id.widget_reminder, View.GONE)
            } else {
                views.setTextViewText(
                    R.id.widget_subtitle,
                    prefs.getString(KEY_SUBTITLE, "").orEmpty(),
                )
                views.setTextViewText(R.id.widget_reminder, reminder)
                views.setViewVisibility(R.id.widget_reminder, View.VISIBLE)
            }
            val status = prefs.getString(KEY_STATUS, "ok").orEmpty()
            views.setImageViewBitmap(R.id.widget_status_icon, statusIcon(status))
            views.setViewVisibility(R.id.widget_status_icon, View.VISIBLE)
            views.setTextColor(R.id.widget_subtitle, if (compact) Color.WHITE else Color.rgb(209, 213, 219))
            views.setTextColor(
                R.id.widget_reminder,
                Color.WHITE,
            )

            manager.updateAppWidget(appWidgetId, views)
        }

        private fun isCompact(manager: AppWidgetManager, appWidgetId: Int): Boolean {
            val options = manager.getAppWidgetOptions(appWidgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            return minHeight <= 100
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

        private fun statusIcon(status: String): Bitmap {
            val size = 48
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val center = size / 2f

            paint.color = statusColor(status)
            paint.style = Paint.Style.FILL
            canvas.drawCircle(center, center, 21f, paint)

            paint.color = Color.WHITE
            paint.strokeWidth = 5f
            paint.strokeCap = Paint.Cap.ROUND
            paint.strokeJoin = Paint.Join.ROUND
            paint.style = Paint.Style.STROKE

            when (status) {
                "overdue" -> {
                    canvas.drawLine(center, 12f, center, 28f, paint)
                    paint.style = Paint.Style.FILL
                    canvas.drawCircle(center, 36f, 2.8f, paint)
                }
                "due", "dueSoon" -> {
                    canvas.drawCircle(center, center, 10f, paint)
                    canvas.drawLine(center, center, center, 17f, paint)
                    canvas.drawLine(center, center, 31f, center, paint)
                }
                "missingDailyKm" -> {
                    paint.textAlign = Paint.Align.CENTER
                    paint.textSize = 31f
                    paint.style = Paint.Style.FILL
                    paint.strokeWidth = 0f
                    paint.typeface = android.graphics.Typeface.DEFAULT_BOLD
                    canvas.drawText("?", center, 35f, paint)
                }
                else -> {
                    canvas.drawLine(13f, 25f, 21f, 33f, paint)
                    canvas.drawLine(21f, 33f, 35f, 16f, paint)
                }
            }

            return bitmap
        }

        private fun titleLine(title: String, subtitle: String): String {
            if (title.isEmpty()) return subtitle
            if (subtitle.isEmpty()) return title
            return "$title ($subtitle)"
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

        private fun trimTransparentPadding(bitmap: Bitmap): Bitmap {
            if (!bitmap.hasAlpha()) return bitmap

            val bounds = transparentBounds(bitmap) ?: return bitmap
            if (bounds.width() == bitmap.width && bounds.height() == bitmap.height) {
                return bitmap
            }

            return Bitmap.createBitmap(
                bitmap,
                bounds.left,
                bounds.top,
                bounds.width(),
                bounds.height(),
            )
        }

        private fun transparentBounds(bitmap: Bitmap): Rect? {
            var left = bitmap.width
            var top = bitmap.height
            var right = -1
            var bottom = -1

            val pixels = IntArray(bitmap.width)
            for (y in 0 until bitmap.height) {
                bitmap.getPixels(pixels, 0, bitmap.width, 0, y, bitmap.width, 1)
                for (x in 0 until bitmap.width) {
                    val alpha = pixels[x] ushr 24
                    if (alpha > 8) {
                        if (x < left) left = x
                        if (x > right) right = x
                        if (y < top) top = y
                        if (y > bottom) bottom = y
                    }
                }
            }

            if (right < left || bottom < top) return null
            return Rect(left, top, right + 1, bottom + 1)
        }
    }
}
