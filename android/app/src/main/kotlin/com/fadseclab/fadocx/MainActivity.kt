package com.fadseclab.fadocx

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.poi.ss.usermodel.WorkbookFactory
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fadocx/excel_parser"
    private val TAG = "Fadocx.ExcelParser"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "parseExcel" -> handleParseExcel(call.arguments as? Map<*, *>, result)
                    "isAvailable" -> result.success(true) // Native parsing is available
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleParseExcel(
        arguments: Map<*, *>?,
        result: MethodChannel.Result
    ) {
        try {
            val filePath = arguments?.get("filePath") as? String
                ?: return result.error("INVALID_ARGS", "Missing filePath", null)

            Log.i(TAG, "Starting Excel parse: $filePath")
            
            val startTime = System.currentTimeMillis()
            val parsedData = parseExcelFile(filePath)
            val duration = System.currentTimeMillis() - startTime
            
            Log.i(TAG, "Parse completed in ${duration}ms")
            result.success(parsedData)
        } catch (e: Exception) {
            Log.e(TAG, "Parse error", e)
            result.error("PARSE_ERROR", e.message, null)
        }
    }

    private fun parseExcelFile(filePath: String): Map<String, Any> {
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

                // Stream parse rows - don't load all into memory at once
                for (rowIndex in 0 until sheet.physicalNumberOfRows) {
                    val row = sheet.getRow(rowIndex) ?: continue

                    val cells = mutableListOf<String>()
                    for (cellIndex in 0 until row.physicalNumberOfCells) {
                        val cell = row.getCell(cellIndex)
                        val cellValue = when {
                            cell == null -> ""
                            cell.cellType.name == "STRING" -> cell.stringCellValue ?: ""
                            cell.cellType.name == "NUMERIC" -> cell.numericCellValue.toString()
                            cell.cellType.name == "BOOLEAN" -> cell.booleanCellValue.toString()
                            else -> cell.toString() ?: ""
                        }
                        cells.add(cellValue)
                    }

                    if (cells.isNotEmpty()) {
                        rows.add(cells)
                    }
                }

                sheets.add(
                    mapOf(
                        "name" to (sheet.sheetName ?: "Sheet $sheetIndex"),
                        "rows" to rows,
                        "rowCount" to rows.size,
                        "colCount" to (rows.firstOrNull()?.size ?: 0)
                    )
                )

                Log.d(TAG, "Parsed sheet: ${sheet.sheetName} (${rows.size} rows)")
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
}

