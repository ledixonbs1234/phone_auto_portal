package com.example.phone_auto_portal

import android.content.Intent
import android.content.pm.PackageManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.phone_auto_portal/volume"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchApp") {
                val appName = call.argument<String>("appName")
                if (appName != null) {
                    val success = launchAppStartingWith(appName)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "AppName is null", null)
                }
            } else {
                result.notImplemented()
            }
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
                MethodChannel(it, CHANNEL).invokeMethod("volumeKeyPressed", keyCode.toString())
            }
            return true // Chặn hành vi thay đổi âm lượng mặc định
        }
        return super.onKeyDown(keyCode, event)
    }
}
