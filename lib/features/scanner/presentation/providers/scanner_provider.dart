import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:fadocx/core/services/camera_service.dart';
import 'package:fadocx/core/services/isolate_processor.dart';
import 'package:fadocx/core/services/storage_service.dart';
import 'package:fadocx/core/services/tesseract_service.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

final log = Logger();

/// Processing step enum — drives UI step-by-step animation.
enum ProcessingStep {
  idle,
  capturing,
  preparing,
  ocr,
  done,
}

/// Scanner state class - holds all scanner-related state
class ScannerState {
  final bool cameraInitialized;
  final String? cameraError;
  final bool isProcessing;
  final bool hasScannedImage;
  final String extractedText;
  final bool torchEnabled;
  final String? capturedImagePath;
  final String? displayedImagePath;
  final ProcessingStep processingStep;
  final double ocrConfidence;
  final List<TextBlock> textBlocks;
  final int? ocrImageWidth;
  final int? ocrImageHeight;

  const ScannerState({
    this.cameraInitialized = false,
    this.cameraError,
    this.isProcessing = false,
    this.hasScannedImage = false,
    this.extractedText = '',
    this.torchEnabled = false,
    this.capturedImagePath,
    this.displayedImagePath,
    this.processingStep = ProcessingStep.idle,
    this.ocrConfidence = 0.0,
    this.textBlocks = const [],
    this.ocrImageWidth,
    this.ocrImageHeight,
  });

  ScannerState copyWith({
    bool? cameraInitialized,
    String? cameraError,
    bool? isProcessing,
    bool? hasScannedImage,
    String? extractedText,
    bool? torchEnabled,
    String? capturedImagePath,
    String? displayedImagePath,
    ProcessingStep? processingStep,
    double? ocrConfidence,
    List<TextBlock>? textBlocks,
    int? ocrImageWidth,
    int? ocrImageHeight,
  }) {
    return ScannerState(
      cameraInitialized: cameraInitialized ?? this.cameraInitialized,
      cameraError: cameraError ?? this.cameraError,
      isProcessing: isProcessing ?? this.isProcessing,
      hasScannedImage: hasScannedImage ?? this.hasScannedImage,
      extractedText: extractedText ?? this.extractedText,
      torchEnabled: torchEnabled ?? this.torchEnabled,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      displayedImagePath: displayedImagePath ?? this.displayedImagePath,
      processingStep: processingStep ?? this.processingStep,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      textBlocks: textBlocks ?? this.textBlocks,
      ocrImageWidth: ocrImageWidth ?? this.ocrImageWidth,
      ocrImageHeight: ocrImageHeight ?? this.ocrImageHeight,
    );
  }

  /// Whether a given step is completed based on current processingStep.
  bool isStepCompleted(ProcessingStep step) {
    const order = [
      ProcessingStep.idle,
      ProcessingStep.capturing,
      ProcessingStep.preparing,
      ProcessingStep.ocr,
      ProcessingStep.done,
    ];
    final current = order.indexOf(processingStep);
    final target = order.indexOf(step);
    return current > target;
  }

  /// Whether a given step is currently active.
  bool isStepActive(ProcessingStep step) => processingStep == step;
}

/// Notifier to manage scanner state
class ScannerNotifier extends Notifier<ScannerState> {
  late CameraService _cameraService;

  @override
  ScannerState build() {
    _cameraService = CameraService();
    _initializeCameraAsync();
    return const ScannerState();
  }

  void _initializeCameraAsync() async {
    final success = await _cameraService.initialize();
    if (success) {
      state = state.copyWith(cameraInitialized: true);
    } else {
      state = state.copyWith(
        cameraInitialized: false,
        cameraError: _cameraService.initError,
      );
    }
  }

  CameraService getCameraService() => _cameraService;

  Future<void> retryCameraInitialization() async {
    state = state.copyWith(cameraError: null);
    await _cameraService.initialize();
    final success = _cameraService.isInitialized;
    if (success) {
      state = state.copyWith(cameraInitialized: true);
    } else {
      state = state.copyWith(
        cameraInitialized: false,
        cameraError: _cameraService.initError,
      );
    }
  }

