package com.fadseclab.fadocx

import android.app.Activity
import android.graphics.Bitmap
import android.net.Uri
import android.util.Log
import org.libreoffice.kit.Document
import org.libreoffice.kit.LibreOfficeKit
import org.libreoffice.kit.Office
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class LOKitWrapper private constructor() {

    companion object {
        private const val TAG = "LOKitWrapper"
        private const val TWIPS_PER_INCH = 1440.0

        @Volatile
        private var instance: LOKitWrapper? = null
        private val instanceLock = Any()

        fun getInstance(): LOKitWrapper {
            return instance ?: synchronized(instanceLock) {
                instance ?: LOKitWrapper().also { instance = it }
            }
        }
    }

    private var office: Office? = null
    private var document: Document? = null
    private val syncLock = Any()

    private fun writeSofficerc(dataDir: String, cacheDir: String) {
        val programDir = File(dataDir, "program")
        programDir.mkdirs()
        val userDir = File(cacheDir, "lo_user")
        userDir.mkdirs()

        File(programDir, "sofficerc").writeText("""[Bootstrap]
Logo=1
NativeProgress=1
URE_BOOTSTRAP=file:///assets/program/fundamentalrc
UserInstallation=file://$cacheDir/lo_user
""")
        Log.i(TAG, "Wrote sofficerc with UserInstallation=$userDir")
    }

    private fun setupRuntime(activity: Activity): Boolean {
        val dataDir = activity.applicationInfo.dataDir
        val cacheDir = activity.cacheDir.absolutePath
        val versionMarker = File(dataDir, ".lokit_version")
        val currentVersion = "v5"

        writeSofficerc(dataDir, cacheDir)
        if (versionMarker.exists() && versionMarker.readText() == currentVersion) {
            return true
        }

        Log.i(TAG, "Setting up LO runtime v$currentVersion ...")
        versionMarker.writeText(currentVersion)
        Log.i(TAG, "LO runtime setup complete")
        return true
    }

    fun init(activity: Activity): Boolean {
        synchronized(syncLock) {
            try {
                setupRuntime(activity)
                LibreOfficeKit.putenv("SAL_LOG=+WARN+INFO")
                LibreOfficeKit.putenv("SAL_LOK_OPTIONS=compact_fonts")
                LibreOfficeKit.init(activity)
                val handle = LibreOfficeKit.getLibreOfficeKitHandle()
                if (handle == null) {
                    Log.e(TAG, "getLibreOfficeKitHandle returned null")
                    return false
                }
                office = Office(handle)
                Log.i(TAG, "LibreOfficeKit initialized")
                return true
            } catch (e: Exception) {
                Log.e(TAG, "LibreOfficeKit init failed", e)
                return false
            }
        }
    }

    fun loadDocument(path: String): Map<String, Any>? {
        synchronized(syncLock) {
            closeDocumentInternal()
            val file = File(path)
            val encodedName = Uri.encode(file.name)
            val loadPath = File(file.parent, encodedName).path
            val doc = office?.documentLoad(loadPath)
            if (doc == null) {
                val error = office?.error ?: "unknown"
                Log.e(TAG, "Failed to load document: $error")
                return null
            }
            doc.initializeForRendering()
            document = doc
            val typeName = when (doc.documentType) {
                Document.DOCTYPE_TEXT -> "TEXT"
                Document.DOCTYPE_SPREADSHEET -> "SPREADSHEET"
                Document.DOCTYPE_PRESENTATION -> "PRESENTATION"
                Document.DOCTYPE_DRAWING -> "DRAWING"
                else -> "OTHER"
            }
            val info = mapOf(
                "width" to doc.documentWidth,
                "height" to doc.documentHeight,
                "type" to doc.documentType,
                "typeName" to typeName,
                "parts" to doc.parts
            )
            Log.i(TAG, "Document loaded: $info")
            return info
        }
    }

    fun renderPage(part: Int, widthPx: Int, heightPx: Int): ByteArray? {
        synchronized(syncLock) {
            val doc = document ?: return null
            doc.setPart(part)
            val widthTwips = doc.documentWidth.toInt()
            val heightTwips = doc.documentHeight.toInt()
            return renderPageInternal(doc, widthPx, heightPx, widthTwips, heightTwips)
        }
    }

    fun getDocumentInfo(): Map<String, Any>? {
        synchronized(syncLock) {
            val doc = document ?: return null
            return mapOf(
                "width" to doc.documentWidth,
                "height" to doc.documentHeight,
                "type" to doc.documentType,
                "parts" to doc.parts
            )
        }
    }

    fun renderPageFit(part: Int, maxWidth: Int, maxHeight: Int): ByteArray? {
        synchronized(syncLock) {
            val doc = document ?: return null
            doc.setPart(part)
            val widthTwips = doc.documentWidth.toDouble()
            val heightTwips = doc.documentHeight.toDouble()
            if (widthTwips <= 0 || heightTwips <= 0) return null
            val ratio = minOf(maxWidth / widthTwips, maxHeight / heightTwips)
            val w = (widthTwips * ratio).toInt().coerceAtLeast(1)
            val h = (heightTwips * ratio).toInt().coerceAtLeast(1)
            return renderPageInternal(doc, w, h, widthTwips.toInt(), heightTwips.toInt())
        }
    }

    fun renderPageHighQuality(part: Int, maxWidth: Int, maxHeight: Int, scale: Float = 2.0f): ByteArray? {
        synchronized(syncLock) {
            val doc = document ?: return null
            doc.setPart(part)
            val widthTwips = doc.documentWidth.toDouble()
            val heightTwips = doc.documentHeight.toDouble()
            if (widthTwips <= 0 || heightTwips <= 0) return null
            val ratio = minOf(maxWidth / widthTwips, maxHeight / heightTwips) * scale
            val w = (widthTwips * ratio).toInt().coerceAtLeast(1)
            val h = (heightTwips * ratio).toInt().coerceAtLeast(1)
            return renderPageInternal(doc, w, h, widthTwips.toInt(), heightTwips.toInt())
        }
    }

    private fun renderPageInternal(doc: Document, widthPx: Int, heightPx: Int, twipW: Int, twipH: Int): ByteArray? {
        val buffer = ByteBuffer.allocateDirect(widthPx * heightPx * 4) ?: return null
        try {
            doc.paintTile(buffer, widthPx, heightPx, 0, 0, twipW, twipH)
            val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
            buffer.rewind()
            bitmap.copyPixelsFromBuffer(buffer)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            bitmap.recycle()
            return stream.toByteArray()
        } catch (e: Exception) {
            Log.e(TAG, "Render failed", e)
            return null
        }
    }


    fun getPartPageRectangles(): String? {
        synchronized(syncLock) {
            val doc = document ?: return null
            return try { doc.partPageRectangles } catch (e: Exception) { null }
        }
    }

    fun getPageCount(): Int {
        synchronized(syncLock) {
            val doc = document ?: return 0
            val rects = try { doc.partPageRectangles } catch (e: Exception) { null } ?: return doc.parts
            if (doc.documentType == Document.DOCTYPE_TEXT) {
                return rects.trim().split("\s+".toRegex()).size / 4
            }
            return doc.parts
        }
    }

    fun renderTextPage(pageIndex: Int, maxWidth: Int, maxHeight: Int, scale: Float): ByteArray? {
        synchronized(syncLock) {
            val doc = document ?: return null
            if (doc.documentType != Document.DOCTYPE_TEXT) return null
            try {
                val rects = doc.partPageRectangles ?: return null
                val tokens = rects.trim().split("\s+".toRegex())
                if (tokens.size < (pageIndex + 1) * 4) return null
                val baseIdx = pageIndex * 4
                val pageX = tokens[baseIdx].toDouble().toInt()
                val pageY = tokens[baseIdx + 1].toDouble().toInt()
                val pageW = tokens[baseIdx + 2].toDouble().toInt()
                val pageH = tokens[baseIdx + 3].toDouble().toInt()
                if (pageW <= 0 || pageH <= 0) return null
                val ratio = minOf(maxWidth.toDouble() / pageW, maxHeight.toDouble() / pageH) * scale
                val renderW = (pageW * ratio).toInt().coerceAtLeast(1)
                val renderH = (pageH * ratio).toInt().coerceAtLeast(1)
                val buffer = ByteBuffer.allocateDirect(renderW * renderH * 4) ?: return null
                doc.paintTile(buffer, renderW, renderH, pageX, pageY, pageW, pageH)
                val bitmap = Bitmap.createBitmap(renderW, renderH, Bitmap.Config.ARGB_8888)
                buffer.rewind()
                bitmap.copyPixelsFromBuffer(buffer)
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
                bitmap.recycle()
                return stream.toByteArray()
            } catch (e: Exception) {
                Log.e(TAG, "renderTextPage failed for page $pageIndex", e)
                return null
            }
        }
    }

    fun extractText(): String? {
        synchronized(syncLock) {
            val doc = document ?: return null
            try {
                val tempFile = File.createTempFile("lokit_text_", ".txt")
                tempFile.deleteOnExit()
                doc.saveAs(tempFile.absolutePath, "text", "")
                val text = tempFile.readText()
                tempFile.delete()
                return text
            } catch (e: Exception) {
                Log.e(TAG, "extractText failed", e)
                return null
            }
        }
    }

    fun extractPartText(part: Int): String? {
        synchronized(syncLock) {
            val doc = document ?: return null
            try {
                doc.setPart(part)
                val tempFile = File.createTempFile("lokit_text_", ".txt")
                tempFile.deleteOnExit()
                doc.saveAs(tempFile.absolutePath, "text", "")
                val text = tempFile.readText()
                tempFile.delete()
                return text
            } catch (e: Exception) {
                Log.e(TAG, "extractPartText failed for part $part", e)
                return null
            }
        }
    }

    fun closeDocument() {
        synchronized(syncLock) { closeDocumentInternal() }
    }

    private fun closeDocumentInternal() {
        document?.destroy()
        document = null
    }

    fun destroy() {
        synchronized(syncLock) {
            closeDocumentInternal()
            office?.destroy()
            office = null
        }
    }
}
