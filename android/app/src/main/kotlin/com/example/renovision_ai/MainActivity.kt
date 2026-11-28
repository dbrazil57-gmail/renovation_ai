package com.example.renovision_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CreationExportBridge(this).register(flutterEngine.dartExecutor.binaryMessenger)
        FeedbackBridge(this).register(flutterEngine.dartExecutor.binaryMessenger)
        val vault = KeyVault(applicationContext)
        val geminiVault = KeyVault(applicationContext, "gemini")
        val testerVault = KeyVault(applicationContext, "tester")
        val accessVault = KeyVault(applicationContext, "access")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "renovision/secrets")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "readAppAccess" -> result.success(accessVault.read())
                        "writeAppAccess" -> {
                            accessVault.write(call.argument<String>("key") ?: error("Missing key"))
                            result.success(null)
                        }
                        "deleteAppAccess" -> { accessVault.delete(); result.success(null) }
                        "readOpenAiKey" -> result.success(vault.read())
                        "writeOpenAiKey" -> {
                            vault.write(call.argument<String>("key") ?: error("Missing key"))
                            result.success(null)
                        }
                        "deleteOpenAiKey" -> { vault.delete(); result.success(null) }
                        "readGeminiKey" -> result.success(geminiVault.read())
                        "writeGeminiKey" -> {
                            geminiVault.write(call.argument<String>("key") ?: error("Missing key"))
                            result.success(null)
                        }
                        "deleteGeminiKey" -> { geminiVault.delete(); result.success(null) }
                        "readTesterKey" -> result.success(testerVault.read())
                        "writeTesterKey" -> {
                            testerVault.write(call.argument<String>("key") ?: error("Missing invitation"))
                            result.success(null)
                        }
                        "deleteTesterKey" -> { testerVault.delete(); result.success(null) }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("secure_storage", "The device could not access the saved API key. Re-enter it or try removing it in Settings.", null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "renovision/files")
            .setMethodCallHandler { call, result ->
                if (call.method != "save" && call.method != "openBackup") {
                    result.notImplemented()
                } else if (pendingResult != null) {
                    result.error("busy", "A file chooser is already open.", null)
                } else {
                    val saving = call.method == "save"
                    val bytes = if (saving) call.argument<ByteArray>("bytes") else null
                    if (saving && bytes == null) {
                        result.error("invalid", "No file data supplied.", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(if (saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE)
                    intent.type = if (saving) call.argument<String>("mimeType") ?: "application/octet-stream" else "*/*"
                    if (saving) intent.putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "renovision.json")
                    pendingResult = result
                    pendingBytes = bytes
                    try { startActivityForResult(intent, if (saving) 4310 else 4311) }
                    catch (_: Exception) {
                        pendingResult = null
                        pendingBytes = null
                        result.error("chooser", "File chooser is unavailable.", null)
                    }
                }
            }
    }

    @Deprecated("Android compatibility callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 4310 && requestCode != 4311) return
        val result = pendingResult ?: return
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (requestCode == 4310) false else null)
            return
        }
        Thread {
            try {
                val response: Any = if (requestCode == 4310) {
                    val output = contentResolver.openOutputStream(uri) ?: error("No output stream")
                    output.use { it.write(bytes ?: error("Missing data")) }
                    true
                } else {
                    val input = contentResolver.openInputStream(uri) ?: error("No input stream")
                    input.use {
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        var count = it.read(buffer)
                        while (count != -1) {
                            if (output.size() + count > 100 * 1024 * 1024) error("Backup exceeds 100 MB")
                            output.write(buffer, 0, count)
                            count = it.read(buffer)
                        }
                        output.toByteArray()
                    }
                }
                runOnUiThread { result.success(response) }
            } catch (_: Exception) {
                runOnUiThread { result.error("file", "The file could not be read or saved. Check storage and permissions.", null) }
            }
        }.start()
    }
}
