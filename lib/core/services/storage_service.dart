import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String fadocxDocsFolder = 'fadocx_docs';
  static const String pdfsFolder = 'PDFs';
  static const String documentsFolder = 'Documents';
  static const String spreadsheetsFolder = 'Spreadsheets';
  static const String presentationsFolder = 'Presentations';
  static const String imagesFolder = 'Images';
  static const String scansFolder = 'Scans';

  static Future<Directory> _getStorageDir() async {
    try {
      final dirs = await getExternalStorageDirectories();
      if (dirs != null && dirs.isNotEmpty) {
        return dirs.first;
      }
    } catch (e) {
      // Fallback to app documents
    }

    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory> _getFadocxDir() async {
    final baseDir = await _getStorageDir();
    final fadocxDir = Directory('${baseDir.path}/$fadocxDocsFolder');
    if (!await fadocxDir.exists()) {
      await fadocxDir.create(recursive: true);
    }
    return fadocxDir;
  }

  static Future<Directory> _getCategoryDir(String category) async {
    final fadocxDir = await _getFadocxDir();
    final categoryDir = Directory('${fadocxDir.path}/$category');
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }
    return categoryDir;
  }

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

  static Future<File> cacheDocument(String sourcePath, String fileName) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Source file not found: $sourcePath');
    }

    final extension = fileName.split('.').last;
    final category = _getCategoryFromExtension(extension);
    final categoryDir = await _getCategoryDir(category);

    final cachedFile = File('${categoryDir.path}/$fileName');

    if (!await cachedFile.exists()) {
      await file.copy(cachedFile.path);
    }

    return cachedFile;
  }

  static Future<List<File>> getDocumentsInCategory(String category) async {
    try {
      final categoryDir = await _getCategoryDir(category);
      final files = categoryDir.listSync().whereType<File>().toList();
      return files;
    } catch (e) {
      return [];
    }
  }

  static Future<int> getCacheSizeBytes() async {
    try {
      final fadocxDir = await _getFadocxDir();
      int totalSize = 0;

      for (final entity in fadocxDir.listSync(recursive: true)) {
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
      final fadocxDir = await _getFadocxDir();
      if (await fadocxDir.exists()) {
        await fadocxDir.delete(recursive: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> clearCategoryCache(String category) async {
    try {
      final categoryDir = await _getCategoryDir(category);
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
}
