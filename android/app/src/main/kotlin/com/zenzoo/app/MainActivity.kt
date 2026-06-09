package com.zenzoo.app

import android.Manifest
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_BLOCK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageAccess" -> result.success(hasUsageAccess())
                "openUsageAccessSettings" -> {
                    openSettings(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    result.success(null)
                }
                "hasNotificationPermission" -> result.success(hasNotificationPermission())
                "requestNotificationPermission" -> requestNotificationPermission(result)
                "hasAccessibilityPermission" -> result.success(hasAccessibilityPermission())
                "openAccessibilitySettings" -> {
                    openSettings(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    result.success(null)
                }
                "startBlocking" -> {
                    val packages = call.argument<List<String>>("packages").orEmpty()
                    resetBlockCount()
                    AppBlockState.start(this, packages)
                    startBlocking(packages)
                    result.success(null)
                }
                "stopBlocking" -> {
                    AppBlockState.stop(this)
                    stopService(Intent(this, FocusBlockService::class.java))
                    result.success(null)
                }
                "getBlockCount" -> result.success(getBlockCount())
                "resetBlockCount" -> {
                    resetBlockCount()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FOCUS_SILENCE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationPolicyAccess" -> result.success(hasNotificationPolicyAccess())
                "openNotificationPolicySettings" -> {
                    openSettings(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    result.success(null)
                }
                "enableFocusSilence" -> result.success(enableFocusSilence())
                "disableFocusSilence" -> {
                    disableFocusSilence()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasNotificationPolicyAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return notificationManager.isNotificationPolicyAccessGranted
    }

    private fun hasAccessibilityPermission(): Boolean {
        val expectedService = "$packageName/${ZenZooAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        for (service in splitter) {
            if (service.equals(expectedService, ignoreCase = true)) return true
        }
        return false
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (hasNotificationPermission()) {
            result.success(true)
            return
        }
        if (notificationPermissionResult != null) {
            result.error("permission_request_active", "Notification permission request is already active.", null)
            return
        }
        notificationPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST
        )
    }

    private fun getBlockCount(): Int {
        return getSharedPreferences(
            FocusBlockService.BLOCK_STATS_PREFS,
            Context.MODE_PRIVATE
        ).getInt(FocusBlockService.KEY_BLOCK_COUNT, 0)
    }

    private fun resetBlockCount() {
        getSharedPreferences(FocusBlockService.BLOCK_STATS_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putInt(FocusBlockService.KEY_BLOCK_COUNT, 0)
            .apply()
    }

    private fun startBlocking(packages: List<String>) {
        val intent = Intent(this, FocusBlockService::class.java).apply {
            action = FocusBlockService.ACTION_START
            putStringArrayListExtra(FocusBlockService.EXTRA_BLOCKED_PACKAGES, ArrayList(packages))
        }
        ContextCompat.startForegroundService(this, intent)
    }

    private fun enableFocusSilence(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || !hasNotificationPolicyAccess()) {
            return false
        }
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val prefs = getSharedPreferences(FOCUS_SILENCE_PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SILENCE_ACTIVE, false)) {
            prefs.edit()
                .putBoolean(KEY_SILENCE_ACTIVE, true)
                .putInt(KEY_PREVIOUS_FILTER, notificationManager.currentInterruptionFilter)
                .apply()
        }
        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
        return true
    }

    private fun disableFocusSilence() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || !hasNotificationPolicyAccess()) {
            return
        }
        val prefs = getSharedPreferences(FOCUS_SILENCE_PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SILENCE_ACTIVE, false)) return
        val previousFilter = prefs.getInt(
            KEY_PREVIOUS_FILTER,
            NotificationManager.INTERRUPTION_FILTER_ALL
        )
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.setInterruptionFilter(previousFilter)
        prefs.edit()
            .putBoolean(KEY_SILENCE_ACTIVE, false)
            .remove(KEY_PREVIOUS_FILTER)
            .apply()
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        try {
            startService(Intent(this, FocusBlockService::class.java).apply {
                action = FocusBlockService.ACTION_USER_LEFT
            })
        } catch (_: Throwable) {
            // If focus blocking is not running, there is nothing to notify.
        }
    }

    private fun openSettings(action: String) {
        startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return
        notificationPermissionResult?.success(
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        )
        notificationPermissionResult = null
    }

    companion object {
        private const val APP_BLOCK_CHANNEL = "zenzoo/app_block"
        private const val FOCUS_SILENCE_CHANNEL = "zenzoo/focus_silence"
        private const val FOCUS_SILENCE_PREFS = "zenzoo_focus_silence"
        private const val KEY_SILENCE_ACTIVE = "silence_active"
        private const val KEY_PREVIOUS_FILTER = "previous_filter"
        private const val NOTIFICATION_PERMISSION_REQUEST = 4207
    }
}

