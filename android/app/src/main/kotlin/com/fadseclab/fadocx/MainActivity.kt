package com.fadseclab.fadocx

import android.content.Intent
import android.content.ActivityNotFoundException
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.ByteArrayOutputStream
import java.io.FileInputStream
import java.io.PrintWriter
import java.io.StringWriter

/// Native document parser bridge for Flutter
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        // Use the cached engine pre-warmed in FadocxApplication
        return FlutterEngineCache.getInstance().get("fadocx_engine")
    }

    private val CHANNEL = "com.fadseclab.fadocx/document_parser"
    private val FILE_CHANNEL = "com.fadseclab.fadocx/file_intent"
    private val PDF_CHANNEL = "com.fadseclab.fadocx/pdf"
    private val TAG = "Fadocx.DocumentParser"
    private var pendingFileIntent: String? = null
    
    // Cache for PDF renderers
    private val pdfRenderers = mutableMapOf<String, PdfRenderer>()
    private val pdfDescriptors = mutableMapOf<String, ParcelFileDescriptor>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupMethodChannels(flutterEngine)
        handleFileIntent(intent)
    }

    private fun setupMethodChannels(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                Thread {
                    try {
                        when (call.method) {
                            "parseDocument" -> {
                                val filePath = call.argument<String>("filePath")
                                val format = call.argument<String>("format")
                                
                                val parserClass = Class.forName("com.fadseclab.fadocx.NativeDocumentParser")
                                val parserInstance = parserClass.getConstructor(String::class.java).newInstance(TAG)
                                val method = parserClass.getDeclaredMethod("handleParseDocument", 
                                    String::class.java, String::class.java, MethodChannel.Result::class.java, android.app.Activity::class.java)
                                method.invoke(parserInstance, filePath, format, result, this@MainActivity)
                            }
                            "isAvailable" -> runOnUiThread { result.success(true) }
                            else -> runOnUiThread { result.notImplemented() }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Reflection load failed", e)
                        runOnUiThread { result.error("REFLECTION_ERROR", e.message, null) }
                    }
                }.start()
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getOpenFileIntent") {
                    result.success(pendingFileIntent?.let { mapOf("filePath" to it) })
                    pendingFileIntent = null
                } else {
                    result.notImplemented()
                }
            }
            
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "renderPage" -> renderPdfPage(call.argument("filePath"), call.argument("pageNumber") ?: 0, call.argument("width") ?: 800, result)
                    "openPdf" -> openPdf(call.argument("filePath"), result)
                    "closePdf" -> closePdf(call.argument("filePath"), result)
                    "getPageCount" -> getPdfPageCount(call.argument("filePath"), result)
                    "extractPageText" -> Thread { 
                        try {
                            val extractorClass = Class.forName("com.fadseclab.fadocx.PdfTextExtractor")
                            val extractorInstance = extractorClass.getConstructor(String::class.java).newInstance(TAG)
                            val method = extractorClass.getDeclaredMethod("extractPdfPageText", 
                                String::class.java, Int::class.java, MethodChannel.Result::class.java, android.app.Activity::class.java)
                            method.invoke(extractorInstance, call.argument<String>("filePath"), call.argument<Int>("pageNumber") ?: 1, result, this@MainActivity)
                        } catch (e: Exception) {
                            runOnUiThread { result.error("REFLECTION_ERROR", e.message, null) }
                        }
                    }.start()
                    "extractTextWithPositions" -> Thread { 
                        try {
                            val extractorClass = Class.forName("com.fadseclab.fadocx.PdfTextExtractor")
                            val extractorInstance = extractorClass.getConstructor(String::class.java).newInstance(TAG)
                            val method = extractorClass.getDeclaredMethod("extractTextWithPositions", 
                                String::class.java, Int::class.java, MethodChannel.Result::class.java, android.app.Activity::class.java)
                            method.invoke(extractorInstance, call.argument<String>("filePath"), call.argument<Int>("pageNumber") ?: 1, result, this@MainActivity)
                        } catch (e: Exception) {
                            runOnUiThread { result.error("REFLECTION_ERROR", e.message, null) }
                        }
                    }.start()
                    "getPageSize" -> getPageSize(call.argument("filePath"), call.argument("pageNumber") ?: 0, result)
                    else -> result.notImplemented()
                }
            }

        // Method channel for app settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.fadseclab.fadocx/app_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openManageAllFilesSettings" -> {
                        openManageAllFilesSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        pdfRenderers.values.forEach { it.close() }
        pdfDescriptors.values.forEach { it.close() }
        pdfRenderers.clear()
        pdfDescriptors.clear()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleFileIntent(intent)
    }

    private fun openManageAllFilesSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            openApplicationDetailsSettings()
            Log.i(TAG, "Opened app settings (Android < 11)")
            return
        }

        if (Environment.isExternalStorageManager()) {
            Log.i(TAG, "MANAGE_EXTERNAL_STORAGE already granted for $packageName")
            openApplicationDetailsSettings()
            return
        }

        val uri = Uri.fromParts("package", packageName, null)
        val appSpecificIntent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, uri)
        val genericAllFilesIntent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)

        try {
            startActivity(appSpecificIntent)
            Log.i(TAG, "Opened MANAGE_APP_ALL_FILES_ACCESS_PERMISSION for $packageName")
        } catch (e: ActivityNotFoundException) {
            Log.w(TAG, "App-specific all files settings unavailable, opening generic page", e)
            try {
                startActivity(genericAllFilesIntent)
                Log.i(TAG, "Opened MANAGE_ALL_FILES_ACCESS_PERMISSION page")
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to open all files access screens, using app details", e2)
                openApplicationDetailsSettings()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open app-specific all files settings, using fallback", e)
            try {
                startActivity(genericAllFilesIntent)
                Log.i(TAG, "Opened MANAGE_ALL_FILES_ACCESS_PERMISSION page")
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to open all files access screens, using app details", e2)
                openApplicationDetailsSettings()
            }
        }
    }

    private fun openApplicationDetailsSettings() {
        try {
            val appDetailsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(appDetailsIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open app details settings", e)
        }
    }

    private fun handleFileIntent(intent: Intent?) {
        if (intent == null) return
        Thread {
            try {
                if (intent.action == Intent.ACTION_VIEW) {
                    val uri = intent.data
                    if (uri != null) {
                        val filePath = getFilePathFromUri(uri)
                        if (filePath != null) {
                            Log.i(TAG, "File intent detected: $filePath")
                            pendingFileIntent = filePath
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling file intent", e)
            }
        }.start()
    }

    private fun getFilePathFromUri(uri: Uri): String? {
        return when {
            uri.scheme == "file" -> uri.path
            uri.scheme == "content" -> {
                try {
                    getRealPathFromContentUri(uri) ?: uri.toString()
                } catch (e: Exception) {
                    Log.w(TAG, "Could not convert content URI to file path", e)
                    null
                }
            }
            else -> {
                Log.w(TAG, "Unsupported URI scheme: ${uri.scheme}")
                null
            }
        }
    }

    private fun getRealPathFromContentUri(uri: Uri): String? {
        return try {
            val projection = arrayOf(android.provider.MediaStore.MediaColumns.DATA)
            val cursor = contentResolver.query(uri, projection, null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(android.provider.MediaStore.MediaColumns.DATA)
                val result = cursor.getString(columnIndex)
                cursor.close()
                result
            } else {
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error getting real path from content URI", e)
            null
        }
    }
    
    private fun openPdf(filePath: String?, result: MethodChannel.Result) {
        try {
            if (filePath == null) return result.error("INVALID_ARGS", "Missing filePath", null)
            pdfRenderers[filePath]?.close()
            pdfDescriptors[filePath]?.close()
            val file = File(filePath)
            if (!file.exists()) return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
            val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(descriptor)
            pdfDescriptors[filePath] = descriptor
            pdfRenderers[filePath] = renderer
            result.success(mapOf("pageCount" to renderer.pageCount, "filePath" to filePath))
        } catch (e: Exception) {
            Log.e(TAG, "Error opening PDF", e)
            result.error("PDF_ERROR", e.message, null)
        }
    }
    
    private fun closePdf(filePath: String?, result: MethodChannel.Result) {
        try {
            if (filePath == null) return result.error("INVALID_ARGS", "Missing filePath", null)
            pdfRenderers[filePath]?.close()
            pdfDescriptors[filePath]?.close()
            pdfRenderers.remove(filePath)
            pdfDescriptors.remove(filePath)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error closing PDF", e)
            result.error("PDF_ERROR", e.message, null)
        }
    }
    
    private fun renderPdfPage(filePath: String?, pageNumber: Int, width: Int, result: MethodChannel.Result) {
        try {
            if (filePath == null) return result.error("INVALID_ARGS", "Missing filePath", null)
            var renderer = pdfRenderers[filePath]
            if (renderer == null) {
                val file = File(filePath)
                if (!file.exists()) return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                renderer = PdfRenderer(descriptor)
                pdfDescriptors[filePath] = descriptor
                pdfRenderers[filePath] = renderer
            }
            if (pageNumber < 0 || pageNumber >= renderer.pageCount) return result.error("INVALID_PAGE", "Invalid page number: $pageNumber", null)
            val page = renderer.openPage(pageNumber)
            val dpiScale = 2.0f
            val renderWidth = (width * dpiScale).toInt()
            val scale = renderWidth.toFloat() / page.width
            val renderHeight = (page.height * scale).toInt()
            val bitmap = Bitmap.createBitmap(renderWidth, renderHeight, Bitmap.Config.ARGB_8888)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
            page.close()
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            val bytes = stream.toByteArray()
            bitmap.recycle()
            result.success(mapOf("bytes" to bytes, "width" to renderWidth, "height" to renderHeight, "pageNumber" to pageNumber))
        } catch (e: Exception) {
            Log.e(TAG, "Error rendering PDF page", e)
            result.error("PDF_RENDER_ERROR", e.message, null)
        }
    }
    
    private fun getPageSize(filePath: String?, pageNumber: Int, result: MethodChannel.Result) {
        try {
            if (filePath == null) return result.error("INVALID_ARGS", "Missing filePath", null)
            var renderer = pdfRenderers[filePath]
            if (renderer == null) {
                val file = File(filePath)
                if (!file.exists()) return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                renderer = PdfRenderer(descriptor)
                pdfDescriptors[filePath] = descriptor
                pdfRenderers[filePath] = renderer
            }
            if (pageNumber < 0 || pageNumber >= renderer.pageCount) return result.error("INVALID_PAGE", "Invalid page number: $pageNumber", null)
            val page = renderer.openPage(pageNumber)
            val width = page.width
            val height = page.height
            page.close()
            result.success(mapOf("width" to width, "height" to height))
        } catch (e: Exception) {
            Log.e(TAG, "Error getting page size", e)
            result.error("PDF_ERROR", e.message, null)
        }
    }
    
    private fun getPdfPageCount(filePath: String?, result: MethodChannel.Result) {
        try {
            if (filePath == null) return result.error("INVALID_ARGS", "Missing filePath", null)
            val file = File(filePath)
            if (!file.exists()) return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
            val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(descriptor)
            val count = renderer.pageCount
            renderer.close()
            descriptor.close()
            result.success(count)
        } catch (e: Exception) {
            Log.e(TAG, "PDF page count error", e)
            result.error("PDF_ERROR", e.message, null)
        }
    }
}
