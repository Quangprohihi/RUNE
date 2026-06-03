package com.example.rune

import android.Manifest
import android.app.AppOpsManager
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
                    AppBlockState.start(this, packages)
                    startBlocking(packages)
                    result.success(null)
                }
                "stopBlocking" -> {
                    AppBlockState.stop(this)
                    stopService(Intent(this, FocusBlockService::class.java))
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

    private fun startBlocking(packages: List<String>) {
        val intent = Intent(this, FocusBlockService::class.java).apply {
            action = FocusBlockService.ACTION_START
            putStringArrayListExtra(FocusBlockService.EXTRA_BLOCKED_PACKAGES, ArrayList(packages))
        }
        ContextCompat.startForegroundService(this, intent)
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
        private const val NOTIFICATION_PERMISSION_REQUEST = 4207
    }
}
