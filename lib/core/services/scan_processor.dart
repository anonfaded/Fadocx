import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:fadocx/core/services/image_processing_service.dart';
import 'package:fadocx/core/services/tesseract_service.dart';
import 'package:fadocx/core/services/storage_service.dart';

final log = Logger();

/// Scan result containing processed image and extracted text
class ScanResult {
  final String imagePath;
  final String extractedText;
  final DateTime timestamp;
  final String? processedImagePath;
  final double ocrConfidence;
  final List<TextBlock> textBlocks;
  final int? ocrImageWidth;
  final int? ocrImageHeight;

  ScanResult({
    required this.imagePath,
    required this.extractedText,
    required this.timestamp,
    this.processedImagePath,
    this.ocrConfidence = 0.0,
    this.textBlocks = const [],
    this.ocrImageWidth,
    this.ocrImageHeight,
  });

  Map<String, dynamic> toMap() => {
        'imagePath': imagePath,
        'extractedText': extractedText,
        'timestamp': timestamp.toIso8601String(),
        'processedImagePath': processedImagePath,
        'ocrConfidence': ocrConfidence,
        'ocrImageWidth': ocrImageWidth,
        'ocrImageHeight': ocrImageHeight,
        'textBlocks': textBlocks.map((block) => block.toMap()).toList(),
      };
}

/// Orchestrates the complete document scanning workflow
class ScanProcessor {
  /// Process a captured image through the full pipeline.
  /// [tessdataPath] must be provided when called from a background isolate
  /// (pass the path returned by [TesseractService.ensureTessdataReady]).
  static Future<ScanResult?> processImage(
    String capturedImagePath, {
    String? tessdataPath,
  }) async {
    try {
      log.i('Starting pipeline for: $capturedImagePath');
      final startTime = DateTime.now();

      final imageFile = File(capturedImagePath);
      if (!imageFile.existsSync()) {
        log.e('Image not found: $capturedImagePath');
        return null;
      }

      // 1. Perspective correction (includes edge detection + deskew internally)
      log.i('Step 1: Perspective correction');
      final correctedPath = await ImageProcessingService.processImageFile(
        capturedImagePath,
      );

      final ocrInputPath = correctedPath ?? capturedImagePath;
      log.i('OCR input path: $ocrInputPath');

      // 2. OCR with real hOCR confidence
      log.i('Step 2: OCR extraction');
      final ocrResult = await TesseractService.extractFromImage(
        ocrInputPath,
        tessdataPath: tessdataPath,
      );

      final extractedText = ocrResult?.plainText ?? '';
      final confidence = ocrResult?.averageConfidence ?? 0.0;
      final textBlocks = ocrResult?.lines ?? const <TextBlock>[];

      log.i('OCR done: ${extractedText.length} chars, '
          'confidence: ${confidence.toStringAsFixed(2)}');
      log.i('Extracted text: "$extractedText"');

      final elapsed = DateTime.now().difference(startTime).inSeconds;
      log.i('Pipeline completed in ${elapsed}s');

      return ScanResult(
        imagePath: capturedImagePath,
        extractedText: extractedText,
        timestamp: DateTime.now(),
        processedImagePath: correctedPath,
        ocrConfidence: confidence,
        textBlocks: textBlocks,
        ocrImageWidth: ocrResult?.imageWidth,
        ocrImageHeight: ocrResult?.imageHeight,
      );
    } catch (e, st) {
      log.e('Error processing image', error: e, stackTrace: st);
      return null;
    }
  }

  /// Get scan storage directory path
  static Future<String> _getScanStoragePath() async {
    try {
      final scanDir = await StorageService.getCategoryDir(StorageService.scansFolder);
      return scanDir.path;
    } catch (e) {
      log.e('Error getting scan storage path: $e');
      rethrow;
    }
  }

  /// Save scan result metadata
  static Future<bool> saveScanMetadata(ScanResult result) async {
    try {
      final metadataFile =
          '${result.timestamp.millisecondsSinceEpoch}_metadata.json';
      final scanPath = await _getScanStoragePath();
      final metadataPath = '$scanPath/$metadataFile';

      final file = File(metadataPath);
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(result.toMap()));

      log.i('Scan metadata saved: $metadataPath');
      return true;
    } catch (e) {
      log.e('Error saving scan metadata: $e');
      return false;
    }
  }

  /// Get all saved scans
  static Future<List<ScanResult>> getAllScans() async {
    try {
      final scanPath = await _getScanStoragePath();
      final scanDir = Directory(scanPath);
      if (!scanDir.existsSync()) return [];

      final files = scanDir.listSync();
      final scans = <ScanResult>[];

      for (final file in files) {
        if (file.path.endsWith('_processed.png')) {
          final timestamp = _extractTimestampFromPath(file.path);
          scans.add(ScanResult(
            imagePath: file.path,
            extractedText:
                'Scan from ${DateTime.fromMillisecondsSinceEpoch(timestamp)}',
            timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
            processedImagePath: file.path,
          ));
        }
      }
      return scans;
    } catch (e) {
      log.e('Error retrieving scans: $e');
      return [];
    }
  }

  static int _extractTimestampFromPath(String path) {
    try {
      final fileName = path.split('/').last;
      final timestamp = fileName.split('_')[0];
      return int.parse(timestamp);
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }
}
