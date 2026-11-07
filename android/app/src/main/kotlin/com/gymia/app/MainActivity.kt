package com.gymia.app

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.provider.DocumentsContract
import android.os.Build
import android.os.Bundle
import android.app.ActivityManager
import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var importChannel: MethodChannel? = null
    private var pendingImport: Intent? = null
    private var pickerResult: MethodChannel.Result? = null
    private val pickSheetRequest = 7401
    private lateinit var googleSheets: GoogleSheetsBridge
    private var notificationPermissionResult: MethodChannel.Result? = null
    private var restNotificationChannel: MethodChannel? = null
    private var remindersChannel: MethodChannel? = null
    /** Which companion's chat a tapped reminder asks for; handed to Flutter once. */
    private var pendingReminderOpen: Map<String, String>? = null

    private fun captureReminderOpen(intent: Intent?): Boolean {
        val profile = intent?.getStringExtra(Reminders.extraProfile)
        val companion = intent?.getStringExtra(Reminders.extraCompanion)
        if (profile.isNullOrEmpty() || companion.isNullOrEmpty()) return false
        pendingReminderOpen = mapOf("profileId" to profile, "companionId" to companion)
        return true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        RestNotifications.captureStartAction(this, intent)
        super.onCreate(savedInstanceState)
    }

    private fun readSheet(uri: Uri): Map<String, Any> {
        val mime = contentResolver.getType(uri)
        var virtual = mime == "application/vnd.google-apps.spreadsheet"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && DocumentsContract.isDocumentUri(this, uri)) {
            contentResolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_FLAGS), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    virtual = virtual || (cursor.getInt(0) and DocumentsContract.Document.FLAG_VIRTUAL_DOCUMENT != 0)
                }
            }
        }
        val output = ByteArrayOutputStream()
        fun read(input: java.io.InputStream) {
            input.use {
                val buffer = ByteArray(8192)
                var count: Int
                while (it.read(buffer).also { count = it } != -1) {
                    if (output.size() + count > 20 * 1024 * 1024) {
                        throw IllegalArgumentException(getString(R.string.err_sheet_over_20mb))
                    }
                    output.write(buffer, 0, count)
                }
            }
        }
        if (virtual) {
            val available = contentResolver.getStreamTypes(uri, "*/*")?.toList().orEmpty()
            // Prefer XLSX to retain every tab. Drive performs the conversion.
            val format = listOf(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "text/csv", "application/csv", "text/comma-separated-values"
            ).firstOrNull { it in available }
                ?: throw IllegalArgumentException(getString(R.string.err_native_sheet_use_import))
            val descriptor = contentResolver.openTypedAssetFileDescriptor(uri, format, null)
                ?: throw IllegalArgumentException(getString(R.string.err_drive_download))
            descriptor.use { read(it.createInputStream()) }
        } else {
            read(contentResolver.openInputStream(uri)
                ?: throw IllegalArgumentException(getString(R.string.err_open_selected_sheet)))
        }
        var name = "hoja"
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) name = cursor.getString(0) ?: name
        }
        return mapOf("name" to name, "bytes" to output.toByteArray())
    }

    private fun deliverSheet(uri: Uri, result: MethodChannel.Result) {
        // Cloud providers can download on demand; keep this off the UI thread.
        Thread {
            try {
                val sheet = readSheet(uri)
                runOnUiThread { result.success(sheet) }
            } catch (e: Exception) {
                runOnUiThread { result.error("IMPORT_FAILED", e.message ?: getString(R.string.err_read_sheet), null) }
            }
        }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.trackia/local-model")
            .setMethodCallHandler { call, result ->
                if (call.method != "memory") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
                val memory = ActivityManager.MemoryInfo()
                manager.getMemoryInfo(memory)
                result.success(mapOf(
                    "availableBytes" to memory.availMem,
                    "totalBytes" to memory.totalMem,
                    "thresholdBytes" to memory.threshold,
                    "lowMemory" to memory.lowMemory
                ))
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gymia.app/chatgpt")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "openBrowser" -> {
                            val uri = Uri.parse(call.argument<String>("url") ?: "")
                            val allowed = uri.scheme == "https" && uri.userInfo == null &&
                                ((uri.host == "auth.openai.com" && uri.path == "/api/accounts/authorize") ||
                                 (uri.host == "chatgpt.com" && uri.path == "/settings/usage"))
                            require(allowed)
                            // The browser owns authentication. Never use an embedded WebView.
                            startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
                            result.success(null)
                        }
                        "resumeApp" -> {
                            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    // Authorization URLs may contain an ID-token hint: never log them.
                    result.error("CHATGPT_BROWSER", getString(R.string.err_open_browser), null)
                }
            }
        restNotificationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gymia.app/rest-notifications")
        restNotificationChannel!!
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "status" -> result.success(mapOf("enabled" to RestNotifications.preferences(this).getBoolean("enabled", false), "granted" to RestNotifications.permitted(this), "exact" to RestNotifications.exact(this), "lastDeliveredId" to RestNotifications.preferences(this).getString("lastDeliveredId", null), "lastDeliveredEnd" to RestNotifications.preferences(this).getLong("lastDeliveredEnd", 0), "scheduledRestEnd" to RestNotifications.preferences(this).getLong("end", 0), "scheduledActivityEnd" to RestNotifications.preferences(this).getLong("activityEnd", 0), "alarmStyle" to RestNotifications.alarmStyle(this), "dnd" to RestNotifications.dnd(this), "dndFilter" to RestNotifications.dndFilter(this), "alarmChannelBlocked" to RestNotifications.alarmChannelBlocked(this)))
                        "enable" -> {
                            val enabled = call.argument<Boolean>("enabled") == true
                            if (enabled && !RestNotifications.runtimePermissionGranted(this)) {
                                if (notificationPermissionResult != null) { result.error("BUSY", getString(R.string.err_permission_request_busy), null) }
                                else {
                                    notificationPermissionResult = result
                                    requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 8402)
                                }
                            } else {
                                RestNotifications.preferences(this).edit().putBoolean("enabled", enabled).apply()
                                if (!enabled) RestNotifications.cancel(this)
                                result.success(enabled && RestNotifications.permitted(this))
                            }
                        }
                        "schedule" -> {
                            RestNotifications.schedule(this, call.argument<String>("id")!!, call.argument<Number>("end")!!.toLong(), call.argument<String>("name") ?: "Entrenamiento", call.argument<String>("profileId") ?: "local")
                            result.success(null)
                        }
                        "prepared" -> result.success(RestNotifications.notifyPrepared(this,
                            call.argument<String>("name") ?: "Actividad", call.argument<String>("id")!!,
                            call.argument<Number>("revision")!!.toLong(), call.argument<String>("profileId") ?: "local"))
                        "running" -> result.success(RestNotifications.notifyRunning(this,
                            call.argument<String>("name") ?: "Actividad", call.argument<String>("id")!!,
                            call.argument<Number>("revision")!!.toLong(), call.argument<String>("profileId") ?: "local",
                            call.argument<Number>("end")?.toLong() ?: 0L))
                        "cancel" -> { RestNotifications.cancel(this); result.success(null) }
                        "test" -> result.success(RestNotifications.notifyTest(this))
                        "setAlarmStyle" -> {
                            RestNotifications.preferences(this).edit().putBoolean("alarmStyle", call.argument<Boolean>("enabled") != false).apply()
                            result.success(true)
                        }
                        "testAlarm" -> result.success(RestNotifications.scheduleTestAlarm(this))
                        "openChannelSettings" -> {
                            val manager = getSystemService(android.app.NotificationManager::class.java)
                            val channel = when (call.argument<String>("channel")) {
                                "alarm" -> { RestNotifications.ensureAlarmChannel(this, manager); RestNotifications.alarmChannelId }
                                "reminders" -> "trackia_reminders_v1"
                                else -> "gymia_rest"
                            }
                            val exists = Build.VERSION.SDK_INT >= 26 && manager.getNotificationChannel(channel) != null
                            try {
                                startActivity(Intent(if (exists) android.provider.Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS else android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)
                                    .also { if (exists) it.putExtra(android.provider.Settings.EXTRA_CHANNEL_ID, channel) })
                            } catch (_: Exception) {
                                startActivity(Intent(android.provider.Settings.ACTION_SETTINGS))
                            }
                            result.success(null)
                        }
                        "openDndSettings" -> {
                            try { startActivity(Intent("android.settings.ZEN_MODE_SETTINGS")) }
                            catch (_: Exception) { startActivity(Intent(android.provider.Settings.ACTION_SETTINGS)) }
                            result.success(null)
                        }
                        "pendingAction" -> result.success(RestNotifications.pendingAction(this))
                        "completeAction" -> result.success(RestNotifications.completeAction(this,
                            call.argument<String>("id")!!, call.argument<Number>("end")!!.toLong(),
                            call.argument<String>("profileId")!!, call.argument<String>("kind")!!,
                            call.argument<Number>("revision")!!.toLong(), call.argument<Boolean>("success") == true))
                        "testTapStart" -> result.success((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) && RestNotifications.tapStartForTest(this, call.argument<Boolean>("prepared") == true))
                        "testTapClose" -> result.success((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) && RestNotifications.tapCloseForTest(this, call.argument<Boolean>("prepared") == true))
                        "testTapStop" -> result.success((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) && RestNotifications.tapStopForTest(this))
                        "exactSettings" -> {
                            if (Build.VERSION.SDK_INT >= 31) startActivity(Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) { result.error("REST_NOTIFICATION", getString(R.string.err_rest_notification), null) }
            }
        googleSheets = GoogleSheetsBridge(this)
        captureReminderOpen(intent)
        remindersChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gymia.app/reminders")
        remindersChannel!!
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "pendingOpen" -> {
                            val pending = pendingReminderOpen
                            pendingReminderOpen = null
                            result.success(pending)
                        }
                        "sync" -> result.success(Reminders.sync(this, call.argument<String>("snapshot") ?: ""))
                        "clear" -> {
                            Reminders.clear(this, call.argument<String>("profileId") ?: "")
                            result.success(true)
                        }
                        "status" -> result.success(mapOf("permitted" to RestNotifications.permitted(this), "scheduled" to Reminders.scheduledCount(this), "postedToday" to Reminders.postedToday(this)))
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("REMINDERS_FAILED", getString(R.string.err_reminders_schedule), null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gymia.app/google-sheets")
            .setMethodCallHandler { call, result -> googleSheets.handle(call, result) }
        if (intent?.action == Intent.ACTION_SEND) pendingImport = intent
        importChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gymia.app/import")
        importChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "pickSheet") {
                if (pickerResult != null) {
                    result.error("IMPORT_BUSY", getString(R.string.err_sheet_pick_busy), null)
                    return@setMethodCallHandler
                }
                pickerResult = result
                try {
                    // CATEGORY_OPENABLE excludes native Google Sheets (virtual documents).
                    startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        type = "*/*"
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }, pickSheetRequest)
                } catch (e: Exception) {
                    pickerResult = null
                    result.error("IMPORT_FAILED", getString(R.string.err_open_sheet_picker), null)
                }
                return@setMethodCallHandler
            }
            if (call.method != "takePendingImport") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val shared = pendingImport
            pendingImport = null
            if (shared == null) {
                result.success(null)
                return@setMethodCallHandler
            }
            try {
                val uri = shared.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    ?: shared.clipData?.getItemAt(0)?.uri
                    ?: throw IllegalArgumentException(getString(R.string.err_sheets_send_copy))
                deliverSheet(uri, result)
            } catch (e: Exception) {
                result.error("IMPORT_FAILED", e.message ?: getString(R.string.err_read_shared_sheet), null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::googleSheets.isInitialized && googleSheets.onActivityResult(requestCode, resultCode, data)) return
        if (requestCode != pickSheetRequest) return
        val result = pickerResult ?: return
        pickerResult = null
        if (resultCode != android.app.Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.error("IMPORT_FAILED", getString(R.string.err_sheet_not_received), null)
            return
        }
        deliverSheet(uri, result)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 8402) return
        val granted = RestNotifications.permitted(this)
        RestNotifications.preferences(this).edit().putBoolean("enabled", true).apply()
        notificationPermissionResult?.success(granted)
        notificationPermissionResult = null
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (captureReminderOpen(intent)) remindersChannel?.invokeMethod("openAvailable", null)
        if (RestNotifications.captureStartAction(this, intent)) {
            restNotificationChannel?.invokeMethod("actionAvailable", null)
        }
        if (intent.action == Intent.ACTION_SEND) {
            pendingImport = intent
            importChannel?.invokeMethod("importReady", null)
        }
    }
}
