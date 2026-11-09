package com.example.fitvisions

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.PointF
import android.media.FaceDetector
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fitvisions/avatar-face")
            .setMethodCallHandler { call, result ->
                if (call.method != "locate") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.arguments as? ByteArray
                if (bytes == null || bytes.size > 2 * 1024 * 1024) {
                    result.error("invalid_image", "Invalid face image", null)
                    return@setMethodCallHandler
                }
                Thread {
                    val landmarks = runCatching { findAvatarFace(bytes) }.getOrNull()
                    runOnUiThread { result.success(landmarks) }
                }.start()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fitvisions/password-reset")
            .setMethodCallHandler { call, result ->
                if (call.method != "openResetLink") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val link = call.arguments as? String
                val code = link?.takeIf { it.length <= 8192 }?.let { passwordResetCode(Uri.parse(it)) }
                if (code == null) {
                    result.error("invalid_link", "Invalid reset link", null)
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, passwordResetPage(code)))
                    result.success(null)
                } catch (_: ActivityNotFoundException) {
                    result.error("no_browser", "No browser available", null)
                }
            }
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

    private fun findAvatarFace(bytes: ByteArray): List<Double>? {
        val original = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        try {
            val width = original.width and 1.inv()
            if (width < 2 || original.height < 2) return null
            val bitmap = Bitmap.createBitmap(width, original.height, Bitmap.Config.RGB_565)
            try {
                android.graphics.Canvas(bitmap).drawBitmap(original, 0f, 0f, null)
                val faces = arrayOfNulls<FaceDetector.Face>(2)
                if (FaceDetector(width, bitmap.height, faces.size).findFaces(bitmap, faces) != 1) {
                    return null
                }
                val face = faces[0] ?: return null
                if (face.confidence() < FaceDetector.Face.CONFIDENCE_THRESHOLD) return null
                val eyes = PointF()
                face.getMidPoint(eyes)
                return listOf(eyes.x.toDouble(), eyes.y.toDouble(), face.eyesDistance().toDouble())
            } finally {
                bitmap.recycle()
            }
        } finally {
            original.recycle()
        }
    }
}
