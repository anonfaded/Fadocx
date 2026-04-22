package com.fadseclab.fadocx

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.apache.poi.ss.usermodel.DataFormatter
import org.apache.poi.ss.usermodel.CellType
import org.apache.poi.ss.usermodel.WorkbookFactory
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import org.apache.poi.hwpf.HWPFDocument
import org.apache.poi.hwpf.extractor.WordExtractor
import java.io.File
import java.io.FileInputStream
import java.io.PrintWriter
import java.io.StringWriter

class NativeDocumentParser(private val TAG: String) {

    fun handleParseDocument(
        filePath: String?,
        format: String?,
        maxRows: Int?,
        maxCols: Int?,
        maxSheets: Int?,
        result: MethodChannel.Result,
        activity: Activity,
    ) {
        try {
            if (filePath == null || format == null) {
                activity.runOnUiThread { result.error("INVALID_ARGS", "Missing filePath or format", null) }
                return
            }

            Log.i(TAG, "Parsing document: $filePath (format: $format)")
            val startTime = System.currentTimeMillis()

            val parsedData = when (format.uppercase()) {
                "XLSX" -> parseXLSX(filePath, maxRows, maxCols, maxSheets)
                "XLS" -> parseXLS(filePath, maxRows, maxCols, maxSheets)
                "CSV" -> parseCSV(filePath, maxRows, maxCols)
                "DOC" -> parseDOC(filePath)
                "PDF" -> mapOf("format" to "PDF", "filePath" to filePath) // PDF page count handled in MainActivity for now
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
            activity.runOnUiThread { result.success(parsedData) }
        } catch (e: Exception) {
            Log.e(TAG, "Parse error", e)
            val sw = StringWriter()
            e.printStackTrace(PrintWriter(sw))
            activity.runOnUiThread { result.error("PARSE_ERROR", "${e.message}\n${sw.toString()}", null) }
        }
    }

    private fun parseXLSX(filePath: String, maxRows: Int?, maxCols: Int?, maxSheets: Int?): Map<String, Any> {
        val file = File(filePath)
        val workbook = WorkbookFactory.create(file)
        val sheets = mutableListOf<Map<String, Any>>()
        val formatter = DataFormatter()
        val evaluator = workbook.creationHelper.createFormulaEvaluator()
        val rowLimit = maxRows ?: Int.MAX_VALUE
        val colLimit = maxCols ?: Int.MAX_VALUE
        val sheetLimit = minOf(workbook.numberOfSheets, maxSheets ?: workbook.numberOfSheets)

        try {
            for (sheetIndex in 0 until sheetLimit) {
                val sheet = workbook.getSheetAt(sheetIndex)
                val rows = mutableListOf<List<String>>()

                for (rowIndex in 0 until sheet.physicalNumberOfRows) {
                    if (rows.size >= rowLimit) break

                    val row = sheet.getRow(rowIndex) ?: continue
                    val cells = mutableListOf<String>()
                    val cellCount = minOf(row.lastCellNum.toInt().coerceAtLeast(0), colLimit)

                    for (cellIndex in 0 until cellCount) {
                        val cell = row.getCell(cellIndex)
                        val cellValue = if (cell == null) "" else formatter.formatCellValue(cell, evaluator)
                        cells.add(cellValue)
                    }
                    if (cells.isNotEmpty()) rows.add(cells)
                }

                sheets.add(mapOf(
                    "name" to (sheet.sheetName ?: "Sheet $sheetIndex"),
                    "rows" to rows,
                    "rowCount" to rows.size,
                    "colCount" to (rows.firstOrNull()?.size ?: 0)
                ))
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

    private fun parseXLS(filePath: String, maxRows: Int?, maxCols: Int?, maxSheets: Int?): Map<String, Any> {
        val file = File(filePath)
        val fileInputStream = FileInputStream(file)
        val workbook = HSSFWorkbook(fileInputStream)
        val sheets = mutableListOf<Map<String, Any>>()
        val formatter = DataFormatter()
        val evaluator = workbook.creationHelper.createFormulaEvaluator()
        val rowLimit = maxRows ?: Int.MAX_VALUE
        val colLimit = maxCols ?: Int.MAX_VALUE
        val sheetLimit = minOf(workbook.numberOfSheets, maxSheets ?: workbook.numberOfSheets)

        try {
            for (sheetIndex in 0 until sheetLimit) {
                val sheet = workbook.getSheetAt(sheetIndex)
                val rows = mutableListOf<List<String>>()

                for (rowIndex in 0 until sheet.physicalNumberOfRows) {
                    if (rows.size >= rowLimit) break

                    val row = sheet.getRow(rowIndex) ?: continue
                    val cells = mutableListOf<String>()
                    val cellCount = minOf(row.lastCellNum.toInt().coerceAtLeast(0), colLimit)

                    for (cellIndex in 0 until cellCount) {
                        val cell = row.getCell(cellIndex)
                        val cellValue = if (cell == null) "" else formatter.formatCellValue(cell, evaluator)
                        cells.add(cellValue)
                    }
                    if (cells.isNotEmpty()) rows.add(cells)
                }

                sheets.add(mapOf(
                    "name" to (sheet.sheetName ?: "Sheet $sheetIndex"),
                    "rows" to rows,
                    "rowCount" to rows.size,
                    "colCount" to (rows.firstOrNull()?.size ?: 0)
                ))
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

    private fun parseCSV(filePath: String, maxRows: Int?, maxCols: Int?): Map<String, Any> {
        val file = File(filePath)
        val content = file.readText()
        val lines = content.split("\n")
        val rows = mutableListOf<List<String>>()
        val rowLimit = maxRows ?: Int.MAX_VALUE
        val colLimit = maxCols ?: Int.MAX_VALUE

        for (line in lines) {
            if (rows.size >= rowLimit) break
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
                rows.add(cells.take(colLimit))
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
        val fileInputStream = FileInputStream(file)
        val document = HWPFDocument(fileInputStream)
        val extractor = WordExtractor(document)

        try {
            val text = extractor.text
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
