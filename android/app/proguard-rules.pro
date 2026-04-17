# ProGuard rules for Fadocx
# Optimizing for Apache POI and PDFBox

# Preserve NativeDocumentParser and PdfTextExtractor for reflection
-keep class com.fadseclab.fadocx.NativeDocumentParser { *; }
-keep class com.fadseclab.fadocx.PdfTextExtractor { *; }

# Apache POI
-keep class org.apache.poi.** { *; }
-keep class org.apache.xmlbeans.** { *; }
-keep class com.microsoft.schemas.** { *; }
-dontwarn org.apache.poi.**
-dontwarn org.apache.xmlbeans.**

# PDFBox
-keep class com.tom_roush.pdfbox.** { *; }
-dontwarn com.tom_roush.pdfbox.**

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
