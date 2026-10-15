package com.example.fitvisions

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fitvisions/downloads")
            .setMethodCallHandler { call, result ->
                if (call.method != "savePreview") { result.notImplemented(); return@setMethodCallHandler }
                val bytes = call.arguments as? ByteArray
                if (bytes == null || bytes.size > 20 * 1024 * 1024) {
                    result.error("invalid_image", "Invalid preview", null); return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    result.error("unsupported", "Downloads requires Android 10 or later", null); return@setMethodCallHandler
                }
                Thread {
                    var uri: android.net.Uri? = null
                    try {
                        val values = ContentValues().apply {
                            put(MediaStore.Downloads.DISPLAY_NAME, "FitVisions-${System.currentTimeMillis()}.png")
                            put(MediaStore.Downloads.MIME_TYPE, "image/png")
                            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/FitVisions")
                            put(MediaStore.Downloads.IS_PENDING, 1)
                        }
                        val savedUri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                            ?: throw IllegalStateException("Could not create download")
                        uri = savedUri
                        val output = contentResolver.openOutputStream(savedUri) ?: throw IllegalStateException("Could not open download")
                        output.use { it.write(bytes) }
                        contentResolver.update(savedUri, ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }, null, null)
                        runOnUiThread { result.success(savedUri.toString()) }
                    } catch (e: Exception) {
                        uri?.let { contentResolver.delete(it, null, null) }
                        runOnUiThread { result.error("save_failed", "Could not save preview", null) }
                    }
                }.start()
            }
    }
}
