import 'dart:async';
import 'dart:io';
import 'dart:ui';
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
///
/// Three-step flow: Capture → Processing → Results
/// Camera is only active during step 0 (Capture).
/// Tap-to-focus is supported on the camera preview.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _processingController;

  // Step tracking (0: Capture, 1: Processing, 2: Results)
  int _currentStep = 0;

  // Live document corner detection (from frame stream, not takePicture)
  DocumentCorners? _liveCorners;
  // Image dimensions from the last processed frame (for coordinate scaling)
  int _frameWidth = 1;
  int _frameHeight = 1;
  // Throttle: only process one frame at a time
  bool _processingFrame = false;

  // Tap-to-focus animation
  Offset? _focusPoint;
  bool _showFocusAnimation = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _processingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Start in immersive mode for better camera experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _processingController.dispose();
    // Restore system UI on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Stop frame stream on dispose
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    cameraService.stopFrameStream();
    super.dispose();
  }

  // ─── Camera lifecycle ─────────────────────────────────────────────────────

  void _startFrameStream() {
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    cameraService.startFrameStream((Uint8List yPlane, int w, int h) {
      if (_processingFrame || !mounted) return;
      // Throttle to ~3 fps for corner detection
      _processingFrame = true;
      Future.microtask(() {
        try {
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

  // ─── Tap-to-focus ──────────────────────────────────────────────────────────

  void _handleTapToFocus(TapDownDetails details, BoxConstraints constraints) {
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    final controller = cameraService.controller;
    if (controller == null || !cameraService.isInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    // Show focus animation at tap point
    setState(() {
      _focusPoint = details.localPosition;
      _showFocusAnimation = true;
    });

    // Set focus and exposure point
    controller.setFocusPoint(offset);
    controller.setExposurePoint(offset);

    // Hide focus animation after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showFocusAnimation = false);
      }
    });
  }

  // ─── Navigation helper ────────────────────────────────────────────────────

  void _goToStep(int step) {
    if (!mounted) return;
    final prevStep = _currentStep;
    setState(() {
      _currentStep = step.clamp(0, 2);
      // Camera lifecycle: stop stream when leaving capture step
      if (prevStep == 0 && step > 0) {
        _liveCorners = null;
      }
    });

    // Camera lifecycle: stop/start stream outside setState
    if (prevStep == 0 && step > 0) {
      _stopFrameStream();
    }
    // Restart stream when returning to capture step
    if (prevStep > 0 && step == 0) {
      final scannerState = ref.read(scannerProvider);
      if (scannerState.cameraInitialized && !scannerState.isProcessing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startFrameStream();
        });
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If camera was already initialized before this widget mounted, start stream
    final cameraService = ref.read(scannerProvider.notifier).getCameraService();
    if (scannerState.cameraInitialized &&
        !cameraService.isStreaming &&
        !scannerState.isProcessing &&
        _currentStep == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startFrameStream());
    }

    // React to state changes
    ref.listen<ScannerState>(scannerProvider, (prev, next) {
      // Start frame stream once camera is ready
      if (prev?.cameraInitialized == false && next.cameraInitialized) {
        _startFrameStream();
      }
      // Stop stream and switch step when processing begins
      if (prev?.isProcessing == false && next.isProcessing) {
        _stopFrameStream();
        setState(() => _liveCorners = null);
        _goToStep(1);
      }
      // Switch to results when done
      if (prev?.isProcessing == true &&
          !next.isProcessing &&
          next.hasScannedImage) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _goToStep(2);
        });
      }
    });

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: _currentStep == 0 ? Colors.black : surfaceColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Step content (full bleed)
          _buildStepContent(context, scannerState, isDark),

          // Floating top bar (back button + title)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(context, isDark),
          ),

          // Step indicator (below top bar)
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 52,
            left: 0,
            right: 0,
            child: Center(
              child: _buildStepIndicator(context, isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Floating Top Bar ─────────────────────────────────────────────────────

  Widget _buildFloatingTopBar(BuildContext context, bool isDark) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {}, // Absorb taps
      child: Stack(
        children: [
          // Shadow below the top bar
          Positioned(
            bottom: -8,
            left: 0,
            right: 0,
            height: 8,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // Main top bar with rounded bottom corners
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: _currentStep == 0
                      ? (isDark
                          ? Colors.black.withValues(alpha: 0.75)
                          : Colors.black.withValues(alpha: 0.4))
                      : (isDark
                          ? surfaceColor.withValues(alpha: 0.85)
                          : surfaceColor.withValues(alpha: 0.95)),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: _currentStep == 0
                          ? Colors.white.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(Icons.chevron_left,
                                  color: _currentStep == 0 || isDark ? Colors.white : onSurfaceColor),
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
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Center(
                            child: Text(
                              'Document Scanner',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _currentStep == 0 || isDark ? Colors.white : onSurfaceColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step Indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator(BuildContext context, bool isDark) {
    const steps = ['Capture', 'Processing', 'Results'];
    const icons = [Icons.camera_alt_outlined, Icons.auto_fix_high, Icons.description_outlined];
    final surfaceVariant = Theme.of(context).colorScheme.surfaceContainerHighest;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _currentStep == 0 
            ? Colors.white.withValues(alpha: 0.12)
            : surfaceVariant.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: _currentStep == 0 
            ? null 
            : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: _currentStep == 0 ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          final colorForText = _currentStep == 0 ? Colors.white : onSurface;

          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Connector line
                if (index > 0)
                  Container(
                    width: 12,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: isCompleted
                        ? colorForText
                        : colorForText.withValues(alpha: 0.3),
                  ),
                // Step pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 12 : 8,
                    vertical: isActive ? 6 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (_currentStep == 0 ? Colors.white : Theme.of(context).colorScheme.primary)
                        : isCompleted
                            ? colorForText.withValues(alpha: 0.2)
                            : colorForText.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check : icons[index],
                        size: isActive ? 14 : 12,
                        color: isActive
                            ? (_currentStep == 0 ? Colors.black : Theme.of(context).colorScheme.onPrimary)
                            : isCompleted
                                ? colorForText
                                : colorForText.withValues(alpha: 0.6),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${index + 1}. ${steps[index]}',
                          style: TextStyle(
                            color: isActive
                                ? (_currentStep == 0 ? Colors.black : Theme.of(context).colorScheme.onPrimary)
                                : colorForText,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step Content Router ──────────────────────────────────────────────────

  Widget _buildStepContent(
      BuildContext context, ScannerState scannerState, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildCaptureStep(context, scannerState);
      case 1:
        return _buildProcessingStep(context, scannerState);
      case 2:
        return _buildResultsStep(context, scannerState);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Capture ──────────────────────────────────────────────────────

  Widget _buildCaptureStep(BuildContext context, ScannerState scannerState) {
    // Show loading state while camera initializes (not the error screen)
    if (!scannerState.cameraInitialized && scannerState.cameraError == null) {
      return _buildCameraLoading(context);
    }
    // Show error only if camera actually failed
    if (!scannerState.cameraInitialized) {
      return _buildCameraError(context, scannerState);
    }

    final cameraService = ref.read(scannerProvider.notifier).getCameraService();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed camera preview
        Container(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) =>
                    _handleTapToFocus(details, constraints),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera preview - maintain aspect ratio
                    if (!scannerState.isProcessing &&
                        cameraService.controller != null &&
                        cameraService.isInitialized)
                      Center(
                        child: AspectRatio(
                          aspectRatio: 1 /
                              cameraService.controller!.value.aspectRatio,
                          child: CameraPreview(cameraService.controller!),
                        ),
                      )
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    // Live document quad overlay
                    if (_liveCorners != null && !scannerState.isProcessing)
                      CustomPaint(
                        painter: _DocumentQuadPainter(
                          corners: _liveCorners!,
                          color: Colors.white,
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
                              color: Colors.white,
                              pulseValue: _pulseController.value,
                            ),
                          );
                        },
                      ),
                    // Tap-to-focus indicator
                    if (_showFocusAnimation && _focusPoint != null)
                      _buildFocusIndicator(),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom panel with controls
        if (!scannerState.isProcessing)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCapturePanel(context, scannerState),
          ),
      ],
    );
  }

  Widget _buildFocusIndicator() {
    return Positioned(
      left: _focusPoint!.dx - 30,
      top: _focusPoint!.dy - 30,
      child: AnimatedOpacity(
        opacity: _showFocusAnimation ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.yellow.withValues(alpha: 0.9),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildCapturePanel(BuildContext context, ScannerState scannerState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _liveCorners != null
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _liveCorners != null
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _liveCorners != null ? Icons.check_circle : Icons.info_outline,
                  size: 14,
                  color: _liveCorners != null ? Colors.green : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  _liveCorners != null
                      ? 'Document detected — hold steady'
                      : 'Keep document upright & flat for best results',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Main controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Upload button
              _buildCaptureSideButton(
                context: context,
                icon: Icons.photo_library_outlined,
                label: 'Upload',
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(scannerProvider.notifier)
                        .pickAndProcessImage();
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to open image: $e')),
                      );
                    }
                  }
                },
              ),
              // Capture button (large, center)
              _buildCaptureButton(context),
              // Torch button
              _buildCaptureSideButton(
                context: context,
                icon: scannerState.torchEnabled
                    ? Icons.flash_on
                    : Icons.flash_off,
                label: 'Flash',
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  ref
                      .read(scannerProvider.notifier)
                      .toggleTorch()
                      .catchError((e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to toggle torch: $e')),
                    );
                  });
                },
isActive: scannerState.torchEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(scannerProvider.notifier).captureAndProcess();
        } catch (e) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
            _goToStep(0);
          }
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.black,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureSideButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              border: isActive
                  ? Border.all(color: Colors.yellow, width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.yellow : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLoading(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Starting Camera...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraError(BuildContext context, ScannerState scannerState) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.photo_camera_back_outlined,
                    size: 40, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                scannerState.cameraError ?? 'Unable to initialize camera',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => ref
                    .read(scannerProvider.notifier)
                    .retryCameraInitialization(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Processing ────────────────────────────────────────────────────

  Widget _buildProcessingStep(BuildContext context, ScannerState scannerState) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;

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

    return Container(
      color: surface,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: MediaQuery.viewPaddingOf(context).top + 52 + 44 + 8,
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Captured image preview with a thematic border
              if (scannerState.capturedImagePath != null)
                Container(
                  height: 220,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: outline.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(scannerState.capturedImagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              // Processing steps card with modern surface coloring
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          scannerState.processingStep == ProcessingStep.done
                              ? 'Processing Complete'
                              : 'Processing Document...',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (scannerState.processingStep != ProcessingStep.done) ...[
                          const Spacer(),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    for (final info in steps) ...[
                      _buildProcessingStepRow(context, scannerState, info),
                      if (info != steps.last) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              // Confidence badge (shown when done)
              if (scannerState.processingStep == ProcessingStep.done) ...[
                const SizedBox(height: 24),
                _buildConfidenceBadge(context, scannerState.ocrConfidence),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildProcessingStepRow(
    BuildContext context,
    ScannerState state,
    _StepInfo info,
  ) {
    final isCompleted = state.isStepCompleted(info.step);
    final isActive = state.isStepActive(info.step);
    final isPending = !isCompleted && !isActive;
    
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.1)
            : isActive
                ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.25)
              : isActive
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.08),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          if (isActive)
            AnimatedBuilder(
              animation: _processingController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_processingController.value * 2 * 3.14159,
                  child: Icon(Icons.sync, size: 20, color: colorScheme.primary),
                );
              },
            )
          else
            Icon(
              isCompleted ? Icons.check_circle : info.icon,
              size: 20,
              color: isCompleted
                  ? Colors.green
                  : isPending
                      ? onSurface.withValues(alpha: 0.25)
                      : onSurface.withValues(alpha: 0.6),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: TextStyle(
                    color: isPending ? onSurface.withValues(alpha: 0.35) : onSurface,
                    fontWeight: isCompleted || isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: isPending ? 0.25 : 0.55),
                    fontSize: 12,
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            'OCR Confidence: $pct%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Results ────────────────────────────────────────────────────────

  Widget _buildResultsStep(BuildContext context, ScannerState scannerState) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;

    if (!scannerState.hasScannedImage) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 80,
                color: onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Scans Yet',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Capture a document to see extracted text here',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Top padding for floating top bar + step indicator
          SizedBox(
            height: MediaQuery.viewPaddingOf(context).top + 52 + 44 + 8,
          ),
          // Results content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview with detected text
                  if (imagePath != null) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _DetectedTextPreview(
                          imagePath: imagePath,
                          blocks: scannerState.textBlocks,
                          imageWidth: scannerState.ocrImageWidth,
                          imageHeight: scannerState.ocrImageHeight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Extracted text header
                  Row(
                    children: [
                      Text(
                        'Extracted Text',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (confidence > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: confidenceColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: confidenceColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  size: 12, color: confidenceColor),
                              const SizedBox(width: 4),
                              Text(
                                '${(confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: confidenceColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Extracted text box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: SelectableText(
                      scannerState.extractedText.isEmpty
                          ? '(No text extracted)'
                          : scannerState.extractedText,
                      style: TextStyle(
                        color: scannerState.extractedText.isEmpty
                            ? onSurface.withValues(alpha: 0.38)
                            : onSurface,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Detected lines
                  if (scannerState.textBlocks.isNotEmpty) ...[
                    Text(
                      'Detected Lines',
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: outline.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: scannerState.textBlocks
                            .map((block) => _DetectedLineTile(block: block))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          // Bottom action bar
          _buildResultsActionBar(context, scannerState),
        ],
      ),
    );
  }

  Widget _buildResultsActionBar(BuildContext context, ScannerState scannerState) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? surfaceColor.withValues(alpha: 0.95)
            : surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Copy All button
          Expanded(
            child: OutlinedButton.icon(
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
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: onSurface,
                side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // New Scan button
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                ref.read(scannerProvider.notifier).resetScanner();
                _goToStep(0);
                setState(() => _liveCorners = null);
                _startFrameStream();
              },
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('New Scan'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color = block.confidence >= 0.8
        ? Colors.green
        : block.confidence >= 0.5
            ? Colors.orange
            : Colors.red;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              block.text,
              style: TextStyle(color: onSurface, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(block.confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
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
    return LayoutBuilder(
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
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────

/// Draws the detected document quad on the camera preview.
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
    // Gentle guide corners — not a strict frame, just visual hints
    // Margins are modest so it doesn't feel like a required boundary
    final hMargin = size.width * 0.08;
    final vMargin = size.height * 0.12;
    final rect = Rect.fromLTWH(
      hMargin,
      vMargin,
      size.width - (hMargin * 2),
      size.height - (vMargin * 2),
    );

    // Subtle pulse outline (very faint, just a gentle guide)
    final pulseAlpha =
        0.06 * (1 - (pulseValue - pulseValue.floor()).abs() * 2).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: pulseAlpha)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final expand =
        4.0 * (1 - (pulseValue - pulseValue.floor()).abs() * 2).clamp(0.0, 1.0);
    canvas.drawRect(rect.inflate(expand), pulsePaint);

    // Only draw corner brackets — no full rectangle outline
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, cornerPaint);
      canvas.drawLine(b, c, cornerPaint);
    }

    // Top-left
    corner(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
    );
    // Top-right
    corner(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
    );
    // Bottom-left
    corner(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
    );
    // Bottom-right
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