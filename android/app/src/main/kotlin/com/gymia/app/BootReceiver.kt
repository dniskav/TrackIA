package com.gymia.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Reprograms the reminders after a reboot or a clock/zone change; ignores any other action. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED ->
                Reminders.scheduleAll(context.applicationContext)
            else -> Unit
        }
    }
}
