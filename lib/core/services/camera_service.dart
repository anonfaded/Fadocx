import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fadocx/core/utils/logger.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _initError;
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get initError => _initError;
  List<CameraDescription>? get cameras => _cameras;
  bool get isStreaming => _isStreaming;

  /// Initialize camera service and request permissions
  Future<bool> initialize() async {
    try {
      _initError = null;

      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _initError = 'Camera permission denied';
        log.w('Camera permission denied');
        notifyListeners();
        return false;
      }

      // Dispose any existing controller cleanly before reinitializing.
      if (_controller != null) {
        try {
          if (_isStreaming) {
            await _controller!.stopImageStream();
          }
        } catch (_) {}
        await _controller!.dispose();
        _controller = null;
        _isStreaming = false;
        _isInitialized = false;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _initError = 'No cameras available on device';
        log.w('No cameras found');
        notifyListeners();
        return false;
      }

      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();
      _isInitialized = true;
      _isStreaming = false;
      log.i('Camera initialized successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _initError = 'Failed to initialize camera: $e';
      log.e('Camera initialization error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Start live image stream for frame analysis (e.g. corner detection).
  /// [onFrame] receives a Y-plane-only grayscale Uint8List + image dimensions.
  Future<void> startFrameStream(
    void Function(Uint8List yPlane, int width, int height) onFrame,
  ) async {
    if (_controller == null || !_isInitialized || _isStreaming) return;
    try {
      await _controller!.startImageStream((CameraImage image) {
        // NV21 / YUV420: first plane is the Y (luma) plane
        final yPlane = image.planes[0].bytes;
        onFrame(yPlane, image.width, image.height);
      });
      _isStreaming = true;
      log.i('Frame stream started');
    } catch (e) {
      log.e('Error starting frame stream: $e');
    }
  }

  /// Stop the live image stream before taking a picture.
  Future<void> stopFrameStream() async {
    if (_controller == null) return;
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      _isStreaming = false;
      log.i('Frame stream stopped');
    } catch (e) {
      _isStreaming = false;
      log.w('stopFrameStream: $e');
    }
  }

  /// Capture a still photo. Stops frame stream first if needed.
  Future<XFile?> capturePhoto() async {
    if (_controller == null || !_isInitialized) {
      log.w('Camera not initialized');
      return null;
    }
    try {
      // Must stop stream before takePicture()
      if (_isStreaming) await stopFrameStream();
      final image = await _controller!.takePicture();
      log.i('Photo captured: ${image.path}');
      return image;
    } catch (e) {
      log.e('Error capturing photo: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    if (_isStreaming) await stopFrameStream();
    await _controller?.dispose();
    super.dispose();
  }
}
