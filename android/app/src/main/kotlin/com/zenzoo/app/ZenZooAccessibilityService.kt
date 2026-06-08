package com.zenzoo.app

import android.accessibilityservice.AccessibilityService
import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.view.accessibility.AccessibilityEvent

class ZenZooAccessibilityService : AccessibilityService() {
    private var lastRelaunchAt = 0L
    private var lastPackage: String? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || !isForegroundSignal(event.eventType)) return
        val foregroundPackage = event.packageName?.toString() ?: return
        if (foregroundPackage == packageName || !shouldBlock(foregroundPackage)) {
            return
        }
        relaunchZenZoo(foregroundPackage)
    }

    override fun onInterrupt() = Unit

    private fun isForegroundSignal(eventType: Int): Boolean {
        return eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED ||
            eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
    }

    private fun shouldBlock(foregroundPackage: String): Boolean {
        return AppBlockState.isBlocked(this, foregroundPackage) ||
            (AppBlockState.isActive(this) && AppBlockState.isHomePackage(this, foregroundPackage))
    }

    private fun relaunchZenZoo(blockedPackage: String) {
        val now = System.currentTimeMillis()
        if (blockedPackage == lastPackage && now - lastRelaunchAt < RELAUNCH_THROTTLE_MS) {
            return
        }
        lastPackage = blockedPackage
        lastRelaunchAt = now

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra(FocusBlockService.EXTRA_BLOCKED_PACKAGE, blockedPackage)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            blockedPackage.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val options = ActivityOptions.makeBasic()
                    .setPendingIntentBackgroundActivityStartMode(
                        backgroundActivityStartMode()
                    )
                    .toBundle()
                pendingIntent.send(this, 0, launchIntent, null, null, null, options)
            } else {
                pendingIntent.send()
            }
        } catch (_: PendingIntent.CanceledException) {
            startActivity(launchIntent)
        }
    }

    private fun backgroundActivityStartMode(): Int {
        return try {
            ActivityOptions::class.java
                .getField("MODE_BACKGROUND_ACTIVITY_START_ALLOW_ALWAYS")
                .getInt(null)
        } catch (_: Throwable) {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
    }

    companion object {
        private const val RELAUNCH_THROTTLE_MS = 1000L
    }
}

