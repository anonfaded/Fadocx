package com.fadseclab.fadocx

import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.poi.ss.usermodel.CellType
import org.apache.poi.ss.usermodel.WorkbookFactory
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.apache.poi.hwpf.HWPFDocument
import org.apache.poi.hwpf.extractor.WordExtractor
import java.io.File
import java.io.FileInputStream
import java.io.IOException

/// Native document parser bridge for Flutter
/// Handles XLSX, XLS, CSV via native libraries
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fadseclab.fadocx/document_parser"
    private val FILE_CHANNEL = "com.fadseclab.fadocx/file_intent"
    private val TAG = "Fadocx.DocumentParser"
    private var pendingFileIntent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Document parser channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "parseDocument" -> {
                        val filePath = call.argument<String>("filePath")
                        val format = call.argument<String>("format")
                        handleParseDocument(filePath, format, result)
                    }
                    "isAvailable" -> result.success(true)
                    else -> result.notImplemented()
                }
            }

        // File intent channel
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

        handleFileIntent(intent)
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
                else -> throw IllegalArgumentException("Unsupported format: $format")
            }

            val duration = System.currentTimeMillis() - startTime
            Log.i(TAG, "Parse completed in ${duration}ms")
            result.success(parsedData)
        } catch (e: Exception) {
            Log.e(TAG, "Parse error", e)
            result.error("PARSE_ERROR", e.message, null)
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
            // Extract text content from the document
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
}

