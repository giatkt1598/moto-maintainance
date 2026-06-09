package com.example.moto_maintainance

import android.content.Context
import android.content.Intent
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        persistPendingWidgetVehicle(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        persistPendingWidgetVehicle(intent)
        scheduleVehicleWidgetSync()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VehicleWidgetProvider.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences(
                VehicleWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE,
            )

            when (call.method) {
                "getSelectedVehicleId" -> {
                    result.success(prefs.getString(VehicleWidgetProvider.KEY_SELECTED_VEHICLE_ID, null))
                }

                "consumePendingOpenVehicleId" -> {
                    val vehicleId = prefs.getString(VehicleWidgetProvider.KEY_PENDING_OPEN_VEHICLE_ID, null)
                    prefs.edit().remove(VehicleWidgetProvider.KEY_PENDING_OPEN_VEHICLE_ID).apply()
                    result.success(vehicleId)
                }

                "setSelectedVehicleId" -> {
                    val vehicleId = call.argument<String>("vehicleId")
                    prefs.edit().apply {
                        if (vehicleId.isNullOrEmpty()) {
                            remove(VehicleWidgetProvider.KEY_SELECTED_VEHICLE_ID)
                        } else {
                            putString(VehicleWidgetProvider.KEY_SELECTED_VEHICLE_ID, vehicleId)
                        }
                    }.apply()
                    VehicleWidgetSyncer.sync(this)
                    VehicleWidgetProvider.updateAll(this)
                    result.success(null)
                }

                "updateVehicleWidget" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("invalid_args", "Missing widget payload", null)
                        return@setMethodCallHandler
                    }

                    prefs.edit()
                        .putBoolean(VehicleWidgetProvider.KEY_HAS_DATA, true)
                        .putString(VehicleWidgetProvider.KEY_VEHICLE_ID, args["vehicleId"] as? String ?: "")
                        .putString(VehicleWidgetProvider.KEY_TITLE, args["title"] as? String ?: "")
                        .putString(VehicleWidgetProvider.KEY_SUBTITLE, args["subtitle"] as? String ?: "")
                        .putString(VehicleWidgetProvider.KEY_REMINDER, args["reminderText"] as? String ?: "")
                        .putString(VehicleWidgetProvider.KEY_REMINDER_KIND, args["reminderKind"] as? String ?: "")
                        .putString(VehicleWidgetProvider.KEY_ITEM_NAME, args["itemName"] as? String ?: "")
                        .putLong(VehicleWidgetProvider.KEY_DUE_AT_MILLIS, (args["dueAtMillis"] as? Number)?.toLong() ?: 0L)
                        .putString(VehicleWidgetProvider.KEY_STATUS, args["status"] as? String ?: "ok")
                        .putString(VehicleWidgetProvider.KEY_IMAGE_PATH, args["imagePath"] as? String ?: "")
                        .apply()
                    VehicleWidgetProvider.updateAll(this)
                    result.success(null)
                }

                "clearVehicleWidget" -> {
                    prefs.edit()
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
                    VehicleWidgetProvider.updateAll(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun persistPendingWidgetVehicle(intent: Intent?) {
        val vehicleId = intent?.getStringExtra(VehicleWidgetProvider.EXTRA_OPEN_VEHICLE_ID)
        if (vehicleId.isNullOrEmpty()) return
        getSharedPreferences(VehicleWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(VehicleWidgetProvider.KEY_PENDING_OPEN_VEHICLE_ID, vehicleId)
            .apply()
    }

    private fun scheduleVehicleWidgetSync() {
        val request = PeriodicWorkRequestBuilder<VehicleWidgetSyncWorker>(
            15,
            TimeUnit.MINUTES,
        ).build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            VehicleWidgetSyncWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }
}
