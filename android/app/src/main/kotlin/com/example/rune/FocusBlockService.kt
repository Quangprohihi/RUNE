package com.example.rune

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.ActivityOptions
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class FocusBlockService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val blockedPackages = mutableSetOf<String>()
    private var lastRelaunchAt = 0L
    private var lastRelaunchedPackage: String? = null

    private val pollRunnable = object : Runnable {
        override fun run() {
            enforceBlocklist()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            AppBlockState.stop(this)
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent?.action == ACTION_USER_LEFT) {
            scheduleUserLeftCheck()
            return START_REDELIVER_INTENT
        }

        blockedPackages.clear()
        blockedPackages.addAll(readBlockedPackages(intent))
        AppBlockState.start(this, blockedPackages)

        if (blockedPackages.isEmpty()) {
            stopSelf()
            return START_NOT_STICKY
        }

        startAsForegroundService()
        handler.removeCallbacks(pollRunnable)
        handler.post(pollRunnable)
        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        handler.removeCallbacks(pollRunnable)
        super.onDestroy()
    }

    private fun startAsForegroundService() {
        createNotificationChannel()
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("ZenZoo Focus Guard")
            .setContentText("ZenZoo is protecting your focus session.")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "ZenZoo Focus Guard",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Runs while ZenZoo blocks distracting apps during focus."
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun enforceBlocklist() {
        val foregroundPackage = getForegroundPackage() ?: return
        if (foregroundPackage == packageName || !blockedPackages.contains(foregroundPackage)) {
            return
        }
        relaunchZenZooBurst(foregroundPackage)
    }

    private fun scheduleUserLeftCheck() {
        if (blockedPackages.isEmpty()) return
        handler.postDelayed({
            val foregroundPackage = getForegroundPackage()
            if (foregroundPackage == packageName) return@postDelayed
            if (
                foregroundPackage == null ||
                blockedPackages.contains(foregroundPackage) ||
                AppBlockState.isHomePackage(this, foregroundPackage)
            ) {
                relaunchZenZooBurst(foregroundPackage ?: "unknown")
            }
        }, USER_LEFT_GRACE_MS)
    }

    private fun getForegroundPackage(): String? {
        return getForegroundPackageFromEvents() ?: getForegroundPackageFromStats()
    }

    private fun getForegroundPackageFromEvents(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(now - LOOKBACK_WINDOW_MS, now)
        val event = UsageEvents.Event()
        var latestPackage: String? = null
        var latestTimestamp = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val isForegroundEvent =
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                        event.eventType == UsageEvents.Event.ACTIVITY_RESUMED)
            if (isForegroundEvent && event.timeStamp >= latestTimestamp) {
                latestTimestamp = event.timeStamp
                latestPackage = event.packageName
            }
        }

        return latestPackage
    }

    private fun getForegroundPackageFromStats(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        return usageStatsManager
            .queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                now - LOOKBACK_WINDOW_MS,
                now
            )
            .filter { it.lastTimeUsed > 0L }
            .maxByOrNull { it.lastTimeUsed }
            ?.packageName
    }

    private fun relaunchZenZooBurst(blockedPackage: String) {
        val now = System.currentTimeMillis()
        if (
            blockedPackage == lastRelaunchedPackage &&
            now - lastRelaunchAt < RELAUNCH_THROTTLE_MS
        ) {
            return
        }

        lastRelaunchedPackage = blockedPackage
        lastRelaunchAt = now
        relaunchZenZoo(blockedPackage)
        handler.postDelayed({ relaunchIfStillBlocked(blockedPackage) }, 450L)
        handler.postDelayed({ relaunchIfStillBlocked(blockedPackage) }, 1100L)
    }

    private fun relaunchIfStillBlocked(blockedPackage: String) {
        if (getForegroundPackage() == blockedPackage) {
            relaunchZenZoo(blockedPackage)
        }
    }

    private fun relaunchZenZoo(blockedPackage: String) {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        launchIntent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        )
        launchIntent.putExtra(EXTRA_BLOCKED_PACKAGE, blockedPackage)

        val pendingIntent = PendingIntent.getActivity(
            this,
            blockedPackage.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            pendingIntentCreatorOptions()
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                pendingIntent.send(
                    this,
                    0,
                    launchIntent,
                    null,
                    null,
                    null,
                    pendingIntentSenderOptions()
                )
            } else {
                pendingIntent.send()
            }
        } catch (_: PendingIntent.CanceledException) {
            startActivity(launchIntent)
        }
    }

    private fun pendingIntentSenderOptions(): Bundle? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return null
        val options = ActivityOptions.makeBasic()
        options.setPendingIntentBackgroundActivityStartMode(backgroundActivityStartMode())
        return options.toBundle()
    }

    private fun pendingIntentCreatorOptions(): Bundle? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return null
        val options = ActivityOptions.makeBasic()
        setCreatorBackgroundActivityStartMode(options, backgroundActivityStartMode())
        return options.toBundle()
    }

    private fun setCreatorBackgroundActivityStartMode(options: ActivityOptions, mode: Int) {
        try {
            ActivityOptions::class.java
                .getMethod(
                    "setPendingIntentCreatorBackgroundActivityStartMode",
                    Int::class.javaPrimitiveType
                )
                .invoke(options, mode)
        } catch (_: Throwable) {
            // Android 14 only requires sender opt-in.
        }
    }

    fun backgroundActivityStartMode(): Int {
        return try {
            ActivityOptions::class.java
                .getField("MODE_BACKGROUND_ACTIVITY_START_ALLOW_ALWAYS")
                .getInt(null)
        } catch (_: Throwable) {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
    }

    private fun readBlockedPackages(intent: Intent?): List<String> {
        if (intent == null) return emptyList()
        return intent.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)
            ?: intent.getStringArrayExtra(EXTRA_BLOCKED_PACKAGES)?.toList()
            ?: intent.getStringExtra(EXTRA_BLOCKED_PACKAGES)
                ?.split(",")
                ?.map { it.trim() }
                ?.filter { it.isNotEmpty() }
            ?: emptyList()
    }

    companion object {
        const val ACTION_START = "com.example.rune.action.START_FOCUS_BLOCKING"
        const val ACTION_STOP = "com.example.rune.action.STOP_FOCUS_BLOCKING"
        const val ACTION_USER_LEFT = "com.example.rune.action.USER_LEFT_FOCUS_APP"
        const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"

        private const val CHANNEL_ID = "zenzoo_focus_guard"
        private const val NOTIFICATION_ID = 2108
        private const val POLL_INTERVAL_MS = 500L
        private const val LOOKBACK_WINDOW_MS = 10000L
        private const val RELAUNCH_THROTTLE_MS = 1500L
        private const val USER_LEFT_GRACE_MS = 1200L
    }
}
