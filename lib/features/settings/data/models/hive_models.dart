import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'hive_models.g.dart';

/// Recent file model - stores metadata for quick list display
/// Cloud-sync ready: includes sync status, timestamps, and unique ID
@HiveType(typeId: 0)
class HiveRecentFile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String filePath;

  @HiveField(2)
  final String fileName;

  @HiveField(3)
  final String fileType; // pdf, docx, xlsx, csv

  @HiveField(4)
  final int fileSizeBytes;

  @HiveField(5)
  final DateTime dateOpened;

  @HiveField(6)
  final DateTime dateModified;

  @HiveField(7)
  final int pagePosition; // Last opened page/position for resuming

  @HiveField(8)
  final DateTime? syncedAt; // When this was last synced to cloud

  @HiveField(9)
  final String syncStatus; // "pending", "synced", "conflict", "failed"

  @HiveField(10)
  final bool isDeleted; // Soft delete flag

  @HiveField(11)
  final DateTime? deletedAt; // When the file was soft deleted

  @HiveField(12)
  final bool isRead;

  @HiveField(13)
  final int totalTimeSpentMs; // Total time spent viewing in milliseconds

  @HiveField(14)
  final DateTime? sessionStartTime; // When current viewing session started

  HiveRecentFile({
    String? id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.dateOpened,
    required this.dateModified,
    this.pagePosition = 0,
    this.syncedAt,
    this.syncStatus = 'pending',
    bool? isDeleted,
    this.deletedAt,
    this.isRead = false,
    this.totalTimeSpentMs = 0,
    this.sessionStartTime,
  }) : id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false;

  /// Create copy with modifications (immutability pattern)
  HiveRecentFile copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    DateTime? dateOpened,
    DateTime? dateModified,
    int? pagePosition,
    DateTime? syncedAt,
    String? syncStatus,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? isRead,
    int? totalTimeSpentMs,
    DateTime? sessionStartTime,
  }) {
    return HiveRecentFile(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      dateOpened: dateOpened ?? this.dateOpened,
      dateModified: dateModified ?? this.dateModified,
      pagePosition: pagePosition ?? this.pagePosition,
      syncedAt: syncedAt ?? this.syncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isRead: isRead ?? this.isRead,
      totalTimeSpentMs: totalTimeSpentMs ?? this.totalTimeSpentMs,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    );
  }

  @override
  String toString() =>
      'HiveRecentFile(id: $id, fileName: $fileName, fileType: $fileType)';
}

/// App settings model - stores user preferences
/// Cloud-sync ready: user settings can sync across devices
@HiveType(typeId: 1)
class HiveAppSettings {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String theme; // "dark", "light", "system"

  @HiveField(2)
  final String language; // "en", "es", "fr", etc.

  @HiveField(3)
  final bool enableNotifications;

  @HiveField(8)
  final bool hasImportedSampleFiles;

  @HiveField(9)
  final bool? hasDismissedWelcome;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final String syncStatus; // "pending", "synced", "conflict"

  @HiveField(7)
  final DateTime? syncedAt;

  HiveAppSettings({
    String? id,
    this.theme = 'dark',
    this.language = 'en',
    this.enableNotifications = true,
    this.hasImportedSampleFiles = false,
    bool? hasDismissedWelcome,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
    this.syncedAt,
  })  : hasDismissedWelcome = hasDismissedWelcome ?? false,
        id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  HiveAppSettings copyWith({
    String? id,
    String? theme,
    String? language,
    bool? enableNotifications,
    bool? hasImportedSampleFiles,
    bool? hasDismissedWelcome,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    DateTime? syncedAt,
  }) {
    return HiveAppSettings(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      hasImportedSampleFiles: hasImportedSampleFiles ?? this.hasImportedSampleFiles,
      hasDismissedWelcome: hasDismissedWelcome ?? this.hasDismissedWelcome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  String toString() =>
      'HiveAppSettings(id: $id, theme: $theme, language: $language)';
}

/// Device info for cloud sync (Phase 2+)
/// Helps identify which device last modified data
@HiveType(typeId: 2)
class HiveDeviceInfo {
  @HiveField(0)
  final String? deviceId; // Unique device identifier

  @HiveField(1)
  final String? deviceName;

  @HiveField(2)
  final String? osVersion;

  @HiveField(3)
  final DateTime? lastSyncAt;

  HiveDeviceInfo({
    this.deviceId,
    this.deviceName,
    this.osVersion,
    this.lastSyncAt,
  });

  HiveDeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? osVersion,
    DateTime? lastSyncAt,
  }) {
    return HiveDeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      osVersion: osVersion ?? this.osVersion,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

/// Thumbnail cache model - stores generated thumbnail PNG bytes by file ID
/// Keyed by file ID for quick lookup when displaying document list
@HiveType(typeId: 3)
class HiveThumbnail {
  @HiveField(0)
  final String fileId; // References HiveRecentFile.id

  @HiveField(1)
  final List<int> pngBytes; // PNG image data

  @HiveField(2)
  final DateTime generatedAt;

  /// The brightness used when generating this thumbnail ('light' or 'dark')
  @HiveField(3)
  final String brightness;

  HiveThumbnail({
    required this.fileId,
    required this.pngBytes,
    required this.generatedAt,
    this.brightness = 'light',
  });

  HiveThumbnail copyWith({
    String? fileId,
    List<int>? pngBytes,
    DateTime? generatedAt,
    String? brightness,
  }) {
    return HiveThumbnail(
      fileId: fileId ?? this.fileId,
      pngBytes: pngBytes ?? this.pngBytes,
      generatedAt: generatedAt ?? this.generatedAt,
      brightness: brightness ?? this.brightness,
    );
  }
}
