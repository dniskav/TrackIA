package com.gymia.app

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.SystemClock
import java.util.UUID

object RestNotifications {
    private const val channelId = "gymia_rest"
    const val alarmChannelId = "trackia_timer_alarm_v1"
    private const val requestId = 8401
    private const val testRequestId = 8403
    private const val startRequestId = 8404
    private const val closeRequestId = 8405
    private const val preparedRequestId = 8406
    private const val preparedStartRequestId = 8407
    private const val preparedCloseRequestId = 8408
    private const val resultRequestId = 8409
    private const val runningRequestId = 8410
    private const val stopRequestId = 8411
    private const val activityAlarmRequestId = 8412
    private const val activityCloseRequestId = 8413
    private const val testAlarmRequestId = 8414
    const val startAction = "com.gymia.app.START_REST_ACTIVITY"
    const val stopAction = "com.gymia.app.STOP_RUNNING_ACTIVITY"
    const val closeAction = "com.gymia.app.CLOSE_REST_NOTICE"
    private val brandTeal = Color.rgb(2, 125, 146)
    private val brandOrange = Color.rgb(255, 106, 26)
    private fun brandIcon(): Bitmap {
        val bitmap = Bitmap.createBitmap(192, 192, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = brandTeal
        canvas.drawCircle(96f, 96f, 92f, paint)
        paint.color = brandOrange
        val accent = Path().apply {
            moveTo(132f, 25f)
            lineTo(165f, 25f)
            lineTo(165f, 58f)
            lineTo(155f, 48f)
            lineTo(143f, 60f)
            lineTo(130f, 47f)
            lineTo(142f, 35f)
            close()
        }
        canvas.drawPath(accent, paint)
        paint.color = Color.WHITE
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        paint.textSize = 31f
        paint.textAlign = Paint.Align.CENTER
        val baseline = 101f - (paint.fontMetrics.ascent + paint.fontMetrics.descent) / 2f
        canvas.drawText("TrackIA", 96f, baseline, paint)
        return bitmap
    }
    fun preferences(context: Context) = context.getSharedPreferences("gymia_rest", Context.MODE_PRIVATE)
    fun runtimePermissionGranted(context: Context): Boolean =
        Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    fun permitted(context: Context): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java)
        return runtimePermissionGranted(context) &&
            (Build.VERSION.SDK_INT < 24 || manager.areNotificationsEnabled()) &&
            (Build.VERSION.SDK_INT < 26 || manager.getNotificationChannel(channelId)?.importance != NotificationManager.IMPORTANCE_NONE)
    }
    fun alarmStyle(context: Context): Boolean = preferences(context).getBoolean("alarmStyle", true)
    /** Alarm-usage channel: Android lets alarms through Do Not Disturb priority mode. */
    fun ensureAlarmChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < 26) return
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        manager.createNotificationChannel(NotificationChannel(alarmChannelId, "Fin de descanso y tramo", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Suena como una alarma cuando termina un descanso o un tramo con duración."
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 400, 200, 400)
            setSound(sound, AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build())
        })
    }
    /** Builder for the end-of-rest and end-of-segment notices; null when the user blocked the channel. */
    private fun timerBuilder(context: Context, manager: NotificationManager): Notification.Builder? {
        val alarm = alarmStyle(context)
        val builder: Notification.Builder
        if (Build.VERSION.SDK_INT >= 26) {
            if (alarm) ensureAlarmChannel(manager)
            val id = if (alarm) alarmChannelId else channelId
            if (manager.getNotificationChannel(id)?.importance == NotificationManager.IMPORTANCE_NONE) return null
            builder = Notification.Builder(context, id)
        } else builder = Notification.Builder(context)
        if (alarm) builder.setCategory(Notification.CATEGORY_ALARM)
        return builder
    }
    /** True while any Do Not Disturb mode restricts interruptions. */
    fun dnd(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 23) return false
        val filter = context.getSystemService(NotificationManager::class.java).currentInterruptionFilter
        return filter != NotificationManager.INTERRUPTION_FILTER_ALL && filter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN
    }
    fun dndFilter(context: Context): Int =
        if (Build.VERSION.SDK_INT < 23) 1 else context.getSystemService(NotificationManager::class.java).currentInterruptionFilter
    fun alarmChannelBlocked(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 26) return false
        val manager = context.getSystemService(NotificationManager::class.java)
        return manager.getNotificationChannel(alarmChannelId)?.importance == NotificationManager.IMPORTANCE_NONE
    }
    fun scheduleTestAlarm(context: Context): Boolean {
        if (!preferences(context).getBoolean("enabled", false) || !permitted(context)) return false
        val alarm = context.getSystemService(AlarmManager::class.java)
        val intent = PendingIntent.getBroadcast(context, testAlarmRequestId,
            Intent(context, RestAlarmReceiver::class.java).putExtra("kind", "test"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        alarm.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, SystemClock.elapsedRealtime() + 5000, intent)
        return true
    }
    fun notifyTimerTest(context: Context): Boolean {
        if (!preferences(context).getBoolean("enabled", false) || !permitted(context)) return false
        val manager = context.getSystemService(NotificationManager::class.java)
        val builder = timerBuilder(context, manager) ?: return false
        val open = PendingIntent.getActivity(context, testAlarmRequestId, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager.notify(testAlarmRequestId, builder.setSmallIcon(R.drawable.ic_trackia)
            .setLargeIcon(brandIcon()).setColor(brandTeal)
            .setContentTitle("Prueba del aviso de descanso")
            .setContentText(if (alarmStyle(context)) "Suena como una alarma." else "Aviso normal.")
            .setContentIntent(open).setAutoCancel(true).setTimeoutAfter(15000)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setDefaults(Notification.DEFAULT_ALL).build())
        return true
    }
    fun exact(context: Context): Boolean = Build.VERSION.SDK_INT < 31 ||
        context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()
    private fun pending(context: Context, id: String = "", end: Long = 0, name: String = ""): PendingIntent =
        PendingIntent.getBroadcast(context, requestId,
            Intent(context, RestAlarmReceiver::class.java).putExtra("id", id).putExtra("end", end).putExtra("name", name),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun pendingActivity(context: Context, id: String = "", end: Long = 0, name: String = ""): PendingIntent =
        PendingIntent.getBroadcast(context, activityAlarmRequestId,
            Intent(context, RestAlarmReceiver::class.java).putExtra("id", id).putExtra("end", end)
                .putExtra("name", name).putExtra("kind", "activity"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(pending(context))
        context.getSystemService(AlarmManager::class.java).cancel(pendingActivity(context))
        preferences(context).edit().remove("id").remove("end").remove("profileId").remove("actionNonce")
            .remove("activityId").remove("activityEnd").remove("activityProfileId")
            .remove("preparedId").remove("preparedRevision").remove("preparedNonce")
            .remove("preparedDismissed").apply()
        preferences(context).edit().remove("runningNonce").remove("runningId").remove("runningRevision").apply()
        context.getSystemService(NotificationManager::class.java).cancel(requestId)
        context.getSystemService(NotificationManager::class.java).cancel(preparedRequestId)
        context.getSystemService(NotificationManager::class.java).cancel(runningRequestId)
    }
    fun schedule(context: Context, id: String, end: Long, name: String, profileId: String) {
        cancel(context)
        if (!preferences(context).getBoolean("enabled", false) || !permitted(context) || end <= System.currentTimeMillis()) return
        preferences(context).edit().putString("id", id).putLong("end", end).putString("profileId", profileId).apply()
        val alarm = context.getSystemService(AlarmManager::class.java)
        val trigger = SystemClock.elapsedRealtime() + (end - System.currentTimeMillis())
        val intent = pending(context, id, end, name)
        if (exact(context)) alarm.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, trigger, intent)
        else alarm.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, trigger, intent)
    }
    fun notify(context: Context, name: String, id: String, end: Long, profileId: String): Boolean {
        if (!permitted(context)) return false
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channelId, "Actividad y descanso", NotificationManager.IMPORTANCE_HIGH).apply {
                enableVibration(true)
                description = "Avisa al preparar una actividad y cuando termina el descanso."
            })
        }
        val builder = timerBuilder(context, manager) ?: return false
        val open = PendingIntent.getActivity(context, requestId, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val nonce = UUID.randomUUID().toString()
        preferences(context).edit().putString("actionNonce", nonce).apply()
        val start = PendingIntent.getActivity(context, startRequestId,
            Intent(context, MainActivity::class.java).setAction(startAction)
                .putExtra("id", id).putExtra("end", end).putExtra("profileId", profileId).putExtra("nonce", nonce)
                .putExtra("kind", "rest")
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val close = PendingIntent.getBroadcast(context, closeRequestId,
            Intent(context, RestActionReceiver::class.java).setAction(closeAction)
                .putExtra("nonce", nonce).putExtra("kind", "rest"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager.notify(requestId, builder.setSmallIcon(R.drawable.ic_trackia)
            .setLargeIcon(brandIcon()).setColor(brandTeal)
            .setContentTitle("Descanso terminado")
            .setContentText("$name · puedes comenzar cuando quieras")
            .setContentIntent(open).setAutoCancel(true)
            .addAction(R.drawable.ic_trackia, "Iniciar", start)
            .addAction(R.drawable.ic_trackia, "Cerrar", close)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setDefaults(Notification.DEFAULT_ALL).build())
        return true
    }
    fun notifyPrepared(context: Context, name: String, id: String, revision: Long, profileId: String): Boolean {
        if (!preferences(context).getBoolean("enabled", false) || !permitted(context)) return false
        val prefs = preferences(context)
        if (prefs.getString("preparedId", null) == id && prefs.getLong("preparedRevision", 0) == revision) {
            return !prefs.getBoolean("preparedDismissed", false)
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channelId, "Actividad y descanso", NotificationManager.IMPORTANCE_HIGH))
            if (manager.getNotificationChannel(channelId)?.importance == NotificationManager.IMPORTANCE_NONE) return false
        }
        val nonce = UUID.randomUUID().toString()
        prefs.edit().putString("preparedId", id).putLong("preparedRevision", revision)
            .putString("preparedNonce", nonce).putBoolean("preparedDismissed", false).apply()
        val start = PendingIntent.getActivity(context, preparedStartRequestId,
            Intent(context, MainActivity::class.java).setAction(startAction)
                .putExtra("id", id).putExtra("end", 0L).putExtra("profileId", profileId)
                .putExtra("revision", revision).putExtra("nonce", nonce).putExtra("kind", "prepared")
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val close = PendingIntent.getBroadcast(context, preparedCloseRequestId,
            Intent(context, RestActionReceiver::class.java).setAction(closeAction)
                .putExtra("nonce", nonce).putExtra("kind", "prepared"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(context, preparedRequestId, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId) else Notification.Builder(context)
        manager.notify(preparedRequestId, builder.setSmallIcon(R.drawable.ic_trackia)
            .setLargeIcon(brandIcon()).setColor(brandTeal)
            .setContentTitle("Actividad lista").setContentText("$name · inicia cuando quieras")
            .setContentIntent(open).setAutoCancel(true)
            .addAction(R.drawable.ic_trackia, "Iniciar", start)
            .addAction(R.drawable.ic_trackia, "Cerrar", close)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setDefaults(Notification.DEFAULT_ALL).build())
        return true
    }
    fun notifyRunning(context: Context, name: String, id: String, revision: Long, profileId: String, end: Long): Boolean {
        if (!preferences(context).getBoolean("enabled", false) || !permitted(context)) return false
        val prefs = preferences(context)
        if (prefs.getString("runningId", null) == id && prefs.getLong("runningRevision", 0) == revision) {
            scheduleActivityAlarm(context, id, end, name, profileId)
            return true
        }
        cancel(context)
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channelId, "Actividad y descanso", NotificationManager.IMPORTANCE_HIGH))
            if (manager.getNotificationChannel(channelId)?.importance == NotificationManager.IMPORTANCE_NONE) return false
        }
        val nonce = UUID.randomUUID().toString()
        prefs.edit().putString("runningId", id).putLong("runningRevision", revision).putString("runningNonce", nonce).apply()
        val stop = PendingIntent.getActivity(context, stopRequestId,
            Intent(context, MainActivity::class.java).setAction(stopAction)
                .putExtra("id", id).putExtra("end", 0L).putExtra("profileId", profileId)
                .putExtra("revision", revision).putExtra("nonce", nonce).putExtra("kind", "running")
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(context, runningRequestId, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId) else Notification.Builder(context)
        manager.notify(runningRequestId, builder.setSmallIcon(R.drawable.ic_trackia)
            .setLargeIcon(brandIcon()).setColor(brandTeal)
            .setContentTitle("Actividad en curso").setContentText(name)
            .setContentIntent(open).addAction(R.drawable.ic_trackia, "Parar", stop)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setOnlyAlertOnce(true).build())
        scheduleActivityAlarm(context, id, end, name, profileId)
        return true
    }
    private fun scheduleActivityAlarm(context: Context, id: String, end: Long, name: String, profileId: String) {
        if (end <= 0) return
        val prefs = preferences(context)
        if (prefs.getString("activityId", null) == id && prefs.getLong("activityEnd", 0) == end) return
        val alarm = context.getSystemService(AlarmManager::class.java)
        alarm.cancel(pendingActivity(context))
        prefs.edit().putString("activityId", id).putLong("activityEnd", end)
            .putString("activityProfileId", profileId).apply()
        if (end <= System.currentTimeMillis()) {
            notifyActivityFinished(context, name, id, end)
            return
        }
        val trigger = SystemClock.elapsedRealtime() + (end - System.currentTimeMillis())
        val intent = pendingActivity(context, id, end, name)
        if (exact(context)) alarm.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, trigger, intent)
        else alarm.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, trigger, intent)
    }
    fun notifyActivityFinished(context: Context, name: String, id: String, end: Long): Boolean {
        val prefs = preferences(context)
        if (!prefs.getBoolean("enabled", false) || !permitted(context) ||
            prefs.getString("activityId", null) != id || prefs.getLong("activityEnd", 0) != end) return false
        val nonce = prefs.getString("runningNonce", null) ?: return false
        val manager = context.getSystemService(NotificationManager::class.java)
        val stop = PendingIntent.getActivity(context, stopRequestId,
            Intent(context, MainActivity::class.java).setAction(stopAction)
                .putExtra("id", id).putExtra("end", 0L)
                .putExtra("profileId", prefs.getString("activityProfileId", "local"))
                .putExtra("revision", prefs.getLong("runningRevision", 0))
                .putExtra("nonce", nonce).putExtra("kind", "running")
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val close = PendingIntent.getBroadcast(context, activityCloseRequestId,
            Intent(context, RestActionReceiver::class.java).setAction(closeAction)
                .putExtra("nonce", nonce).putExtra("kind", "running"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(context, runningRequestId,
            Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = timerBuilder(context, manager) ?: return false
        manager.notify(runningRequestId, builder.setSmallIcon(R.drawable.ic_trackia)
            .setLargeIcon(brandIcon()).setColor(brandTeal)
            .setContentTitle("Tramo terminado").setContentText("$name · tiempo cumplido")
            .setContentIntent(open).setAutoCancel(true)
            .addAction(R.drawable.ic_trackia, "Parar", stop)
            .addAction(R.drawable.ic_trackia, "Cerrar", close)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setDefaults(Notification.DEFAULT_ALL).build())
        prefs.edit().putString("lastDeliveredId", id).putLong("lastDeliveredEnd", end).apply()
        return true
    }
    @Synchronized fun captureStartAction(context: Context, intent: Intent?): Boolean {
        if (intent?.action != startAction && intent?.action != stopAction) return false
        val prefs = preferences(context)
        val nonce = intent.getStringExtra("nonce") ?: return false
        val kind = intent.getStringExtra("kind") ?: return false
        if (kind !in setOf("rest", "prepared", "running") ||
            (kind == "running") != (intent.action == stopAction) ||
            nonce != prefs.getString(when (kind) { "rest" -> "actionNonce"; "prepared" -> "preparedNonce"; else -> "runningNonce" }, null)) return false
        val id = intent.getStringExtra("id") ?: return false
        val end = intent.getLongExtra("end", 0)
        val revision = intent.getLongExtra("revision", 0)
        val profileId = intent.getStringExtra("profileId") ?: return false
        if ((kind == "rest" && end <= 0) || (kind != "rest" && revision <= 0) || profileId.isBlank()) return false
        prefs.edit().remove(when (kind) { "rest" -> "actionNonce"; "prepared" -> "preparedNonce"; else -> "runningNonce" })
            .putString("pendingActionId", id).putLong("pendingActionEnd", end)
            .putString("pendingActionProfile", profileId).putString("pendingActionKind", kind)
            .putLong("pendingActionRevision", revision)
            .putLong("pendingActionRequestedAt", System.currentTimeMillis()).commit()
        context.getSystemService(NotificationManager::class.java).cancel(when (kind) { "rest" -> requestId; "prepared" -> preparedRequestId; else -> runningRequestId })
        return true
    }
    fun pendingAction(context: Context): Map<String, Any>? {
        val prefs = preferences(context)
        val id = prefs.getString("pendingActionId", null) ?: return null
        return mapOf("id" to id, "end" to prefs.getLong("pendingActionEnd", 0),
            "profileId" to (prefs.getString("pendingActionProfile", null) ?: ""),
            "kind" to (prefs.getString("pendingActionKind", null) ?: ""),
            "revision" to prefs.getLong("pendingActionRevision", 0),
            "requestedAt" to prefs.getLong("pendingActionRequestedAt", 0))
    }
    fun completeAction(context: Context, id: String, end: Long, profileId: String, kind: String, revision: Long, success: Boolean): Boolean {
        val current = pendingAction(context) ?: return false
        if (current["id"] != id || current["end"] != end || current["profileId"] != profileId ||
            current["kind"] != kind || current["revision"] != revision) return false
        preferences(context).edit().remove("pendingActionId").remove("pendingActionEnd")
            .remove("pendingActionProfile").remove("pendingActionKind").remove("pendingActionRevision")
            .remove("pendingActionRequestedAt").commit()
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.cancel(resultRequestId)
        if (success) return true
        val open = PendingIntent.getActivity(context, resultRequestId, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId) else Notification.Builder(context)
        if (Build.VERSION.SDK_INT >= 26) builder.setTimeoutAfter(10000)
        manager.notify(resultRequestId, builder.setSmallIcon(R.drawable.ic_trackia)
            .setLargeIcon(brandIcon()).setColor(brandTeal)
            .setContentTitle("No se pudo completar la acción")
            .setContentText("Abre TrackIA y revisa la actividad actual.")
            .setContentIntent(open).setAutoCancel(true).setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE).build())
        return true
    }
    @Synchronized fun closeNotice(context: Context, nonce: String?, kind: String?): Boolean {
        val prefs = preferences(context)
        if (kind !in setOf("rest", "prepared", "running") || nonce == null ||
            nonce != prefs.getString(when (kind) { "rest" -> "actionNonce"; "prepared" -> "preparedNonce"; else -> "runningNonce" }, null)) return false
        val edit = prefs.edit().remove(when (kind) { "rest" -> "actionNonce"; "prepared" -> "preparedNonce"; else -> "runningNonce" })
        if (kind == "prepared") edit.putBoolean("preparedDismissed", true)
        edit.commit()
        context.getSystemService(NotificationManager::class.java).cancel(when (kind) { "rest" -> requestId; "prepared" -> preparedRequestId; else -> runningRequestId })
        return true
    }
    fun tapStartForTest(context: Context, prepared: Boolean): Boolean {
        val action = PendingIntent.getActivity(context, if (prepared) preparedStartRequestId else startRequestId,
            Intent(context, MainActivity::class.java).setAction(startAction),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE) ?: return false
        action.send()
        return true
    }
    fun tapCloseForTest(context: Context, prepared: Boolean): Boolean {
        val action = PendingIntent.getBroadcast(context, if (prepared) preparedCloseRequestId else closeRequestId,
            Intent(context, RestActionReceiver::class.java).setAction(closeAction),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE) ?: return false
        action.send()
        return true
    }
    fun tapStopForTest(context: Context): Boolean {
        val action = PendingIntent.getActivity(context, stopRequestId,
            Intent(context, MainActivity::class.java).setAction(stopAction),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE) ?: return false
        action.send()
        return true
    }
    fun notifyTest(context: Context): Boolean {
        if (!preferences(context).getBoolean("enabled", false) || !permitted(context)) return false
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channelId, "Descanso de entrenamiento", NotificationManager.IMPORTANCE_HIGH).apply {
                enableVibration(true)
                description = "Avisa cuando termina el descanso que configuraste."
            })
            if (manager.getNotificationChannel(channelId)?.importance == NotificationManager.IMPORTANCE_NONE) return false
        }
        val open = PendingIntent.getActivity(context, testRequestId, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId) else Notification.Builder(context)
        manager.notify(testRequestId, builder.setSmallIcon(R.drawable.ic_trackia)
            .setLargeIcon(brandIcon()).setColor(brandTeal)
            .setContentTitle("Prueba de notificaciones")
            .setContentText("TrackIA puede avisarte en este móvil.")
            .setContentIntent(open).setAutoCancel(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setDefaults(Notification.DEFAULT_ALL).build())
        return true
    }
}

class RestAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val preferences = RestNotifications.preferences(context)
        if (intent.getStringExtra("kind") == "test") {
            RestNotifications.notifyTimerTest(context)
            return
        }
        val id = intent.getStringExtra("id") ?: return
        val end = intent.getLongExtra("end", 0)
        if (intent.getStringExtra("kind") == "activity") {
            if (System.currentTimeMillis() >= end) {
                RestNotifications.notifyActivityFinished(context, intent.getStringExtra("name") ?: "Actividad", id, end)
            }
            return
        }
        if (!preferences.getBoolean("enabled", false) || preferences.getString("id", null) != id || preferences.getLong("end", 0) != end) return
        if (System.currentTimeMillis() < end) return
        preferences.edit().remove("id").remove("end").apply()
        if (RestNotifications.notify(context, intent.getStringExtra("name") ?: "Entrenamiento", id, end,
                preferences.getString("profileId", "local") ?: "local")) {
            preferences.edit().putString("lastDeliveredId", id).putLong("lastDeliveredEnd", end).apply()
        }
    }
}

class RestActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == RestNotifications.closeAction) {
            RestNotifications.closeNotice(context, intent.getStringExtra("nonce"), intent.getStringExtra("kind"))
        }
    }
}
