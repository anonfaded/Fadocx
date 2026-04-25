import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/core/errors/failures.dart';

/// Abstract repository for app settings
/// Implementation can use Hive, Firebase, SQL, etc.
abstract class AppSettingsRepository {
  /// Get current app settings
  Future<Result<AppSettings>> getSettings();

  /// Update theme
  Future<Result<void>> updateTheme(String theme);

  /// Update language
  Future<Result<void>> updateLanguage(String language);

  /// Update notification setting
  Future<Result<void>> updateNotifications(bool enabled);

  /// Update has imported sample files setting
  Future<Result<void>> updateHasImportedSampleFiles(bool hasImported);

  /// Update has dismissed welcome setting
  Future<Result<void>> updateHasDismissedWelcome(bool hasDismissed);

  /// Get settings as stream for reactive updates
  Stream<Result<AppSettings>> watchSettings();

  /// Clear all settings (reset to default)
  Future<Result<void>> clearSettings();

  /// Sync settings with cloud (Phase 2+)
  Future<Result<void>> syncSettings();
}

/// Abstract repository for recent files
abstract class RecentFilesRepository {
  /// Get all recent files (sorted by date opened, desc)
  Future<Result<List<RecentFile>>> getRecentFiles();

  /// Add file to recent files
  Future<Result<void>> addRecentFile(RecentFile file);

  /// Update page position for resume functionality
  Future<Result<void>> updatePagePosition(String fileId, int pagePosition);

  /// Update date opened to now
  Future<Result<void>> updateDateOpened(String filePath);

  /// Remove file from recent files
  Future<Result<void>> removeRecentFile(String fileId);

  /// Clear all recent files
  Future<Result<void>> clearRecentFiles();

  /// Get deleted/trash files
  Future<Result<List<RecentFile>>> getTrashFiles();

  /// Soft delete a file (move to trash)
  Future<Result<void>> softDeleteFile(String fileId);

  /// Restore a file from trash
  Future<Result<void>> restoreFromTrash(String fileId);

  /// Permanently delete a file
  Future<Result<void>> permanentlyDeleteFile(String fileId);

  Future<Result<void>> markAsRead(String fileId);

  /// Start a viewing session (record start time)
  Future<Result<void>> startViewingSession(String filePath);

  /// End a viewing session (calculate and add duration)
  Future<Result<void>> endViewingSession(String filePath);

  /// Get recent files as stream for reactive updates
  Stream<Result<List<RecentFile>>> watchRecentFiles();

  /// Sync recent files with cloud (Phase 2+)
  Future<Result<void>> syncRecentFiles();

  /// Get sync status for a file
  Future<Result<String>> getSyncStatus(String fileId);
}

/// Abstract repository for document operations
abstract class DocumentRepository {
  /// Open/parse a document from file path
  Future<Result<Document>> openDocument(String filePath);

  /// Get document metadata without full parsing
  Future<Result<DocumentMetadata>> getDocumentMetadata(String filePath);

  /// Detect file type
  String detectFileType(String filePath);

  /// Check if file is supported
  bool isSupportedFileType(String filePath);

  /// Get supported file types
  List<String> getSupportedTypes();
}

/// Generic document entity
class Document {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType;
  final int totalPages;
  final Map<String, dynamic> content; // Format-specific content

  Document({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.totalPages,
    required this.content,
  });
}

/// Document metadata (lightweight info)
class DocumentMetadata {
  final String filePath;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final int? totalPages;
  final DateTime dateModified;
  final DateTime dateCreated;

  DocumentMetadata({
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    this.totalPages,
    required this.dateModified,
    required this.dateCreated,
  });
}
