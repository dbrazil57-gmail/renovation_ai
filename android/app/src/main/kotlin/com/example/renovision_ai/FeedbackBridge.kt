package com.example.renovision_ai

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class FeedbackBridge(private val activity: Activity) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "renovision/feedback").setMethodCallHandler { call, result ->
            if (call.method != "open") { result.notImplemented(); return@setMethodCallHandler }
            val uri = call.argument<String>("url")?.let { Uri.parse(it) }
            if (uri == null || (uri.scheme != "mailto" && uri.scheme != "https")) {
                result.error("destination", "Unsupported feedback destination.", null)
                return@setMethodCallHandler
            }
            try {
                activity.startActivity(Intent(
                    if (uri.scheme == "mailto") Intent.ACTION_SENDTO else Intent.ACTION_VIEW,
                    uri
                ))
                result.success(true)
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }
}
