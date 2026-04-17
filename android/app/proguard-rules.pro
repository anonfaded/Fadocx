# ProGuard rules for Fadocx
# Optimizing for Apache POI and PDFBox

# Preserve NativeDocumentParser and PdfTextExtractor for reflection
-keep class com.fadseclab.fadocx.NativeDocumentParser { *; }
-keep class com.fadseclab.fadocx.PdfTextExtractor { *; }

# Apache POI - Surgical keep to reduce class load time
-keep class org.apache.poi.ss.usermodel.WorkbookFactory { *; }
-keep class org.apache.poi.ss.usermodel.CellType { *; }
-keep class org.apache.poi.hssf.usermodel.HSSFWorkbook { *; }
-keep class org.apache.poi.hwpf.** { *; }

# PDFBox
-keep class com.tom_roush.pdfbox.** { *; }

# Prevent warnings for unused transitive dependencies
-dontwarn org.apache.poi.**
-dontwarn org.apache.xmlbeans.**
-dontwarn com.tom_roush.pdfbox.**
-dontwarn org.apache.commons.logging.**

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