  Future<void> toggleTorch() async {
    if (!state.cameraInitialized || _cameraService.controller == null) return;
    try {
      final newTorchState = !state.torchEnabled;
      await _cameraService.controller!.setFlashMode(
        newTorchState ? FlashMode.torch : FlashMode.off,
      );
      state = state.copyWith(torchEnabled: newTorchState);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disableTorch() async {
    if (state.torchEnabled && _cameraService.controller != null) {
      try {
        await _cameraService.controller!.setFlashMode(FlashMode.off);
        state = state.copyWith(torchEnabled: false);
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Save captured image to Scans folder with Fadocx_scanned_ prefix + human-readable timestamp.
  Future<String?> _saveCapturedImage(String sourcePath) async {
    try {
      final scansDir = await StorageService.getCategoryDir(StorageService.scansFolder);
      final now = DateTime.now();
      final timestamp = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final fileName = 'Fadocx_scanned_$timestamp.png';
      final destination = File('${scansDir.path}/$fileName');
      await File(sourcePath).copy(destination.path);
      log.i('Saved scanned image to: ${destination.path}');

      // Register in recent files so it appears in the library
      await _registerInRecentFiles(destination.path, fileName);

      return destination.path;
    } catch (e) {
      log.w('Failed to save scanned image to Scans folder: $e');
      return null; // Fall back to temp path
    }
  }

  /// Register a scanned file in the recent files list (Hive database).
  Future<void> _registerInRecentFiles(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      final now = DateTime.now();
      final recentFile = RecentFile(
        id: const Uuid().v4(),
        filePath: filePath,
        fileName: fileName,
        fileType: 'png',
        fileSizeBytes: fileSize,
        dateOpened: now,
        dateModified: now,
        pagePosition: 0,
        syncStatus: 'local',
      );
      final mutator = ref.read(recentFilesMutatorProvider);
      await mutator.addRecentFile(recentFile);
      log.i('Registered scanned file in recent files: $fileName');
    } catch (e) {
      log.w('Failed to register scanned file in recent files: $e');
      // Non-critical - file is still saved to disk
    }
  }

  /// Update a recent file with extracted OCR text (single source of truth in Hive).
  Future<void> _updateRecentFileWithText(String filePath, String extractedText) async {
    try {
      final mutator = ref.read(recentFilesMutatorProvider);
      await mutator.updateExtractedText(filePath, extractedText);
      log.i('Updated extracted text for: $filePath');
    } catch (e) {
      log.w('Failed to update extracted text: $e');
      // Non-critical - OCR text is still in state for this session
    }
  }

  /// Capture and process image, emitting per-step state updates.
  Future<void> captureAndProcess() async {
    if (state.isProcessing) return;

    try {
      // Step: capturing
      state = state.copyWith(
        isProcessing: true,
        processingStep: ProcessingStep.capturing,
      );

      final capturedImage = await _cameraService.capturePhoto();
      if (capturedImage == null) {
        throw Exception('Failed to capture image');
      }

      await disableTorch();

      // Save captured image to Scans folder with proper naming
      final savedPath = await _saveCapturedImage(capturedImage.path);

      state = state.copyWith(
        capturedImagePath: savedPath ?? capturedImage.path,
        displayedImagePath: savedPath ?? capturedImage.path,
        processingStep: ProcessingStep.preparing,
      );

      final rootIsolateToken = RootIsolateToken.instance!;

      final message = IsolateMessage(
        rootIsolateToken: rootIsolateToken,
        imagePath: capturedImage.path,
      );

      // Step 1: OpenCV image processing in background isolate (safe — no ServicesBinding).
      final processedPath = await compute(
        processImageInBackgroundIsolate,
        message,
      );

      // Step 2: OCR on main isolate — flutter_tesseract_ocr requires ServicesBinding.
      state = state.copyWith(processingStep: ProcessingStep.ocr);
      final ocrInputPath = processedPath ?? capturedImage.path;
      final ocrResult = await TesseractService.extractFromImage(ocrInputPath);

      final extractedText = ocrResult?.plainText ?? '';
      final confidence = ocrResult?.averageConfidence ?? 0.0;
      final textBlocks = ocrResult?.lines ?? const <TextBlock>[];

      log.i(
          'Processing done: ${extractedText.length} chars, confidence: ${confidence.toStringAsFixed(2)}');

      // Note: Scan metadata is now stored in Hive via _updateRecentFileWithText
      // (single source of truth — no separate JSON file needed)
      state = state.copyWith(
        hasScannedImage: true,
        extractedText: extractedText,
        ocrConfidence: confidence,
        textBlocks: textBlocks,
        displayedImagePath: ocrInputPath,
        ocrImageWidth: ocrResult?.imageWidth,
        ocrImageHeight: ocrResult?.imageHeight,
        processingStep: ProcessingStep.done,
        isProcessing: false,
      );

      // Update recent file with extracted text (single source of truth in Hive)
      await _updateRecentFileWithText(savedPath ?? capturedImage.path, extractedText);
    } catch (e, st) {
      log.e('captureAndProcess error', error: e, stackTrace: st);
      state = state.copyWith(
        isProcessing: false,
        processingStep: ProcessingStep.idle,
      );
      rethrow;
    }
  }

  Future<void> pickAndProcessImage() async {
    if (state.isProcessing) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final imagePath = result?.files.single.path;
      if (imagePath == null || imagePath.isEmpty) return;

      await _processExistingImage(imagePath);
    } catch (e, st) {
      log.e('pickAndProcessImage error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> _processExistingImage(String imagePath) async {
    // Save uploaded image to Scans folder with proper naming
    final savedPath = await _saveCapturedImage(imagePath);

    state = state.copyWith(
      isProcessing: true,
      processingStep: ProcessingStep.preparing,
      capturedImagePath: savedPath ?? imagePath,
      displayedImagePath: savedPath ?? imagePath,
      extractedText: '',
      ocrConfidence: 0.0,
      textBlocks: const [],
    );

    try {
      final rootIsolateToken = RootIsolateToken.instance!;
      final message = IsolateMessage(
        rootIsolateToken: rootIsolateToken,
        imagePath: imagePath,
      );

      final processedPath = await compute(
        processImageInBackgroundIsolate,
        message,
      );

      state = state.copyWith(processingStep: ProcessingStep.ocr);
      final ocrInputPath = processedPath ?? imagePath;
      final ocrResult = await TesseractService.extractFromImage(ocrInputPath);

      final extractedText = ocrResult?.plainText ?? '';
      final confidence = ocrResult?.averageConfidence ?? 0.0;
      final textBlocks = ocrResult?.lines ?? const <TextBlock>[];

      // Note: Scan metadata is now stored in Hive via _updateRecentFileWithText

      state = state.copyWith(
        hasScannedImage: true,
        extractedText: extractedText,
        ocrConfidence: confidence,
        textBlocks: textBlocks,
        displayedImagePath: ocrInputPath,
        ocrImageWidth: ocrResult?.imageWidth,
        ocrImageHeight: ocrResult?.imageHeight,
        processingStep: ProcessingStep.done,
        isProcessing: false,
      );

      // Update recent file with extracted text (single source of truth in Hive)
      await _updateRecentFileWithText(savedPath ?? imagePath, extractedText);
    } catch (e, st) {
      log.e('_processExistingImage error', error: e, stackTrace: st);
      state = state.copyWith(
        isProcessing: false,
        processingStep: ProcessingStep.idle,
      );
      rethrow;
    }
  }

  void resetScanner() {
    state = ScannerState(cameraInitialized: state.cameraInitialized);
  }

  void dispose() {
    _cameraService.dispose();
  }
}

/// Provider for camera service
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for scanner state
final scannerProvider =
    NotifierProvider.autoDispose<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);
