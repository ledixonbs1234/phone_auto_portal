package com.example.phone_auto_portal

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.view.KeyEvent
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val VOLUME_CHANNEL = "com.example.phone_auto_portal/volume"
    private val TMS_CHANNEL = "com.example.phone_auto_portal/tms_automation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Channel cũ (Volume & LaunchApp)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchApp" -> {
                    val appName = call.argument<String>("appName")
                    if (appName != null) {
                        val success = launchAppStartingWith(appName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "AppName is null", null)
                    }
                }
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "startTmsAutomation" -> {
                    val code = call.argument<String>("code") ?: ""
                    val targetApp = call.argument<String>("targetApp") ?: "TMS"
                    val startStep = call.argument<String>("startStep") ?: "STEP_1_ACCEPT_ORDER"
                    val started = startTmsAutomation(code, targetApp, startStep)
                    result.success(started)
                }
                "stopTmsAutomation" -> {
                    TmsAccessibilityService.instance?.stopAutomation()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Kênh chuyên dụng TMS Automation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "startTmsAutomation" -> {
                    val code = call.argument<String>("code") ?: ""
                    val targetApp = call.argument<String>("targetApp") ?: "TMS"
                    val startStep = call.argument<String>("startStep") ?: "STEP_1_ACCEPT_ORDER"
                    val started = startTmsAutomation(code, targetApp, startStep)
                    result.success(started)
                }
                "stopTmsAutomation" -> {
                    TmsAccessibilityService.instance?.stopAutomation()
                    result.success(true)
                }
                "isAutomationRunning" -> {
                    result.success(TmsAccessibilityService.isRunning)
                }
                "launchApp" -> {
                    val appName = call.argument<String>("appName") ?: "TMS"
                    result.success(launchAppStartingWith(appName))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        if (TmsAccessibilityService.isServiceRunning()) {
            return true
        }
        val expectedServiceName = "${packageName}/${TmsAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedServiceName, ignoreCase = true) ||
                componentName.contains("TmsAccessibilityService", ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Toast.makeText(this, "Vui lòng tìm và BẬT 'TMS Automation Service'", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startTmsAutomation(code: String, targetApp: String, startStep: String = "STEP_1_ACCEPT_ORDER"): Boolean {
        val service = TmsAccessibilityService.instance
        if (service != null) {
            service.startAutomation(code, targetApp, startStep)
            return true
        } else {
            // Chưa bật accessibility service
            Toast.makeText(this, "Chưa bật quyền Trợ năng cho ứng dụng. Đang mở cài đặt...", Toast.LENGTH_LONG).show()
            openAccessibilitySettings()
            return false
        }
    }

    private fun launchAppStartingWith(prefix: String): Boolean {
        try {
            val pm = packageManager
            val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)

            // 1. Search for app label starting with prefix (case insensitive)
            for (app in apps) {
                val name = pm.getApplicationLabel(app).toString()
                if (name.startsWith(prefix, ignoreCase = true)) {
                    val intent = pm.getLaunchIntentForPackage(app.packageName)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        return true
                    }
                }
            }

            // 2. Search for package name starting with prefix (case insensitive)
            for (app in apps) {
                val packageName = app.packageName
                if (packageName.startsWith(prefix, ignoreCase = true)) {
                    val intent = pm.getLaunchIntentForPackage(packageName)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        return true
                    }
                }
            }

            // 3. Search for app label containing prefix (case insensitive)
            for (app in apps) {
                val name = pm.getApplicationLabel(app).toString()
                if (name.contains(prefix, ignoreCase = true)) {
                    val intent = pm.getLaunchIntentForPackage(app.packageName)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        return true
                    }
                }
            }

            return false
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, VOLUME_CHANNEL).invokeMethod("volumeKeyPressed", keyCode.toString())
            }
            return true // Chặn hành vi thay đổi âm lượng mặc định
        }
        return super.onKeyDown(keyCode, event)
    }
}
