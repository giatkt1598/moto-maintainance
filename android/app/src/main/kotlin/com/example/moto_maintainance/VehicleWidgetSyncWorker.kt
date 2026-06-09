package com.example.moto_maintainance

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class VehicleWidgetSyncWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {
    override fun doWork(): Result {
        try {
            VehicleWidgetSyncer.sync(applicationContext)
        } catch (_: Exception) {
            // Fail-soft: widget sync sẽ thử lại ở chu kỳ tiếp theo, tránh retry dồn dập.
        }
        return Result.success()
    }

    companion object {
        const val WORK_NAME = "vehicle_widget_sync"
    }
}
