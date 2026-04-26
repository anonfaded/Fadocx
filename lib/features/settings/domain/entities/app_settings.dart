import 'package:flutter/material.dart';

/// Business logic entity for recent file
/// Independent of data source (Hive, Cloud, etc.)
class RecentFile {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType; // pdf, docx, xlsx, csv, png, etc.
  final int fileSizeBytes;
  final DateTime dateOpened;
  final DateTime dateModified;
  final int pagePosition;
  final DateTime? syncedAt;
  final String syncStatus;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isRead;
  final int totalTimeSpentMs;
  final DateTime? sessionStartTime;
  final String? extractedText; // OCR text for scanned documents

  RecentFile({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.dateOpened,
    required this.dateModified,
    required this.pagePosition,
    this.syncedAt,
    required this.syncStatus,
    this.isDeleted = false,
    this.deletedAt,
    this.isRead = false,
    this.totalTimeSpentMs = 0,
    this.sessionStartTime,
    this.extractedText,
  });

  /// Format total time spent to human-readable string
  String get formattedTimeSpent {
    if (totalTimeSpentMs <= 0) return '0m';
    final seconds = totalTimeSpentMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    
    if (hours > 0) {
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  // Format file size to human-readable string
  String get formattedSize {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (fileSizeBytes >= gb) {
      return '${(fileSizeBytes / gb).toStringAsFixed(2)} GB';
    } else if (fileSizeBytes >= mb) {
      return '${(fileSizeBytes / mb).toStringAsFixed(2)} MB';
    } else if (fileSizeBytes >= kb) {
      return '${(fileSizeBytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '$fileSizeBytes B';
    }
  }

  /// Get icon name based on file type
  String get iconName {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'docx':
      case 'doc':
        return 'word';
      case 'xlsx':
      case 'xls':
        return 'excel';
      case 'csv':
        return 'csv';
      default:
        return 'file';
    }
  }

  @override
  String toString() =>
      'RecentFile(id: $id, fileName: $fileName, fileType: $fileType)';
}

/// Business logic entity for app settings
class AppSettings {
  final String id;
  final String theme; // dark, light, system
  final String language; // en, es, fr, etc.
  final bool enableNotifications;
  final bool hasImportedSampleFiles; // Track if user has imported sample files
  final bool hasDismissedWelcome; // Track if user has dismissed the welcome message
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? syncedAt;

  AppSettings({
    required this.id,
    required this.theme,
    required this.language,
    required this.enableNotifications,
    required this.hasImportedSampleFiles,
    required this.hasDismissedWelcome,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.syncedAt,
  });

  /// Get theme enum for MaterialApp
  ThemeMode get themeMode {
    switch (theme) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  String toString() =>
      'AppSettings(id: $id, theme: $theme, language: $language)';
}
