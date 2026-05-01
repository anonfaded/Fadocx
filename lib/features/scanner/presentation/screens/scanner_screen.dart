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
import 'package:fadocx/core/services/camera_service.dart';
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
  late AnimationController _scanningController;

  // Cached camera service reference to avoid ref usage in dispose
  CameraService? _cameraService;

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

  // Selected text block index for tap-to-select
  int? _selectedBlockIndex;

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

    _scanningController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start in immersive mode for better camera experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache camera service reference early to avoid ref issues in dispose
    _cameraService ??= ref.read(scannerProvider.notifier).getCameraService();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _processingController.dispose();
    _scanningController.dispose();
    // Restore system UI on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Stop frame stream using cached reference (avoids ref usage on unmounted widget)
    _cameraService?.stopFrameStream();
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

    // Start scanning animation when entering processing or results step
    if (step == 1 || step == 2) {
      _scanningController.repeat(reverse: true);
    } else {
      _scanningController.stop();
      _scanningController.reset();
    }

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

    // Update system UI mode based on step
    if (step == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = colorScheme.surface;
    final onSurfaceColor = colorScheme.onSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: GestureDetector(
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
                          : Colors.black.withValues(alpha: 0.08),
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
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.75)
                        : surfaceColor.withValues(alpha: 0.88),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : colorScheme.outline.withValues(alpha: 0.12),
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
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: isDark ? Colors.white : onSurfaceColor,
                                ),
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
                                  color: isDark ? Colors.white : onSurfaceColor,
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
      ),
    );
  }

  // ─── Step Indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator(BuildContext context, bool isDark) {
    const steps = ['Capture', 'Processing', 'Results'];
    const icons = [
      Icons.camera_alt_outlined,
      Icons.auto_fix_high,
      Icons.description_outlined
    ];
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
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
          final colorForText = isDark ? Colors.white : onSurface;

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
                        ? (isDark ? Colors.white : primaryColor)
                        : colorForText.withValues(alpha: 0.2),
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
                        ? primaryColor
                        : isCompleted
                            ? primaryColor.withValues(alpha: 0.15)
                            : colorForText.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check : icons[index],
                        size: isActive ? 14 : 12,
                        color: isActive
                            ? onPrimary
                            : isCompleted
                                ? primaryColor
                                : colorForText.withValues(alpha: 0.5),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${index + 1}. ${steps[index]}',
                          style: TextStyle(
                            color: onPrimary,
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
                onTapDown: (details) => _handleTapToFocus(details, constraints),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera preview - maintain aspect ratio
                    if (!scannerState.isProcessing &&
                        cameraService.controller != null &&
                        cameraService.isInitialized)
                      Center(
                        child: AspectRatio(
                          aspectRatio:
                              1 / cameraService.controller!.value.aspectRatio,
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
                  _liveCorners != null
                      ? Icons.check_circle
                      : Icons.info_outline,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
    final surface = Theme.of(context).colorScheme.surface;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;

    return Container(
      color: surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Large Document Preview with Scanning Animation
          if (scannerState.capturedImagePath != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.viewPaddingOf(context).top + 110,
                20,
                160,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // The captured image
                    Positioned.fill(
                      child: Image.file(
                        File(scannerState.capturedImagePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Scanning animation overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _scanningController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _ScanningLaserPainter(
                                  scanValue: _scanningController.value,
                                  primaryColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Bottom Progress Overlay
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: outline.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scannerState.processingStep ==
                                          ProcessingStep.done
                                      ? 'Analysis Complete'
                                      : 'Analyzing Document...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  scannerState.processingStep ==
                                          ProcessingStep.preparing
                                      ? 'Enhancing image quality...'
                                      : 'Extracting text data...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Results ────────────────────────────────────────────────────────

  Widget _buildResultsStep(BuildContext context, ScannerState scannerState) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
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
                          animation: _scanningController,
                          showScanEffect: false,
                          isPunchHole: true,
                          selectedBlockIndex: _selectedBlockIndex,
                          onBlockTapped: (index) {
                            setState(() {
                              _selectedBlockIndex =
                                  index < 0 ? null : (_selectedBlockIndex == index ? null : index);
                            });
                          },
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest,
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

  Widget _buildResultsActionBar(
      BuildContext context, ScannerState scannerState) {
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
        color: isDark ? surfaceColor.withValues(alpha: 0.95) : surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
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
                side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3)),
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
  final Animation<double> animation;
  final bool showScanEffect;
  final bool isPunchHole;
  final int? selectedBlockIndex;
  final void Function(int)? onBlockTapped;

  const _DetectedTextPreview({
    required this.imagePath,
    required this.blocks,
    this.imageWidth,
    this.imageHeight,
    required this.animation,
    this.showScanEffect = true,
    this.isPunchHole = false,
    this.selectedBlockIndex,
    this.onBlockTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.topLeft,
          children: [
            // Image: normal brightness — punch-hole darkening is done by the painter
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.file(
                File(imagePath),
                width: constraints.maxWidth,
                fit: BoxFit.fitWidth,
              ),
            ),
            if (imageWidth != null && imageHeight != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: onBlockTapped != null && imageWidth != null && imageHeight != null
                      ? (details) {
                          final scale = constraints.maxWidth / imageWidth!;
                          final tapX = details.localPosition.dx / scale;
                          final tapY = details.localPosition.dy / scale;
                          bool found = false;
                          for (int i = 0; i < blocks.length; i++) {
                            final b = blocks[i];
                            if (b.x != null && b.y != null &&
                                b.width != null && b.height != null) {
                              final r = Rect.fromLTWH(
                                b.x!.toDouble(),
                                b.y!.toDouble(),
                                b.width!.toDouble(),
                                b.height!.toDouble(),
                              );
                              if (r.contains(Offset(tapX, tapY))) {
                                onBlockTapped!(i);
                                found = true;
                                return;
                              }
                            }
                          }
                          // Tapped outside any block — dismiss selection
                          if (!found && selectedBlockIndex != null) {
                            onBlockTapped!(-1);
                          }
                        }
                      : null,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _DetectedTextPainter(
                            blocks: blocks,
                            imageWidth: imageWidth!,
                            imageHeight: imageHeight!,
                            scanValue: animation.value,
                            primaryColor: Theme.of(context).colorScheme.primary,
                            showScanEffect: showScanEffect,
                            isPunchHole: isPunchHole,
                            selectedBlockIndex: selectedBlockIndex,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            // Floating selected-text tooltip near the tapped rectangle
            if (selectedBlockIndex != null &&
                selectedBlockIndex! < blocks.length &&
                imageWidth != null &&
                imageHeight != null)
              _buildFloatingSelectedTooltip(
                context,
                block: blocks[selectedBlockIndex!],
                scale: constraints.maxWidth / imageWidth!,
                imageHeight: imageHeight!,
                containerWidth: constraints.maxWidth,
                onDismiss: () => onBlockTapped?.call(-1),
              ),
          ],
        );
      },
      );
  }

  Widget _buildFloatingSelectedTooltip(
    BuildContext context, {
    required TextBlock block,
    required double scale,
    required int imageHeight,
    required double containerWidth,
    required VoidCallback onDismiss,
  }) {
    final theme = Theme.of(context);
    if (block.x == null || block.y == null ||
        block.width == null || block.height == null) {
      return const SizedBox.shrink();
    }

    final rectLeft = block.x! * scale;
    final rectTop = block.y! * scale;
    final rectRight = (block.x! + block.width!) * scale;
    final rectBottom = (block.y! + block.height!) * scale;
    final rectCenterX = (rectLeft + rectRight) / 2;
    final renderedImageHeight = imageHeight * scale;

    const tooltipWidth = 260.0;
    final tooltipLeft = (rectCenterX - tooltipWidth / 2)
        .clamp(8.0, containerWidth - tooltipWidth - 8);

    // Place above the rectangle with a gap
    const gap = 6.0;
    const tooltipHeight = 110.0;
    final tooltipTop = (rectTop - gap - tooltipHeight).clamp(4.0, renderedImageHeight - tooltipHeight - 4);

    return Positioned(
      left: tooltipLeft,
      top: tooltipTop,
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text display area
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Text(
                  block.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
                ),
              ),
              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
              // Action row
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 6, 8),
                child: Row(
                  children: [
                    Text(
                      '${(block.confidence * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    // Copy button
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: block.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.content_copy, size: 14),
                        label: const Text('Copy', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Close button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: onDismiss,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────

/// Simple scanning laser painter used during the Processing step.
/// Does NOT require OCR data (no blocks, no image dimensions needed).
/// Draws a glowing laser line that sweeps top-to-bottom.
class _ScanningLaserPainter extends CustomPainter {
  final double scanValue;
  final Color primaryColor;

  _ScanningLaserPainter({
    required this.scanValue,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final currentY = size.height * scanValue;

    // Glowing line
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(
      Rect.fromLTWH(0, currentY - 3, size.width, 6),
      glowPaint,
    );

    // Bright core line
    final corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0),
          primaryColor,
          primaryColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, currentY - 12, size.width, 24))
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, currentY),
      Offset(size.width, currentY),
      corePaint,
    );
  }

  @override
  bool shouldRepaint(_ScanningLaserPainter old) => old.scanValue != scanValue;
}

class _DetectedTextPainter extends CustomPainter {
  final List<TextBlock> blocks;
  final int imageWidth;
  final int imageHeight;
  final double scanValue;
  final Color primaryColor;
  final bool showScanEffect;
  final bool isPunchHole;

  _DetectedTextPainter({
    required this.blocks,
    required this.imageWidth,
    required this.imageHeight,
    required this.scanValue,
    required this.primaryColor,
    this.showScanEffect = true,
    this.isPunchHole = false,
    this.selectedBlockIndex,
  });

  final int? selectedBlockIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final scale = size.width / imageWidth;
    final renderedHeight = imageHeight * scale;

    // 1. Draw "Laser" scanning line (only when showScanEffect is true)
    if (showScanEffect) {
      final currentScanY = renderedHeight * scanValue;
      final laserPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0),
            primaryColor,
            primaryColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, currentScanY - 20, size.width, 40))
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(0, currentScanY),
        Offset(size.width, currentScanY),
        laserPaint,
      );

      // Subtle glow behind the laser
      final laserGlowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawRect(
          Rect.fromLTWH(0, currentScanY - 2, size.width, 4), laserGlowPaint);
    }

    // 2. Draw Text Blocks with proximity-based highlight or punch-hole overlay
    if (!showScanEffect && isPunchHole) {
      // Punch-hole effect: dark overlay everywhere except inside detected text rectangles.
      // Uses canvas.saveLayer with BlendMode.clear to cut holes through the dark layer.
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, renderedHeight), Paint());
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, renderedHeight),
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      for (final block in blocks) {
        if (block.x == null || block.y == null ||
            block.width == null || block.height == null) continue;
        final rect = Rect.fromLTWH(
          block.x! * scale,
          block.y! * scale,
          block.width! * scale,
          block.height! * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(6)),
          Paint()..blendMode = BlendMode.clear,
        );
      }
      canvas.restore();
      // Draw white borders on top of the punch holes
      for (final block in blocks) {
        if (block.x == null || block.y == null ||
            block.width == null || block.height == null) continue;
        final rect = Rect.fromLTWH(
          block.x! * scale,
          block.y! * scale,
          block.width! * scale,
          block.height! * scale,
        );
        final borderPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(5)),
          borderPaint,
        );
      }
      // Highlight selected block with a brighter fill + thicker border
      if (selectedBlockIndex != null && selectedBlockIndex! < blocks.length) {
        final sel = blocks[selectedBlockIndex!];
        if (sel.x != null && sel.y != null &&
            sel.width != null && sel.height != null) {
          final selRect = Rect.fromLTWH(
            sel.x! * scale,
            sel.y! * scale,
            sel.width! * scale,
            sel.height! * scale,
          );
          final selFill = Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(selRect.inflate(4), const Radius.circular(6)),
            selFill,
          );
          final selBorder = Paint()
            ..color = primaryColor.withValues(alpha: 0.9)
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke;
          canvas.drawRRect(
            RRect.fromRectAndRadius(selRect.inflate(4), const Radius.circular(6)),
            selBorder,
          );
        }
      }
    } else if (showScanEffect) {
      for (final block in blocks) {
        if (block.x == null || block.y == null ||
            block.width == null || block.height == null) continue;
        final rect = Rect.fromLTWH(
          block.x! * scale,
          block.y! * scale,
          block.width! * scale,
          block.height! * scale,
        );

        // Distance from laser line (normalized 0 to 1)
        final currentScanY = renderedHeight * scanValue;
        final distance = (rect.center.dy - currentScanY).abs();
        final proximity = (1.0 - (distance / 100)).clamp(0.0, 1.0);

        if (proximity > 0) {
          final blockPaint = Paint()
            ..color = primaryColor.withValues(alpha: 0.1 * proximity)
            ..style = PaintingStyle.fill;

          final borderPaint = Paint()
            ..color = primaryColor.withValues(alpha: 0.4 * proximity)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

          canvas.drawRRect(
            RRect.fromRectAndRadius(
                rect.inflate(2 * proximity), const Radius.circular(4)),
            blockPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                rect.inflate(2 * proximity), const Radius.circular(4)),
            borderPaint,
          );

          // Add a "digitizing" effect (tiny dots at corners)
          if (proximity > 0.7) {
            final dotPaint = Paint()
              ..color = primaryColor.withValues(alpha: proximity);
            canvas.drawCircle(rect.topLeft, 1.5, dotPaint);
            canvas.drawCircle(rect.topRight, 1.5, dotPaint);
            canvas.drawCircle(rect.bottomLeft, 1.5, dotPaint);
            canvas.drawCircle(rect.bottomRight, 1.5, dotPaint);
          }
        }
      }
    }

    // 3. Mask the unrendered area (if image is shorter than canvas)
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
      old.scanValue != scanValue ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight ||
      old.showScanEffect != showScanEffect;
}

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
    final hMargin = size.width * 0.08;
    final vMargin = size.height * 0.12;
    final rect = Rect.fromLTWH(
      hMargin,
      vMargin,
      size.width - (hMargin * 2),
      size.height - (vMargin * 2),
    );

    // Subtle pulse outline
    final pulseAlpha = 0.06 *
        (1 - (pulseValue - pulseValue.floor()).abs() * 2).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: pulseAlpha)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final expand =
        4.0 * (1 - (pulseValue - pulseValue.floor()).abs() * 2).clamp(0.0, 1.0);
    canvas.drawRect(rect.inflate(expand), pulsePaint);

    // Only draw corner brackets
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
