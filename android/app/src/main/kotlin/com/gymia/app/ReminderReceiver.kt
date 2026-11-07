package com.gymia.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/**
 * Text of a habit reminder. Pure (no Android classes besides org.json) so it
 * can be tested on the JVM; it mirrors `renderReminder` in
 * `lib/domain/reminder.dart` and `contracts/reminders-android.md`.
 */
object ReminderText {
    const val WINDOW_START = "windowStart"
    const val LAST_CALL = "lastCall"
    private val marker = Regex("\\{(\\w+)\\}")

    /** Days since 1970-01-01 of a civil date (proleptic Gregorian). */
    fun epochDay(year: Int, month: Int, day: Int): Long {
        val y = if (month <= 2) year - 1 else year
        val era = Math.floorDiv(y, 400)
        val yoe = y - era * 400
        val doy = (153 * (month + (if (month > 2) -3 else 9)) + 2) / 5 + day - 1
        val doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era.toLong() * 146097 + doe - 719468
    }

    /** Civil year of an epoch day. */
    private fun yearOf(epochDay: Long): Int {
        val z = epochDay + 719468
        val era = Math.floorDiv(z, 146097L)
        val doe = z - era * 146097
        val yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        val doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        val mp = (5 * doy + 2) / 153
        val month = if (mp < 10) mp + 3 else mp - 9
        return (yoe + era * 400 + (if (month <= 2) 1 else 0)).toInt()
    }

    /** 0 = Monday … 6 = Sunday. */
    fun weekdayIndex(epochDay: Long): Int = Math.floorMod(epochDay + 3, 7L).toInt()

    /** ISO-8601 week of a date, like `2026-W44`. */
    fun isoWeekId(year: Int, month: Int, day: Int): String {
        val date = epochDay(year, month, day)
        val thursday = date + (3 - weekdayIndex(date))
        val thursdayYear = yearOf(thursday)
        val week = (thursday - epochDay(thursdayYear, 1, 1)) / 7 + 1
        return "%04d-W%02d".format(thursdayYear, week)
    }

    private fun parseDay(value: String?): Long? {
        if (value == null) return null
        val parts = value.split("-")
        if (parts.size != 3) return null
        return try { epochDay(parts[0].toInt(), parts[1].toInt(), parts[2].toInt()) } catch (e: NumberFormatException) { null }
    }

    private fun text(entry: JSONObject, key: String): String? =
        if (entry.isNull(key)) null else entry.getString(key).ifEmpty { null }

    private fun list(templates: JSONObject, key: String): List<String> {
        val array = templates.optJSONArray(key) ?: JSONArray()
        return (0 until array.length()).map { array.getString(it) }
    }

    /**
     * Picks and fills the text. [kind] is [WINDOW_START] or [LAST_CALL]; the start
     * of the window uses the `inactive` list when the last activity is older than
     * yesterday. The first template whose markers all have a value wins; if none
     * does, the last one is used.
     */
    fun render(entry: JSONObject, kind: String, year: Int, month: Int, day: Int): String {
        val today = epochDay(year, month, day)
        val last = parseDay(text(entry, "lastActivityDate"))
        val sinceLast = if (last == null) null else today - last
        val inactive = sinceLast != null && sinceLast >= 2
        val templates = entry.getJSONObject("templates")
        val chosen = when {
            kind == LAST_CALL -> list(templates, "lastCall")
            inactive -> list(templates, "inactive")
            else -> list(templates, "windowStart")
        }
        if (chosen.isEmpty()) return ""

        var missing: Int? = null
        if (!entry.isNull("weekTarget")) {
            val target = entry.getInt("weekTarget")
            val sameWeek = text(entry, "weekId") == isoWeekId(year, month, day)
            val gap = if (sameWeek) target - entry.optInt("weekCount", 0) else target
            if (gap > 0) missing = gap
        }
        val streak = entry.optInt("streak", 0)
        val values = mapOf(
            "dias" to (if (inactive) sinceLast.toString() else null),
            "faltan" to missing?.toString(),
            "racha" to (if (streak > 0) streak.toString() else null),
            "minimo" to text(entry, "minimumText"),
            "meta" to text(entry, "goalText"),
            "nombre" to text(entry, "companionName"),
        )
        val template = chosen.firstOrNull { t ->
            marker.findAll(t).all { !values[it.groupValues[1]].isNullOrEmpty() }
        } ?: chosen.last()
        return marker.replace(template) { values[it.groupValues[1]] ?: "" }
    }

