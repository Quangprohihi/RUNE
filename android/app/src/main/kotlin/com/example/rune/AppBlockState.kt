package com.example.rune

import android.content.Context

object AppBlockState {
    private const val PREFS_NAME = "zenzoo_app_block"
    private const val KEY_ACTIVE = "active"
    private const val KEY_BLOCKED_PACKAGES = "blocked_packages"

    @Volatile
    var active: Boolean = false

    @Volatile
    var blockedPackages: Set<String> = emptySet()

    fun start(context: Context, packages: Collection<String>) {
        blockedPackages = packages.toSet()
        active = blockedPackages.isNotEmpty()
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ACTIVE, active)
            .putStringSet(KEY_BLOCKED_PACKAGES, blockedPackages)
            .apply()
    }

    fun stop(context: Context) {
        active = false
        blockedPackages = emptySet()
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ACTIVE, false)
            .remove(KEY_BLOCKED_PACKAGES)
            .apply()
    }

    fun isBlocked(context: Context, packageName: String?): Boolean {
        if (packageName == null) return false
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val persistedActive = prefs.getBoolean(KEY_ACTIVE, active)
        val persistedPackages =
            prefs.getStringSet(KEY_BLOCKED_PACKAGES, blockedPackages) ?: emptySet()
        active = persistedActive
        blockedPackages = persistedPackages
        return active && blockedPackages.contains(packageName)
    }

    fun isActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        active = prefs.getBoolean(KEY_ACTIVE, active)
        return active
    }

    fun isHomePackage(context: Context, packageName: String?): Boolean {
        if (packageName == null) return false
        val homeIntent = android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
            addCategory(android.content.Intent.CATEGORY_HOME)
        }
        val homePackage = context.packageManager
            .resolveActivity(homeIntent, 0)
            ?.activityInfo
            ?.packageName
        return packageName == homePackage || packageName.contains("launcher", ignoreCase = true)
    }
}
