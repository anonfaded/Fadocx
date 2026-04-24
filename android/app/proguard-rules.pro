# ProGuard rules for Fadocx
# Optimizing for Apache POI and PDFBox

# Preserve NativeDocumentParser and PdfTextExtractor for reflection
-keep class com.fadseclab.fadocx.NativeDocumentParser { *; }
-keep class com.fadseclab.fadocx.PdfTextExtractor { *; }

# Apache POI - keep all (uses heavy reflection + XMLBeans codegen)
-keep class org.apache.poi.** { *; }
-keep class org.apache.xmlbeans.** { *; }
-keep class org.openxmlformats.** { *; }
-keep class schemaorg_apache_xmlbeans.** { *; }

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

-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# LibreOfficeKit
-keep class org.libreoffice.kit.** { *; }
-keep class com.fadseclab.fadocx.LOKitWrapper { *; }
-dontwarn org.libreoffice.**