    /**
     * The next moment strictly after [now] that falls on a marked day (bit 0 =
     * Monday … bit 6 = Sunday) at [minuteOfDay], or null when no day is marked.
     */
    fun nextTrigger(days: Int, minuteOfDay: Int, now: Long, zone: TimeZone): Long? {
        if (days and 0x7F == 0) return null
        val calendar = Calendar.getInstance(zone)
        for (offset in 0..7) {
            calendar.timeInMillis = now
            calendar.add(Calendar.DAY_OF_YEAR, offset)
            calendar.set(Calendar.HOUR_OF_DAY, minuteOfDay / 60)
            calendar.set(Calendar.MINUTE, minuteOfDay % 60)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val index = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7 // Calendar: Sunday = 1
            if (calendar.timeInMillis > now && days shr index and 1 == 1) return calendar.timeInMillis
        }
        return null
    }
}

/** Habit reminders of `contracts/reminders-android.md`: snapshot, alarms and notices. */
object Reminders {
    const val channelId = "trackia_reminders_v1"
    private const val preferencesName = "trackia_reminders"
    private const val snapshotPrefix = "snapshot:"
    private const val windowMillis = 10 * 60 * 1000L
    const val maxPostsPerDay = 2
    const val extraProfile = "profileId"
    const val extraCompanion = "companionId"

    private fun preferences(context: Context) = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    private fun snapshots(context: Context): Map<String, JSONObject> =
        preferences(context).all.filterKeys { it.startsWith(snapshotPrefix) }.mapNotNull { (key, value) ->
            try { key.removePrefix(snapshotPrefix) to JSONObject(value as String) } catch (e: Exception) { null }
        }.toMap()

    private fun entries(snapshot: JSONObject): List<JSONObject> {
        val array = snapshot.optJSONArray("reminders") ?: return emptyList()
        return (0 until array.length()).map { array.getJSONObject(it) }
    }

    private fun requestCode(id: String, kind: String): Int = (id + kind).hashCode() and 0x7fffffff
    private fun noticeId(id: String): Int = ("notice" + id).hashCode() and 0x7fffffff

    private fun pending(context: Context, profileId: String, id: String, kind: String): PendingIntent =
        PendingIntent.getBroadcast(context, requestCode(id, kind),
            Intent(context, ReminderReceiver::class.java)
                .putExtra(extraProfile, profileId).putExtra("id", id).putExtra("kind", kind),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun alarms(context: Context) = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun cancelAlarms(context: Context, profileId: String, snapshot: JSONObject) {
        for (entry in entries(snapshot)) for (kind in listOf(ReminderText.WINDOW_START, ReminderText.LAST_CALL)) {
            alarms(context).cancel(pending(context, profileId, entry.getString("id"), kind))
        }
    }

    /** Stores the snapshot of a profile and reschedules every alarm; false if it is not version 1. */
    fun sync(context: Context, raw: String): Boolean {
        val snapshot = try { JSONObject(raw) } catch (e: Exception) { return false }
        if (snapshot.optInt("version") != 1) return false
        val profileId = snapshot.optString("profileId")
        if (profileId.isEmpty()) return false
        snapshots(context)[profileId]?.let { cancelAlarms(context, profileId, it) }
        preferences(context).edit().putString(snapshotPrefix + profileId, snapshot.toString()).apply()
        scheduleAll(context)
        return true
    }

    fun clear(context: Context, profileId: String) {
        snapshots(context)[profileId]?.let { cancelAlarms(context, profileId, it) }
        preferences(context).edit().remove(snapshotPrefix + profileId).apply()
    }

    /** Programs the next start-of-window and last-call alarm of each active reminder. */
    fun scheduleAll(context: Context): Int {
        var scheduled = 0
        for ((profileId, snapshot) in snapshots(context)) for (entry in entries(snapshot)) {
            if (entry.optBoolean("paused")) continue
            val id = entry.getString("id")
            val days = entry.getInt("days")
            if (scheduleNext(context, profileId, id, ReminderText.WINDOW_START, days, entry.getInt("windowStartMin"))) scheduled++
            if (!entry.isNull("lastCallMin") &&
                scheduleNext(context, profileId, id, ReminderText.LAST_CALL, days, entry.getInt("lastCallMin"))) scheduled++
        }
        return scheduled
    }

    private fun scheduleNext(context: Context, profileId: String, id: String, kind: String, days: Int, minute: Int): Boolean {
        val at = ReminderText.nextTrigger(days, minute, System.currentTimeMillis(), TimeZone.getDefault()) ?: return false
        // Inexact on purpose: no SCHEDULE_EXACT_ALARM is needed for a habit reminder.
        alarms(context).setWindow(AlarmManager.RTC_WAKEUP, at, windowMillis, pending(context, profileId, id, kind))
        return true
    }

    fun scheduledCount(context: Context): Int =
        snapshots(context).values.sumOf { s -> entries(s).count { !it.optBoolean("paused") } }

    /** Notices posted today per reminder id (the per-day counter), for diagnostics and tests. */
    fun postedToday(context: Context): Map<String, Int> {
        val calendar = Calendar.getInstance()
        val today = "%04d-%02d-%02d".format(calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH) + 1, calendar.get(Calendar.DAY_OF_MONTH))
        return preferences(context).all.mapNotNull { (key, value) ->
            val parts = key.split(":")
            if (parts.size == 3 && parts[0] == "postedCount" && parts[2] == today && value is Int) parts[1] to value else null
        }.toMap()
    }

