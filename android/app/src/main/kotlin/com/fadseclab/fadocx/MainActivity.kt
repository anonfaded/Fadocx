package com.fadseclab.fadocx

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.util.Log
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.poi.ss.usermodel.CellType
import org.apache.poi.ss.usermodel.WorkbookFactory
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.apache.poi.hwpf.HWPFDocument
import org.apache.poi.hwpf.extractor.WordExtractor
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import com.tom_roush.pdfbox.text.TextPosition
import java.io.File
import java.io.FileInputStream
import java.io.StringWriter
import java.io.PrintWriter
import java.io.ByteArrayOutputStream

/// Native document parser bridge for Flutter
/// Handles XLSX, XLS, CSV, DOC, PDF rendering and text extraction
/// PPT/PPTX support: Coming Soon (requires LibreOffice integration)
class MainActivity : FlutterActivity() {
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
        
        // Initialize PDFBox in a background thread to avoid blocking UI
        Thread {
            try {
                PDFBoxResourceLoader.init(applicationContext)
                Log.i(TAG, "PDFBox initialized in background")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize PDFBox", e)
            }
        }.start()

        setupMethodChannels(flutterEngine)
        handleFileIntent(intent)
    }

    private fun setupMethodChannels(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                // Offload heavy parsing to background threads
                Thread {
                    try {
                        when (call.method) {
                            "parseDocument" -> {
                                val filePath = call.argument<String>("filePath")
                                val format = call.argument<String>("format")
                                handleParseDocument(filePath, format, result)
                            }
                            "isAvailable" -> runOnUiThread { result.success(true) }
                            else -> runOnUiThread { result.notImplemented() }
                        }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("THREAD_ERROR", e.message, null) }
                    }
                }.start()
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getOpenFileIntent" -> {
                        if (pendingFileIntent != null) {
                            result.success(mapOf("filePath" to pendingFileIntent))
                            pendingFileIntent = null
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
            
        // PDF platform channel for rendering and text extraction
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL)
            .setMethodCallHandler { call, result ->
                // Rendering is done on main thread for PdfRenderer (UI-safe)
                // but text extraction should be on background thread
                when (call.method) {
                    "renderPage" -> {
                        val filePath = call.argument<String>("filePath")
                        val pageNumber = call.argument<Int>("pageNumber") ?: 0
                        val width = call.argument<Int>("width") ?: 800
                        renderPdfPage(filePath, pageNumber, width, result)
                    }
                    "openPdf" -> {
                        val filePath = call.argument<String>("filePath")
                        openPdf(filePath, result)
                    }
                    "closePdf" -> {
                        val filePath = call.argument<String>("filePath")
                        closePdf(filePath, result)
                    }
                    "getPageCount" -> {
                        val filePath = call.argument<String>("filePath")
                        getPdfPageCount(filePath, result)
                    }
                    "extractPageText" -> {
                        val filePath = call.argument<String>("filePath")
                        val pageNumber = call.argument<Int>("pageNumber") ?: 1
                        Thread { extractPdfPageText(filePath, pageNumber, result) }.start()
                    }
                    "extractTextWithPositions" -> {
                        val filePath = call.argument<String>("filePath")
                        val pageNumber = call.argument<Int>("pageNumber") ?: 1
                        Thread { extractTextWithPositions(filePath, pageNumber, result) }.start()
                    }
                    "getPageSize" -> {
                        val filePath = call.argument<String>("filePath")
                        val pageNumber = call.argument<Int>("pageNumber") ?: 0
                        getPageSize(filePath, pageNumber, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Clean up PDF renderers
        pdfRenderers.values.forEach { it.close() }
        pdfDescriptors.values.forEach { it.close() }
        pdfRenderers.clear()
        pdfDescriptors.clear()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleFileIntent(intent)
    }

    private fun handleFileIntent(intent: Intent?) {
        if (intent == null) return
        try {
            when {
                intent.action == Intent.ACTION_VIEW -> {
                    val uri = intent.data
                    if (uri != null) {
                        val filePath = getFilePathFromUri(uri)
                        if (filePath != null) {
                            Log.i(TAG, "File intent detected: $filePath")
                            pendingFileIntent = filePath
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling file intent", e)
        }
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
    
    // ── PDF Rendering with Android Native PdfRenderer ───────────────────
    
    private fun openPdf(filePath: String?, result: MethodChannel.Result) {
        try {
            if (filePath == null) {
                return result.error("INVALID_ARGS", "Missing filePath", null)
            }
            
            // Close existing if any
            pdfRenderers[filePath]?.close()
            pdfDescriptors[filePath]?.close()
            
            val file = File(filePath)
            if (!file.exists()) {
                return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
            }
            
            val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(descriptor)
            
            pdfDescriptors[filePath] = descriptor
            pdfRenderers[filePath] = renderer
            
            result.success(mapOf(
                "pageCount" to renderer.pageCount,
                "filePath" to filePath
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error opening PDF", e)
            result.error("PDF_ERROR", e.message, null)
        }
    }
    
    private fun closePdf(filePath: String?, result: MethodChannel.Result) {
        try {
            if (filePath == null) {
                return result.error("INVALID_ARGS", "Missing filePath", null)
            }
            
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
            if (filePath == null) {
                return result.error("INVALID_ARGS", "Missing filePath", null)
            }
            
            var renderer = pdfRenderers[filePath]
            
            // Open if not already open
            if (renderer == null) {
                val file = File(filePath)
                if (!file.exists()) {
                    return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                }
                
                val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                renderer = PdfRenderer(descriptor)
                pdfDescriptors[filePath] = descriptor
                pdfRenderers[filePath] = renderer
            }
            
            if (pageNumber < 0 || pageNumber >= renderer.pageCount) {
                return result.error("INVALID_PAGE", "Invalid page number: $pageNumber", null)
            }
            
            val page = renderer.openPage(pageNumber)
            
            // Calculate height maintaining aspect ratio
            // Use higher quality by rendering at higher DPI (2x scale)
            val dpiScale = 2.0f
            val renderWidth = (width * dpiScale).toInt()
            val scale = renderWidth.toFloat() / page.width
            val renderHeight = (page.height * scale).toInt()
            
            val bitmap = Bitmap.createBitmap(renderWidth, renderHeight, Bitmap.Config.ARGB_8888)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
            page.close()
            
            // Convert to PNG bytes (100% quality)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            val bytes = stream.toByteArray()
            bitmap.recycle()
            
            result.success(mapOf(
                "bytes" to bytes,
                "width" to renderWidth,
                "height" to renderHeight,
                "pageNumber" to pageNumber
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error rendering PDF page", e)
            result.error("PDF_RENDER_ERROR", e.message, null)
        }
    }
    
    private fun getPageSize(filePath: String?, pageNumber: Int, result: MethodChannel.Result) {
        try {
            if (filePath == null) {
                return result.error("INVALID_ARGS", "Missing filePath", null)
            }
            
            var renderer = pdfRenderers[filePath]
            
            if (renderer == null) {
                val file = File(filePath)
                if (!file.exists()) {
                    return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                }
                
                val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                renderer = PdfRenderer(descriptor)
                pdfDescriptors[filePath] = descriptor
                pdfRenderers[filePath] = renderer
            }
            
            if (pageNumber < 0 || pageNumber >= renderer.pageCount) {
                return result.error("INVALID_PAGE", "Invalid page number: $pageNumber", null)
            }
            
            val page = renderer.openPage(pageNumber)
            val width = page.width
            val height = page.height
            page.close()
            
            result.success(mapOf(
                "width" to width,
                "height" to height
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error getting page size", e)
            result.error("PDF_ERROR", e.message, null)
        }
    }
    
    // ── PDF Text Extraction with PDFBox ────────────────────────────────
    
    private fun getPdfPageCount(filePath: String?, result: MethodChannel.Result) {
        try {
            if (filePath == null) {
                return result.error("INVALID_ARGS", "Missing filePath", null)
            }
            val file = File(filePath)
            if (!file.exists()) {
                return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
            }
            
            // Try Android PdfRenderer first (faster for just counting)
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
    
    private fun extractPdfPageText(filePath: String?, pageNumber: Int, result: MethodChannel.Result) {
        try {
            if (filePath == null) {
                return runOnUiThread { result.error("INVALID_ARGS", "Missing filePath", null) }
            }
            val file = File(filePath)
            if (!file.exists()) {
                return runOnUiThread { result.error("FILE_NOT_FOUND", "File not found: $filePath", null) }
            }
            
            val document = PDDocument.load(file)
            val textStripper = PDFTextStripper()
            textStripper.startPage = pageNumber
            textStripper.endPage = pageNumber
            val text = textStripper.getText(document)
            document.close()
            
            runOnUiThread {
                result.success(mapOf(
                    "pageNumber" to pageNumber,
                    "text" to text
                ))
            }
        } catch (e: Exception) {
            Log.e(TAG, "PDF page text extraction error", e)
            runOnUiThread { result.error("PDF_ERROR", e.message, null) }
        }
    }
    
    // Extract text with character positions for text selection overlay
    private fun extractTextWithPositions(filePath: String?, pageNumber: Int, result: MethodChannel.Result) {
        try {
            if (filePath == null) {
                return runOnUiThread { result.error("INVALID_ARGS", "Missing filePath", null) }
            }
            val file = File(filePath)
            if (!file.exists()) {
                return runOnUiThread { result.error("FILE_NOT_FOUND", "File not found: $filePath", null) }
            }
            
            val document = PDDocument.load(file)
            
            // Use custom stripper that captures positions
            val stripper = object : PDFTextStripper() {
                val characters = mutableListOf<Map<String, Any>>()
                
                override fun writeString(text: String, textPositions: List<TextPosition>) {
                    for (pos in textPositions) {
                        characters.add(mapOf(
                            "text" to pos.unicode,
                            "x" to pos.xDirAdj,
                            "y" to pos.yDirAdj,
                            "width" to pos.widthDirAdj,
                            "height" to pos.heightDir,
                            "fontSize" to pos.fontSize
                        ))
                    }
                    super.writeString(text, textPositions)
                }
            }
            
            stripper.startPage = pageNumber
            stripper.endPage = pageNumber
            val text = stripper.getText(document)
            document.close()
            
            runOnUiThread {
                result.success(mapOf(
                    "pageNumber" to pageNumber,
                    "text" to text,
                    "characters" to stripper.characters
                ))
            }
        } catch (e: Exception) {
            Log.e(TAG, "PDF text position extraction error", e)
            runOnUiThread { result.error("PDF_ERROR", e.message, null) }
        }
    }

    private fun handleParseDocument(filePath: String?, format: String?, result: MethodChannel.Result) {
        try {
            if (filePath == null) {
                return result.error("INVALID_ARGS", "Missing filePath", null)
            }
            if (format == null) {
                return result.error("INVALID_ARGS", "Missing format", null)
            }

            Log.i(TAG, "Parsing document: $filePath (format: $format)")
            val startTime = System.currentTimeMillis()

            val parsedData = when (format.uppercase()) {
                "XLSX" -> parseXLSX(filePath)
                "XLS" -> parseXLS(filePath)
                "CSV" -> parseCSV(filePath)
                "DOC" -> parseDOC(filePath)
                "PDF" -> parsePDF(filePath)
                "PPT", "PPTX", "ODP" -> {
                    mapOf(
                        "format" to format.uppercase(),
                        "filePath" to filePath,
                        "comingSoon" to true,
                        "message" to "${format.uppercase()} viewing coming in a future update"
                    )
                }
                else -> throw IllegalArgumentException("Unsupported format: $format")
            }

            val duration = System.currentTimeMillis() - startTime
            Log.i(TAG, "Parse completed in ${duration}ms")
            runOnUiThread { result.success(parsedData) }
        } catch (e: Exception) {
            Log.e(TAG, "Parse error", e)
            val sw = StringWriter()
            e.printStackTrace(PrintWriter(sw))
            runOnUiThread { result.error("PARSE_ERROR", "${e.message}\n${sw.toString()}", null) }
        }
    }

    private fun parseXLSX(filePath: String): Map<String, Any> {
        val file = File(filePath)
        if (!file.exists()) {
            throw IllegalArgumentException("File not found: $filePath")
        }

        val workbook = WorkbookFactory.create(file)
        val sheets = mutableListOf<Map<String, Any>>()

        try {
            for (sheetIndex in 0 until workbook.numberOfSheets) {
                val sheet = workbook.getSheetAt(sheetIndex)
                val rows = mutableListOf<List<String>>()

                for (rowIndex in 0 until sheet.physicalNumberOfRows) {
                    val row = sheet.getRow(rowIndex) ?: continue
                    val cells = mutableListOf<String>()

                    for (cellIndex in 0 until row.physicalNumberOfCells) {
                        val cell = row.getCell(cellIndex)
                        val cellValue = when (cell?.cellType) {
                            CellType.STRING -> cell.stringCellValue ?: ""
                            CellType.NUMERIC -> cell.numericCellValue.toString()
                            CellType.BOOLEAN -> cell.booleanCellValue.toString()
                            else -> ""
                        }
                        cells.add(cellValue)
                    }

                    if (cells.isNotEmpty()) {
                        rows.add(cells)
                    }
                }

                sheets.add(mapOf(
                    "name" to (sheet.sheetName ?: "Sheet $sheetIndex"),
                    "rows" to rows,
                    "rowCount" to rows.size,
                    "colCount" to (rows.firstOrNull()?.size ?: 0)
                ))

                Log.d(TAG, "Parsed XLSX sheet: ${sheet.sheetName} (${rows.size} rows)")
            }
        } finally {
            workbook.close()
        }

        return mapOf(
            "sheets" to sheets,
            "sheetCount" to sheets.size,
            "format" to "XLSX",
            "filePath" to filePath
        )
    }

    private fun parseXLS(filePath: String): Map<String, Any> {
        val file = File(filePath)
        if (!file.exists()) {
            throw IllegalArgumentException("File not found: $filePath")
        }

        val fileInputStream = FileInputStream(file)
        val workbook = HSSFWorkbook(fileInputStream)
        val sheets = mutableListOf<Map<String, Any>>()

        try {
            for (sheetIndex in 0 until workbook.numberOfSheets) {
                val sheet = workbook.getSheetAt(sheetIndex)
                val rows = mutableListOf<List<String>>()

                for (rowIndex in 0 until sheet.physicalNumberOfRows) {
                    val row = sheet.getRow(rowIndex) ?: continue
                    val cells = mutableListOf<String>()

                    for (cellIndex in 0 until row.physicalNumberOfCells) {
                        val cell = row.getCell(cellIndex)
                        val cellValue = when (cell?.cellType) {
                            CellType.STRING -> cell.stringCellValue ?: ""
                            CellType.NUMERIC -> cell.numericCellValue.toString()
                            CellType.BOOLEAN -> cell.booleanCellValue.toString()
                            else -> ""
                        }
                        cells.add(cellValue)
                    }

                    if (cells.isNotEmpty()) {
                        rows.add(cells)
                    }
                }

                sheets.add(mapOf(
                    "name" to (sheet.sheetName ?: "Sheet $sheetIndex"),
                    "rows" to rows,
                    "rowCount" to rows.size,
                    "colCount" to (rows.firstOrNull()?.size ?: 0)
                ))

                Log.d(TAG, "Parsed XLS sheet: ${sheet.sheetName} (${rows.size} rows)")
            }
        } finally {
            workbook.close()
            fileInputStream.close()
        }

        return mapOf(
            "sheets" to sheets,
            "sheetCount" to sheets.size,
            "format" to "XLS",
            "filePath" to filePath
        )
    }

    private fun parseCSV(filePath: String): Map<String, Any> {
        val file = File(filePath)
        if (!file.exists()) {
            throw IllegalArgumentException("File not found: $filePath")
        }

        val content = file.readText()
        val lines = content.split("\n")
        val rows = mutableListOf<List<String>>()

        for (line in lines) {
            if (line.trim().isEmpty()) continue

            val cells = mutableListOf<String>()
            var currentCell = StringBuilder()
            var inQuotes = false

            for (char in line) {
                when {
                    char == '"' -> inQuotes = !inQuotes
                    char == ',' && !inQuotes -> {
                        cells.add(currentCell.toString().trim())
                        currentCell = StringBuilder()
                    }
                    else -> currentCell.append(char)
                }
            }

            if (currentCell.isNotEmpty()) {
                cells.add(currentCell.toString().trim())
            }

            if (cells.isNotEmpty()) {
                rows.add(cells)
            }
        }

        return mapOf(
            "sheets" to listOf(mapOf(
                "name" to "Sheet1",
                "rows" to rows,
                "rowCount" to rows.size,
                "colCount" to (rows.firstOrNull()?.size ?: 0)
            )),
            "sheetCount" to 1,
            "format" to "CSV",
            "filePath" to filePath
        )
    }

    private fun parseDOC(filePath: String): Map<String, Any> {
        val file = File(filePath)
        if (!file.exists()) {
            throw IllegalArgumentException("File not found: $filePath")
        }

        val fileInputStream = FileInputStream(file)
        val document = HWPFDocument(fileInputStream)
        val extractor = WordExtractor(document)

        try {
            val text = extractor.text
            Log.d(TAG, "Parsed DOC: ${text.length} characters extracted")

            return mapOf(
                "textContent" to text,
                "format" to "DOC",
                "filePath" to filePath
            )
        } finally {
            extractor.close()
            document.close()
            fileInputStream.close()
        }
    }
    
    private fun parsePDF(filePath: String): Map<String, Any> {
        val file = File(filePath)
        if (!file.exists()) {
            throw IllegalArgumentException("File not found: $filePath")
        }

        // Use Android PdfRenderer for page count (fast)
        val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        val renderer = PdfRenderer(descriptor)
        val pageCount = renderer.pageCount
        renderer.close()
        descriptor.close()

        Log.d(TAG, "Parsed PDF: $pageCount pages")

        return mapOf(
            "format" to "PDF",
            "filePath" to filePath,
            "pageCount" to pageCount
        )
    }
}
