package com.example.renovision_ai

import android.app.Activity
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

class CreationFileProvider : FileProvider()

/** Shares only purpose-made PNG copies, never app records or original files. */
class CreationExportBridge(private val activity: Activity) {
    private var busy = false

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "renovision/creations").setMethodCallHandler { call, result ->
            if (call.method != "saveGallery" && call.method != "shareImage") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (busy) {
                result.error("busy", "An image export is already running.", null)
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            val header = byteArrayOf(-119, 80, 78, 71, 13, 10, 26, 10)
            if (bytes == null || bytes.size < 8 || bytes.size > 100 * 1024 * 1024 ||
                !bytes.copyOfRange(0, 8).contentEquals(header)) {
                result.error("image", "A prepared PNG image is required.", null)
                return@setMethodCallHandler
            }
            if (call.method == "saveGallery" && Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                result.success("chooseFile")
                return@setMethodCallHandler
            }
            val name = (call.argument<String>("name") ?: "RenoImagineAI.png")
                .removeSuffix(".png").replace(Regex("[^a-zA-Z0-9_-]"), "-")
                .take(60).ifBlank { "RenoImagineAI" }
            busy = true
            Thread {
                try {
                    if (call.method == "saveGallery") {
                        saveGallery(bytes, name)
                        activity.runOnUiThread {
                            busy = false
                            result.success("gallery")
                        }
                    } else {
                        val uri = prepareShare(bytes, name)
                        activity.runOnUiThread {
                            try {
                                val send = Intent(Intent.ACTION_SEND).apply {
                                    type = "image/png"
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    clipData = ClipData.newRawUri("RenoImagineAI creation", uri)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                activity.startActivity(Intent.createChooser(send, "Share creation"))
                                // Android does not report whether the recipient actually sent it.
                                result.success("opened")
                            } catch (_: Exception) {
                                result.error("share", "The share sheet could not open.", null)
                            } finally { busy = false }
                        }
                    }
                } catch (_: Exception) {
                    activity.runOnUiThread {
                        busy = false
                        result.error("export", "The image could not be exported. Check free space and try again.", null)
                    }
                }
            }.start()
        }
    }

    private fun saveGallery(bytes: ByteArray, name: String) {
        check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
        val resolver = activity.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$name-${UUID.randomUUID().toString().take(8)}.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/RenoImagineAI")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("Could not allocate image")
        try {
            (resolver.openOutputStream(uri) ?: error("Could not open image")).use { it.write(bytes) }
            val published = ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }
            check(resolver.update(uri, published, null, null) > 0)
        } catch (error: Exception) {
            // Delete only this call's incomplete new row. Existing photos are untouched.
            try { resolver.delete(uri, null, null) } catch (_: Exception) { }
            throw error
        }
    }

    private fun prepareShare(bytes: ByteArray, name: String): Uri {
        val directory = File(activity.cacheDir, "shared_creations")
        check(directory.isDirectory || directory.mkdirs())
        val cutoff = System.currentTimeMillis() - 48L * 60 * 60 * 1000
        directory.listFiles()?.forEach { previous ->
            if (previous.isFile && previous.name.startsWith("creation-") &&
                previous.name.endsWith(".png") && previous.lastModified() < cutoff &&
                previous.canonicalFile.parentFile == directory.canonicalFile) {
                previous.delete()
            }
        }
        val file = File.createTempFile("creation-$name-", ".png", directory)
        try {
            file.outputStream().use { it.write(bytes) }
            return FileProvider.getUriForFile(activity, "${activity.packageName}.creations", file)
        } catch (error: Exception) {
            file.delete()
            throw error
        }
    }
}
