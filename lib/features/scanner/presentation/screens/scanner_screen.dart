import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:logger/logger.dart';
import 'package:fadocx/core/services/image_processing_service.dart';
import 'package:fadocx/core/services/tesseract_service.dart';
import 'package:fadocx/features/scanner/presentation/providers/scanner_provider.dart';

final log = Logger();

/// Document Scanner Screen
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _processingController;

  // Live document corner detection (from frame stream, not takePicture)
  DocumentCorners? _liveCorners;
  // Image dimensions from the last processed frame (for coordinate scaling)
  int _frameWidth = 1;
  int _frameHeight = 1;
  // Throttle: only process one frame at a time
  bool _processingFrame = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _processingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _processingController.dispose();
    // Stop frame stream on dispose
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    cameraService.stopFrameStream();
    super.dispose();
  }

  // ─── Live corner detection via frame stream ───────────────────────────────

  void _startFrameStream() {
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    cameraService.startFrameStream((Uint8List yPlane, int w, int h) {
      if (_processingFrame || !mounted) return;
      // Throttle to ~3 fps for corner detection
      _processingFrame = true;
      Future.microtask(() {
        try {
          // Build a grayscale Mat from the Y-plane bytes
          final mat = cv.Mat.fromList(h, w, cv.MatType.CV_8UC1, yPlane);
          final corners = ImageProcessingService.detectCornersFromMat(mat);
          mat.dispose();
          if (mounted) {
            setState(() {
              _liveCorners = corners;
              _frameWidth = w;
              _frameHeight = h;
            });
          }
        } catch (_) {
          // best-effort
        } finally {
          Future.delayed(const Duration(milliseconds: 300), () {
            _processingFrame = false;
          });
        }
      });
    });
  }

  void _stopFrameStream() {
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    cameraService.stopFrameStream();
  }

  // ─── Navigation helper ────────────────────────────────────────────────────

  void _goToTab(int index) {
    if (mounted) _tabController.animateTo(index);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    // If camera was already initialized before this widget mounted, start stream
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    if (scannerState.cameraInitialized &&
        !cameraService.isStreaming &&
        !scannerState.isProcessing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startFrameStream());
    }

    // React to state changes
    ref.listen<ScannerState>(scannerProvider, (prev, next) {
      // Start frame stream once camera is ready
      if (prev?.cameraInitialized == false && next.cameraInitialized) {
        _startFrameStream();
      }
      // Stop stream and switch tab when processing begins
      if (prev?.isProcessing == false && next.isProcessing) {
        _stopFrameStream();
        setState(() => _liveCorners = null);
        _goToTab(1);
      }
      // Switch to results when done
      if (prev?.isProcessing == true &&
          !next.isProcessing &&
          next.hasScannedImage) {
        Future.delayed(const Duration(milliseconds: 400), () => _goToTab(2));
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.camera_alt_outlined), text: 'Capture'),
                Tab(icon: Icon(Icons.auto_fix_high), text: 'Processing'),
                Tab(icon: Icon(Icons.description_outlined), text: 'Results'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCaptureTab(context, scannerState),
                _buildProcessingTab(context, scannerState),
                _buildResultsTab(context, scannerState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      try {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/');
                        }
                      } catch (e) {
                        log.e('Error navigating back', error: e);
                        context.go('/');
                      }
                    },
                    tooltip: 'Back',
                    iconSize: 20,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Document Scanner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tab 1: Capture ───────────────────────────────────────────────────────

  Widget _buildCaptureTab(BuildContext context, ScannerState scannerState) {
    if (!scannerState.cameraInitialized) {
      return _buildCameraError(context, scannerState);
    }

    final cameraService = ref.read(scannerProvider.notifier).getCameraService();

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview (hidden when processing to avoid stale frame)
                if (!scannerState.isProcessing &&
                    cameraService.controller != null &&
                    cameraService.isInitialized)
                  CameraPreview(cameraService.controller!)
                else if (scannerState.capturedImagePath != null)
                  Image.file(
                    File(scannerState.capturedImagePath!),
                    fit: BoxFit.cover,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing Camera...',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ),
                // Live document quad overlay
                if (_liveCorners != null && !scannerState.isProcessing)
                  CustomPaint(
                    painter: _DocumentQuadPainter(
                      corners: _liveCorners!,
                      color: Theme.of(context).colorScheme.primary,
                      imageWidth: _frameWidth,
                      imageHeight: _frameHeight,
                    ),
                  ),
                // Animated capture frame overlay (when no detected quad)
                if (_liveCorners == null && !scannerState.isProcessing)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _CaptureFramePainter(
                          color: Theme.of(context).colorScheme.primary,
                          pulseValue: _pulseController.value,
                        ),
                      );
                    },
                  ),
                // Bottom controls
                if (!scannerState.isProcessing)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          // Torch toggle
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: scannerState.torchEnabled
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                scannerState.torchEnabled
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                final messenger = ScaffoldMessenger.of(context);
                                ref
                                    .read(scannerProvider.notifier)
                                    .toggleTorch()
                                    .catchError((e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to toggle torch: $e')),
                                  );
                                });
                              },
                            ),
                          ),
                          // Capture button
                          FloatingActionButton.extended(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(scannerProvider.notifier)
                                    .captureAndProcess();
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  _goToTab(0);
                                }
                              }
                            },
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture'),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(scannerProvider.notifier)
                                    .pickAndProcessImage();
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to open image: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Upload Image'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surface,
          child: Text(
            _liveCorners != null
                ? 'Document detected — tap Capture to scan'
                : 'Position document within the frame and tap Capture',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _liveCorners != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraError(BuildContext context, ScannerState scannerState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_back_outlined,
                size: 80, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 24),
            Text('Camera Unavailable',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              scannerState.cameraError ?? 'Unable to initialize camera',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref
                  .read(scannerProvider.notifier)
                  .retryCameraInitialization(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 2: Processing ────────────────────────────────────────────────────

  Widget _buildProcessingTab(BuildContext context, ScannerState scannerState) {
    final steps = [
      _StepInfo(
        step: ProcessingStep.preparing,
        icon: Icons.crop,
        title: 'Prepare Document',
        description: 'OpenCV page crop + perspective normalization',
      ),
      _StepInfo(
        step: ProcessingStep.ocr,
        icon: Icons.text_fields,
        title: 'OCR Extraction',
        description: 'Tesseract hOCR with line boxes and confidence',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Captured image preview
          if (scannerState.capturedImagePath != null)
            Container(
              height: 180,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(scannerState.capturedImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Step indicators
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scannerState.processingStep == ProcessingStep.done
                      ? 'Processing Complete'
                      : 'Processing Document...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                for (final info in steps) ...[
                  _buildStepRow(context, scannerState, info),
                  if (info != steps.last) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          // Confidence badge (shown when done)
          if (scannerState.processingStep == ProcessingStep.done) ...[
            const SizedBox(height: 20),
            _buildConfidenceBadge(context, scannerState.ocrConfidence),
            const SizedBox(height: 12),
            Text(
              'Showing the processed OCR image with detected text boxes.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context,
    ScannerState state,
    _StepInfo info,
  ) {
    final isCompleted = state.isStepCompleted(info.step);
    final isActive = state.isStepActive(info.step);
    final isPending = !isCompleted && !isActive;

    Color iconColor;
    IconData iconData;
    if (isCompleted) {
      iconColor = Theme.of(context).colorScheme.primary;
      iconData = Icons.check_circle;
    } else if (isActive) {
      iconColor = Theme.of(context).colorScheme.secondary;
      iconData = info.icon;
    } else {
      iconColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
      iconData = info.icon;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.25)
            : isActive
                ? Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : isActive
                  ? Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.4)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          if (isActive)
            AnimatedBuilder(
              animation: _processingController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _processingController.value * 2 * 3.14159,
                  child: Icon(Icons.sync, size: 24, color: iconColor),
                );
              },
            )
          else
            Icon(iconData, size: 24, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPending
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4)
                            : null,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: isPending ? 0.4 : 0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, double confidence) {
    final pct = (confidence * 100).toStringAsFixed(0);
    final color = confidence >= 0.8
        ? Colors.green
        : confidence >= 0.5
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            'OCR Confidence: $pct%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 3: Results ───────────────────────────────────────────────────────

  Widget _buildResultsTab(BuildContext context, ScannerState scannerState) {
    if (!scannerState.hasScannedImage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text('No Scans Yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Capture a document to see extracted text here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final confidence = scannerState.ocrConfidence;
    final confidenceColor = confidence >= 0.8
        ? Colors.green
        : confidence >= 0.5
            ? Colors.orange
            : Colors.red;
    final imagePath = scannerState.displayedImagePath;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null) ...[
            Text(
              'Detected Regions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _DetectedTextPreview(
              imagePath: imagePath,
              blocks: scannerState.textBlocks,
              imageWidth: scannerState.ocrImageWidth,
              imageHeight: scannerState.ocrImageHeight,
            ),
            const SizedBox(height: 20),
          ],
          // Confidence chip
          Row(
            children: [
              Text(
                'Extracted Text',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (confidence > 0)
                Chip(
                  avatar:
                      Icon(Icons.verified, size: 14, color: confidenceColor),
                  label: Text(
                    '${(confidence * 100).toStringAsFixed(0)}% confidence',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: confidenceColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  backgroundColor: confidenceColor.withValues(alpha: 0.1),
                  side:
                      BorderSide(color: confidenceColor.withValues(alpha: 0.3)),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Extracted text box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: SelectableText(
              scannerState.extractedText.isEmpty
                  ? '(No text extracted)'
                  : scannerState.extractedText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: scannerState.extractedText.isEmpty
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: scannerState.extractedText.isNotEmpty
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: scannerState.extractedText),
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Text copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Copy All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    ref.read(scannerProvider.notifier).resetScanner();
                    _goToTab(0);
                    setState(() => _liveCorners = null);
                    // Restart stream for new scan
                    _startFrameStream();
                  },
                  child: const Text('New Scan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (scannerState.textBlocks.isNotEmpty) ...[
            Text(
              'Detected Lines',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: scannerState.textBlocks
                    .map((block) => _DetectedLineTile(block: block))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (scannerState.capturedImagePath != null) ...[
            Text(
              'Original Capture',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(scannerState.capturedImagePath!),
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helper data class ─────────────────────────────────────────────────────

class _StepInfo {
  final ProcessingStep step;
  final IconData icon;
  final String title;
  final String description;

  const _StepInfo({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _DetectedLineTile extends StatelessWidget {
  final TextBlock block;

  const _DetectedLineTile({required this.block});

  @override
  Widget build(BuildContext context) {
    final color = block.confidence >= 0.8
        ? Theme.of(context).colorScheme.primary
        : block.confidence >= 0.5
            ? Colors.orange
            : Theme.of(context).colorScheme.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              block.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(block.confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetectedTextPreview extends StatelessWidget {
  final String imagePath;
  final List<TextBlock> blocks;
  final int? imageWidth;
  final int? imageHeight;

  const _DetectedTextPreview({
    required this.imagePath,
    required this.blocks,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.topLeft,
              children: [
                Image.file(
                  File(imagePath),
                  width: constraints.maxWidth,
                  fit: BoxFit.fitWidth,
                ),
                if (imageWidth != null && imageHeight != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _DetectedTextPainter(
                          blocks: blocks,
                          imageWidth: imageWidth!,
                          imageHeight: imageHeight!,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────

/// Draws the detected document quad on the camera preview.
///
/// The camera stream delivers frames in landscape orientation (sensor space).
/// The preview widget shows them in portrait (rotated 90° CCW on most phones).
/// We must map from image-space to screen-space:
///   screenX = (imgY / imgH) * screenW
///   screenY = ((imgW - imgX) / imgW) * screenH
class _DocumentQuadPainter extends CustomPainter {
  final DocumentCorners corners;
  final Color color;
  final int imageWidth;
  final int imageHeight;

  _DocumentQuadPainter({
    required this.corners,
    required this.color,
    required this.imageWidth,
    required this.imageHeight,
  });

  Offset _toScreen(cv.Point p, Size size) {
    // Image is landscape (W > H), preview is portrait.
    // 90° CCW rotation to match CameraPreview display.
    final fx = p.x / imageWidth;
    final fy = p.y / imageHeight;
    return Offset(fy * size.width, (1 - fx) * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.points.length != 4 || imageWidth <= 1 || imageHeight <= 1) {
      return;
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final pts = corners.points.map((p) => _toScreen(p, size)).toList();

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < 4; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in pts) {
      canvas.drawCircle(p, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_DocumentQuadPainter old) =>
      old.corners != corners ||
      old.color != color ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight;
}

/// Animated capture frame with corner highlights.
class _CaptureFramePainter extends CustomPainter {
  final Color color;
  final double pulseValue;

  _CaptureFramePainter({required this.color, this.pulseValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final pulseAlpha =
        0.1 * (1 - (pulseValue - pulseValue.floor()).abs() * 2).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: pulseAlpha)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(40, 20, size.width - 80, size.height - 40);
    final expand =
        8.0 * (1 - (pulseValue - pulseValue.floor()).abs() * 2).clamp(0.0, 1.0);
    canvas.drawRect(rect.inflate(expand), pulsePaint);
    canvas.drawRect(rect, mainPaint);

    final cornerLength = 25.0;
    final cornerPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, cornerPaint);
      canvas.drawLine(b, c, cornerPaint);
    }

    corner(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
    );
    corner(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
    );
    corner(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
    );
    corner(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
    );
  }

  @override
  bool shouldRepaint(_CaptureFramePainter old) =>
      old.pulseValue != pulseValue || old.color != color;
}

class _DetectedTextPainter extends CustomPainter {
  final List<TextBlock> blocks;
  final int imageWidth;
  final int imageHeight;

  _DetectedTextPainter({
    required this.blocks,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final scale = size.width / imageWidth;
    final renderedHeight = imageHeight * scale;

    final fillPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF95D5B2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final block in blocks) {
      if (block.x == null ||
          block.y == null ||
          block.width == null ||
          block.height == null) {
        continue;
      }

      final rect = Rect.fromLTWH(
        block.x! * scale,
        block.y! * scale,
        block.width! * scale,
        block.height! * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        strokePaint,
      );
    }

    if (renderedHeight < size.height) {
      final maskPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(
            0, renderedHeight, size.width, size.height - renderedHeight),
        maskPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DetectedTextPainter old) =>
      old.blocks != blocks ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight;
}