    private fun ensureChannel(context: Context, manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < 26) return
        manager.createNotificationChannel(NotificationChannel(channelId, context.getString(R.string.channel_reminders_name), NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = context.getString(R.string.channel_reminders_description)
        })
    }

    /** Handles one fired alarm: posts the notice if due, then programs the next one. */
    fun fire(context: Context, profileId: String, id: String, kind: String) {
        val snapshot = snapshots(context)[profileId] ?: return
        val entry = entries(snapshot).firstOrNull { it.getString("id") == id } ?: return
        try { post(context, profileId, entry, kind) } finally {
            if (!entry.optBoolean("paused")) {
                val minute = if (kind == ReminderText.LAST_CALL) entry.optInt("lastCallMin", -1) else entry.getInt("windowStartMin")
                if (minute >= 0) scheduleNext(context, profileId, id, kind, entry.getInt("days"), minute)
            }
        }
    }

    private fun post(context: Context, profileId: String, entry: JSONObject, kind: String) {
        if (entry.optBoolean("paused")) return
        val calendar = Calendar.getInstance()
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        val today = "%04d-%02d-%02d".format(year, month, day)
        val weekday = ReminderText.weekdayIndex(ReminderText.epochDay(year, month, day))
        if (entry.getInt("days") shr weekday and 1 == 0) return
        if (!entry.isNull("lastDoneDate") && entry.getString("lastDoneDate") == today) return
        if (!RestNotifications.runtimePermissionGranted(context)) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 24 && !manager.areNotificationsEnabled()) return
        ensureChannel(context, manager)
        if (Build.VERSION.SDK_INT >= 26 && manager.getNotificationChannel(channelId)?.importance == NotificationManager.IMPORTANCE_NONE) return

        val id = entry.getString("id")
        val countKey = "postedCount:$id:$today"
        val preferences = preferences(context)
        val posted = preferences.getInt(countKey, 0)
        if (posted >= maxPostsPerDay) return
        val text = ReminderText.render(entry, kind, year, month, day)
        if (text.isEmpty()) return

        val open = PendingIntent.getActivity(context, noticeId(id),
            Intent(context, MainActivity::class.java)
                .putExtra(extraProfile, profileId)
                .putExtra(extraCompanion, entry.getString("companionId"))
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId) else Notification.Builder(context)
        manager.notify(noticeId(id), builder.setSmallIcon(R.drawable.ic_trackia)
            .setColor(android.graphics.Color.rgb(2, 125, 146))
            .setContentTitle(entry.getString("companionName"))
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setContentIntent(open).setAutoCancel(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .build())
        // Keep only today's counter of this reminder.
        val editor = preferences.edit()
        preferences.all.keys.filter { it.startsWith("postedCount:$id:") && it != countKey }.forEach { editor.remove(it) }
        editor.putInt(countKey, posted + 1).apply()
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val profileId = intent.getStringExtra(Reminders.extraProfile) ?: return
        val id = intent.getStringExtra("id") ?: return
        val kind = intent.getStringExtra("kind") ?: return
        val result = goAsync()
        try { Reminders.fire(context.applicationContext, profileId, id, kind) } finally { result.finish() }
    }
}
