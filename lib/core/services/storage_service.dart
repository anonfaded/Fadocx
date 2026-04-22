import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

final log = Logger();

class StorageService {
  static const String pdfsFolder = 'PDFs';
  static const String documentsFolder = 'Documents';
  static const String spreadsheetsFolder = 'Spreadsheets';
  static const String presentationsFolder = 'Presentations';
  static const String imagesFolder = 'Images';
  static const String scansFolder = 'Scans';
  static const String trashFolder = 'Trash'; // Normal visible folder for deleted files

  /// Single source of truth: App's external scoped storage
  /// Path: /storage/emulated/0/Android/data/{package}/files/
  /// Uses getExternalStorageDirectories() from path_provider
  /// This maps to Context.getExternalFilesDirs() on Android
  static Future<Directory> _getStorageDir() async {
    // getExternalStorageDirectories() returns app-specific external storage
    // On Android API 19+: /storage/emulated/0/Android/data/{package}/files/
    // It returns a list where the first item is the primary external storage
    final externalDirs = await getExternalStorageDirectories();
    
    if (externalDirs == null || externalDirs.isEmpty) {
      throw Exception('External storage not available');
    }
    
    final storageDir = externalDirs.first;
    log.i('Using external scoped storage: ${storageDir.path}');
    return storageDir;
  }

  static Future<Directory> getCategoryDir(String category) async {
    final baseDir = await _getStorageDir();
    final categoryDir = Directory('${baseDir.path}/$category');
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
      log.i('Created category dir: ${categoryDir.path}');
    }
    return categoryDir;
  }

  /// Get trash folder - stores soft-deleted files
  static Future<Directory> _getTrashDir() async {
    final baseDir = await _getStorageDir();
    final trashDir = Directory('${baseDir.path}/$trashFolder');
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
      log.i('Created trash dir: ${trashDir.path}');
    }
    return trashDir;
  }

  /// Helper: Determine category from file extension
  static String _getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return pdfsFolder;
      case 'docx':
      case 'doc':
      case 'odt':
      case 'rtf':
      case 'txt':
        return documentsFolder;
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        return spreadsheetsFolder;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return presentationsFolder;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return imagesFolder;
      default:
        return documentsFolder;
    }
  }

  /// Copy file from source location to app's scoped storage
  /// Source: External file (Downloads, Drive, Camera, etc.)
  /// Destination: App's scoped storage (single source of truth)
  /// Returns the path to the copied file in app storage
  static Future<File> cacheDocument(String sourcePath, String fileName) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file not found: $sourcePath');
    }

    try {
      // Determine category from file extension
      final fileExtension = fileName.split('.').last;
      final category = _getCategoryFromExtension(fileExtension);
      
      // Get destination category folder
      final categoryDir = await getCategoryDir(category);
      final destPath = '${categoryDir.path}/$fileName';
      final destFile = File(destPath);

      // Copy file to app storage
      final copied = await sourceFile.copy(destFile.path);
      log.i('Copied file: $fileName to ${copied.path}');
      
      return copied;
    } catch (e) {
      log.e('Failed to copy file $fileName', error: e);
      rethrow;
    }
  }

  /// Move file to trash folder (soft delete)
  /// Encodes category in filename so we can restore to correct folder
  /// Example: PDFs/document.pdf -> Trash/[PDFs]_document.pdf
  static Future<File> moveToTrash(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        throw Exception('File not found: $filePath');
      }

      final trashDir = await _getTrashDir();
      final fileName = filePath.split('/').last;
      
      // Extract category from path: /.../*.../PDFs/document.pdf -> PDFs
      final pathParts = filePath.split('/');
      final categoryIndex = pathParts.length - 2;
      final category = categoryIndex >= 0 ? pathParts[categoryIndex] : documentsFolder;
      
      // Encode category in trash filename: [PDFs]_document.pdf
      final trashFileName = '[$category]_$fileName';
      final trashPath = '${trashDir.path}/$trashFileName';
      final trashFile = File(trashPath);

      // Move file to trash (rename operation)
      final moved = await sourceFile.rename(trashFile.path);
      log.i('Moved to trash: $filePath -> ${moved.path}');
      
      return moved;
    } catch (e) {
      log.e('Failed to move file to trash: $filePath', error: e);
      rethrow;
    }
  }

  /// Move file from trash back to original category
  /// Extracts category from trash filename: [PDFs]_document.pdf -> PDFs
  static Future<File> restoreFromTrash(String trashFilePath) async {
    try {
      final trashFile = File(trashFilePath);
      if (!await trashFile.exists()) {
        throw Exception('File not found in trash: $trashFilePath');
      }

      final trashFileName = trashFilePath.split('/').last;
      
      // Extract category: [PDFs]_document.pdf -> PDFs
      if (!trashFileName.startsWith('[') || !trashFileName.contains(']_')) {
        throw Exception('Invalid trash file format: $trashFileName');
      }
      
      final endBracket = trashFileName.indexOf(']');
      final category = trashFileName.substring(1, endBracket);
      final originalFileName = trashFileName.substring(endBracket + 2);
      
      // Get original category folder
      final categoryDir = await getCategoryDir(category);
      final originalPath = '${categoryDir.path}/$originalFileName';
      final restoredFile = File(originalPath);

      // Move file from trash to original category
      final moved = await trashFile.rename(restoredFile.path);
      log.i('Restored from trash: $trashFilePath -> ${moved.path}');
      
      return moved;
    } catch (e) {
      log.e('Failed to restore file from trash: $trashFilePath', error: e);
      rethrow;
    }
  }

  /// Permanently delete file from disk (hard delete)
  /// Removes the file completely from the trash folder
  static Future<void> permanentlyDeleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        log.i('Permanently deleted file: $filePath');
      }
    } catch (e) {
      log.e('Failed to permanently delete file: $filePath', error: e);
      rethrow;
    }
  }

  static Future<List<File>> getDocumentsInCategory(String category) async {
    try {
      final categoryDir = await getCategoryDir(category);
      final files = categoryDir.listSync().whereType<File>().toList();
      return files;
    } catch (e) {
      return [];
    }
  }

  static Future<int> getCacheSizeBytes() async {
    try {
      final storageDir = await _getStorageDir();
      int totalSize = 0;

      for (final entity in storageDir.listSync(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> clearAllCache() async {
    try {
      final storageDir = await _getStorageDir();
      if (await storageDir.exists()) {
        await storageDir.delete(recursive: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> clearCategoryCache(String category) async {
    try {
      final categoryDir = await getCategoryDir(category);
      if (await categoryDir.exists()) {
        await categoryDir.delete(recursive: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int index = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }

  /// Load storage sizes and counts for all categories.
  /// Returns: {category: {'bytes': X, 'count': Y}}
  static Future<Map<String, Map<String, int>>> getStorageStats() async {
    final Map<String, Map<String, int>> result = {};
    final categories = [
      pdfsFolder,
      spreadsheetsFolder,
      documentsFolder,
      presentationsFolder,
      imagesFolder,
      scansFolder,
      trashFolder,
    ];

    for (final cat in categories) {
      try {
        final files = await getDocumentsInCategory(cat);
        int bytes = 0;
        for (final f in files) {
          try {
            bytes += await f.length();
          } catch (_) {}
        }
        result[cat] = {'bytes': bytes, 'count': files.length};
      } catch (_) {
        result[cat] = {'bytes': 0, 'count': 0};
      }
    }

    return result;
  }
}
