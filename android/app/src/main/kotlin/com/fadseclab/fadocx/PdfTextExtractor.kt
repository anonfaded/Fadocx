package com.fadseclab.fadocx

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import com.tom_roush.pdfbox.text.TextPosition
import java.io.File

class PdfTextExtractor(private val TAG: String) {

    fun extractPdfPageText(filePath: String?, pageNumber: Int, result: MethodChannel.Result, activity: Activity) {
        try {
            if (filePath == null) {
                activity.runOnUiThread { result.error("INVALID_ARGS", "Missing filePath", null) }
                return
            }
            val file = File(filePath)
            if (!file.exists()) {
                activity.runOnUiThread { result.error("FILE_NOT_FOUND", "File not found: $filePath", null) }
                return
            }
            
            val document = PDDocument.load(file)
            val textStripper = PDFTextStripper()
            textStripper.startPage = pageNumber
            textStripper.endPage = pageNumber
            val text = textStripper.getText(document)
            document.close()
            
            activity.runOnUiThread {
                result.success(mapOf(
                    "pageNumber" to pageNumber,
                    "text" to text
                ))
            }
        } catch (e: Exception) {
            Log.e(TAG, "PDF page text extraction error", e)
            activity.runOnUiThread { result.error("PDF_ERROR", e.message, null) }
        }
    }
    
    fun extractTextWithPositions(filePath: String?, pageNumber: Int, result: MethodChannel.Result, activity: Activity) {
        try {
            if (filePath == null) {
                activity.runOnUiThread { result.error("INVALID_ARGS", "Missing filePath", null) }
                return
            }
            val file = File(filePath)
            if (!file.exists()) {
                activity.runOnUiThread { result.error("FILE_NOT_FOUND", "File not found: $filePath", null) }
                return
            }
            
            val document = PDDocument.load(file)
            
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
            
            activity.runOnUiThread {
                result.success(mapOf(
                    "pageNumber" to pageNumber,
                    "text" to text,
                    "characters" to stripper.characters
                ))
            }
        } catch (e: Exception) {
            Log.e(TAG, "PDF text position extraction error", e)
            activity.runOnUiThread { result.error("PDF_ERROR", e.message, null) }
        }
    }
}
