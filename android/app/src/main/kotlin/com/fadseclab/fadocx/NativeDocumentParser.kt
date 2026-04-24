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
import org.apache.poi.xwpf.usermodel.BodyElementType
import org.apache.poi.xwpf.usermodel.IBodyElement
import org.apache.poi.xwpf.usermodel.UnderlinePatterns
import org.apache.poi.xwpf.usermodel.XWPFDocument
import org.apache.poi.xwpf.usermodel.XWPFHyperlinkRun
import org.apache.poi.xwpf.usermodel.XWPFParagraph
import org.apache.poi.xwpf.usermodel.XWPFRun
import org.apache.poi.xwpf.usermodel.XWPFTable
import org.apache.poi.xwpf.usermodel.XWPFTableCell
import org.apache.poi.xwpf.usermodel.XWPFTableRow
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
                "DOCX" -> parseDOCX(filePath)
                "DOC" -> parseDOC(filePath)
                "PDF" -> mapOf("format" to "PDF", "filePath" to filePath) // PDF page count handled in MainActivity for now
                "PPT", "PPTX", "ODP", "ODS" -> throw IllegalArgumentException("${format.uppercase()} is handled by LOKit renderer")
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

    private fun parseDOCX(filePath: String): Map<String, Any> {
        val file = File(filePath)
        val fileInputStream = FileInputStream(file)
        val document = XWPFDocument(fileInputStream)

        try {
            val blocks = mutableListOf<Map<String, Any>>()
            val warnings = linkedSetOf<String>()

            for (element in document.bodyElements) {
                when (element.elementType) {
                    BodyElementType.PARAGRAPH -> {
                        val paragraphBlock = parseDocxParagraph(element as XWPFParagraph, warnings)
                        if (paragraphBlock != null) {
                            blocks.add(paragraphBlock)
                        }
                    }
                    BodyElementType.TABLE -> {
                        blocks.add(parseDocxTable(element as XWPFTable, warnings))
                    }
                    else -> {
                        warnings.add("Unsupported DOCX body element skipped: ${element.elementType}")
                    }
                }
            }

            val plainText = blocks.joinToString("\n") { flattenBlockText(it) }.trim()
            val wordCount = plainText.split(Regex("\\s+")).count { it.isNotBlank() }
            val lineCount = plainText.split(Regex("\\r\\n|\\r|\\n")).count { it.isNotBlank() }

            return mapOf(
                "textContent" to plainText,
                "plainTextContent" to plainText,
                "documentBlocks" to blocks,
                "parseWarnings" to warnings.toList(),
                "fidelityLevel" to if (warnings.isEmpty()) "rich" else "partial",
                "wordCount" to wordCount,
                "lineCount" to lineCount.coerceAtLeast(1),
                "format" to "DOCX",
                "filePath" to filePath
            )
        } finally {
            document.close()
            fileInputStream.close()
        }
    }

    private fun parseDOC(filePath: String): Map<String, Any> {
        val file = File(filePath)
        val fileInputStream = FileInputStream(file)
        val document = HWPFDocument(fileInputStream)
        val extractor = WordExtractor(document)

        try {
            val text = extractor.text
            val paragraphs = extractor.paragraphText
                ?.mapNotNull { it?.replace("\u0007", "")?.trimEnd() }
                ?.filter { it.isNotBlank() }
                ?: emptyList()
            val documentBlocks = paragraphs.map { paragraphText ->
                mapOf(
                    "type" to "paragraph",
                    "inlines" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to paragraphText,
                            "style" to emptyMap<String, Any>()
                        )
                    )
                )
            }
            val wordCount = text.split(Regex("\\s+")).count { it.isNotBlank() }
            val lineCount = paragraphs.size.coerceAtLeast(1)
            return mapOf(
                "textContent" to text,
                "plainTextContent" to text,
                "documentBlocks" to documentBlocks,
                "parseWarnings" to listOf(
                    "Legacy DOC parsing preserves paragraph structure but not full Word styling parity yet."
                ),
                "fidelityLevel" to "partial",
                "wordCount" to wordCount,
                "lineCount" to lineCount,
                "format" to "DOC",
                "filePath" to filePath
            )
        } finally {
            extractor.close()
            document.close()
            fileInputStream.close()
        }
    }

    private fun parseDocxParagraph(
        paragraph: XWPFParagraph,
        warnings: MutableSet<String>
    ): Map<String, Any>? {
        val inlines = mutableListOf<Map<String, Any>>()

        for (run in paragraph.runs) {
            inlines.addAll(parseDocxRun(run, warnings))
        }

        if (inlines.isEmpty()) {
            val text = paragraph.text?.trimEnd().orEmpty()
            if (text.isBlank()) {
                return null
            }
            inlines.add(
                mapOf(
                    "type" to "text",
                    "text" to text,
                    "style" to emptyMap<String, Any>()
                )
            )
        }

        val paragraphBlock = mutableMapOf<String, Any>(
            "type" to "paragraph",
            "inlines" to inlines
        )

        paragraph.alignment?.let { paragraphBlock["alignment"] = it.name.lowercase() }
        if (paragraph.spacingBefore > 0) {
            paragraphBlock["spacingBefore"] = paragraph.spacingBefore.toDouble() / 20.0
        }
        if (paragraph.spacingAfter > 0) {
            paragraphBlock["spacingAfter"] = paragraph.spacingAfter.toDouble() / 20.0
        }
        if (paragraph.firstLineIndent > 0) {
            paragraphBlock["firstLineIndent"] = paragraph.firstLineIndent.toDouble() / 20.0
        }
        if (paragraph.indentationLeft > 0) {
            paragraphBlock["leftIndent"] = paragraph.indentationLeft.toDouble() / 20.0
        }
        if (paragraph.indentationRight > 0) {
            paragraphBlock["rightIndent"] = paragraph.indentationRight.toDouble() / 20.0
        }
        paragraph.numIlvl?.toInt()?.let { paragraphBlock["listLevel"] = it }
        paragraph.numID?.toString()?.let { paragraphBlock["listKind"] = "num:$it" }

        return paragraphBlock
    }

    private fun parseDocxRun(
        run: XWPFRun,
        warnings: MutableSet<String>
    ): List<Map<String, Any>> {
        val inlines = mutableListOf<Map<String, Any>>()
        val style = mutableMapOf<String, Any>()

        if (run.isBold) style["bold"] = true
        if (run.isItalic) style["italic"] = true
        if (run.isStrikeThrough) style["strike"] = true
        if (run.underline != UnderlinePatterns.NONE) style["underline"] = true
        run.fontFamily?.takeIf { it.isNotBlank() }?.let { style["fontFamily"] = it }
        if (run.fontSize > 0) style["fontSize"] = run.fontSize.toDouble()
        run.color?.takeIf { it.isNotBlank() }?.let { style["colorHex"] = it }
        run.textHightlightColor?.toString()?.takeIf { it.isNotBlank() }?.let { style["backgroundHex"] = it }

        val runText = buildString {
            var textIndex = 0
            while (true) {
                val value = run.getText(textIndex) ?: break
                append(value)
                textIndex++
            }
        }

        if (runText.isNotEmpty()) {
            val type = if (run is XWPFHyperlinkRun) "hyperlink" else "text"
            val inline = mutableMapOf<String, Any>(
                "type" to type,
                "text" to runText,
                "style" to style
            )
            if (run is XWPFHyperlinkRun) {
                val hyperlinkUrl = run
                    .getHyperlink(run.document)
                    ?.url
                    ?.takeIf { it.isNotBlank() }
                if (hyperlinkUrl != null) {
                    inline["href"] = hyperlinkUrl
                }
            }
            inlines.add(inline)
        }

        if (run.embeddedPictures.isNotEmpty()) {
            warnings.add("Embedded DOCX images are not fully rendered yet.")
            inlines.add(
                mapOf(
                    "type" to "text",
                    "text" to "[Image]",
                    "style" to style
                )
            )
        }

        if (runText.isEmpty() && run.embeddedPictures.isEmpty()) {
            val fallbackText = run.toString()
            if (fallbackText.isNotBlank()) {
                inlines.add(
                    mapOf(
                        "type" to "text",
                        "text" to fallbackText,
                        "style" to style
                    )
                )
            }
        }

        return inlines
    }

    private fun parseDocxTable(
        table: XWPFTable,
        warnings: MutableSet<String>
    ): Map<String, Any> {
        val rows = mutableListOf<Map<String, Any>>()
        for (row in table.rows) {
            rows.add(parseDocxTableRow(row, warnings))
        }
        return mapOf(
            "type" to "table",
            "rows" to rows
        )
    }

    private fun parseDocxTableRow(
        row: XWPFTableRow,
        warnings: MutableSet<String>
    ): Map<String, Any> {
        val cells = row.tableCells.map { parseDocxTableCell(it, warnings) }
        return mapOf("cells" to cells)
    }

    private fun parseDocxTableCell(
        cell: XWPFTableCell,
        warnings: MutableSet<String>
    ): Map<String, Any> {
        val blocks = mutableListOf<Map<String, Any>>()
        for (element in cell.bodyElements) {
            when (element.elementType) {
                BodyElementType.PARAGRAPH -> {
                    val paragraphBlock = parseDocxParagraph(element as XWPFParagraph, warnings)
                    if (paragraphBlock != null) {
                        blocks.add(paragraphBlock)
                    }
                }
                BodyElementType.TABLE -> {
                    warnings.add("Nested DOCX tables are rendered as nested table blocks.")
                    blocks.add(parseDocxTable(element as XWPFTable, warnings))
                }
                else -> {
                    warnings.add("Unsupported DOCX table cell element skipped: ${element.elementType}")
                }
            }
        }
        return mapOf("blocks" to blocks)
    }

    private fun flattenBlockText(block: Map<String, Any>): String {
        return when (block["type"]) {
            "paragraph" -> {
                @Suppress("UNCHECKED_CAST")
                val inlines = block["inlines"] as? List<Map<String, Any>> ?: emptyList()
                inlines.joinToString(separator = "") { inline ->
                    when (inline["type"] as? String) {
                        "tab" -> "\t"
                        "lineBreak" -> "\n"
                        else -> inline["text"] as? String ?: ""
                    }
                }
            }
            "table" -> {
                @Suppress("UNCHECKED_CAST")
                val rows = block["rows"] as? List<Map<String, Any>> ?: emptyList()
                rows.joinToString(separator = "\n") { row ->
                    @Suppress("UNCHECKED_CAST")
                    val cells = row["cells"] as? List<Map<String, Any>> ?: emptyList()
                    cells.joinToString(separator = "\t") { cell ->
                        @Suppress("UNCHECKED_CAST")
                        val blocks = cell["blocks"] as? List<Map<String, Any>> ?: emptyList()
                        blocks.joinToString(separator = "\n") { flattenBlockText(it) }
                    }
                }
            }
            else -> ""
        }
    }
}
