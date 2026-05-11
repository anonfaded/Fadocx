import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

const _audioFormats = {
  'aac', 'mp3', 'wav', 'ogg', 'flac', 'm4a', 'wma', 'opus', 'aiff',
};

const _videoFormats = {
  'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', '3gp', 'm4v', 'mpg', 'mpeg', 'fmp4',
};

bool isAudioFormat(String path) {
  final ext = path.split('.').last.toLowerCase();
  return _audioFormats.contains(ext);
}

bool isVideoFormat(String path) {
  final ext = path.split('.').last.toLowerCase();
  return _videoFormats.contains(ext);
}

bool isMediaFormat(String path) => isAudioFormat(path) || isVideoFormat(path);

class MediaViewer extends StatefulWidget {
  final String filePath;
  final String fileName;
  final VoidCallback? onTap;

  const MediaViewer({
    required this.filePath,
    required this.fileName,
    this.onTap,
    super.key,
  });

  @override
  MediaViewerState createState() => MediaViewerState();
}

class MediaViewerState extends State<MediaViewer> {
  late VideoPlayerController _controller;
  VideoPlayerController get controller => _controller;

  // Outer notifier — viewer_screen VLB listens to this so it rebinds
  // automatically when we swap to the pre-warmed controller on replay.
  final currentController = ValueNotifier<VideoPlayerController?>(null);

  final ValueNotifier<bool> loopNotifier = ValueNotifier(false);

  // Pre-warmed controller: initialized in background the moment video completes.
  // On replay the hot-swap is instant — no codec re-init delay.
  VideoPlayerController? _nextController;
  bool _prewarmStarted = false;
  bool _pendingPlay = false; // play was tapped before prewarm finished

  // setState guards — only rebuild on init/error transitions, not every frame
  bool _prevInitialized = false;
  bool _prevError = false;
  bool _prevCompleted = false;

  bool get isAudio => isAudioFormat(widget.filePath);

  // ---------------------------------------------------------------------------
  // Playback control — called from viewer_screen
  // ---------------------------------------------------------------------------

  /// Toggle play/pause. Handles all states robustly.
  ///
  /// Completed state: swaps in the pre-warmed controller for instant replay.
  /// If prewarm isn't ready yet (still initializing), marks _pendingPlay so the
  /// swap fires automatically when prewarm finishes. If prewarm was somehow
  /// cancelled, restarts it so the user is never permanently stuck.
  Future<void> togglePlay() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
      return;
    }

    if (_controller.value.isCompleted) {
      if (_nextController != null) {
        await _swapToNextAndPlay();
      } else {
        // Prewarm still initializing OR was cancelled — ensure it's running
        // and mark pending so swap auto-plays on finish.
        if (!_prewarmStarted) _startPrewarm();
        _pendingPlay = true;
      }
      return;
    }

    await _controller.play();
  }

  void play() => _controller.play();
  void pause() => _controller.pause();

  /// Seek to a position. Cancels any pending pre-warm because seeking on a
  /// completed video means the user wants to scrub, not replay from start.
  Future<void> seekTo(Duration d) async {
    _cancelPrewarm();
    await _controller.seekTo(d);
  }

  void setSpeed(double speed) => _controller.setPlaybackSpeed(speed);

  void toggleLoop() {
    loopNotifier.value = !loopNotifier.value;
    // Use ExoPlayer REPEAT_MODE_ALL — never flushes the hardware codec on loop
    _controller.setLooping(loopNotifier.value);

    if (loopNotifier.value) {
      // Loop just enabled: cancel prewarm (ExoPlayer handles looping natively)
      // and restart from current position if video already ended
      _cancelPrewarm();
      if (_controller.value.isCompleted) {
        _controller.play(); // ExoPlayer loops back to start instantly
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Pre-warm — background init of next controller for instant replay
  // ---------------------------------------------------------------------------

  /// Start pre-warming as soon as video completes (but not during native loop).
  void _startPrewarm() {
    if (_prewarmStarted) return;
    _prewarmStarted = true;
    _doPrewarm();
  }

  Future<void> _doPrewarm() async {
    final next = VideoPlayerController.file(
      File(widget.filePath),
      // Prevent the warm (non-playing) controller from competing for audio focus
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await next.initialize();
    } catch (_) {
      next.dispose();
      if (mounted) _prewarmStarted = false;
      return;
    }

    if (!mounted || !_prewarmStarted) {
      // Cancelled (seek happened, loop toggled, or widget disposed)
      next.dispose();
      return;
    }

    _nextController = next;

    if (_pendingPlay) {
      _pendingPlay = false;
      await _swapToNextAndPlay();
    }
  }

  /// Hot-swap to the pre-warmed controller and start playing immediately.
  /// The old controller is disposed AFTER the new one starts playing so any
  /// stale platform callbacks (deferred seekTo from completion handler) land
  /// on a dead instance with no side effects.
  Future<void> _swapToNextAndPlay() async {
    final old = _controller;
    old.removeListener(_onControllerUpdate);

    _controller = _nextController!;
    _nextController = null;
    _prewarmStarted = false;
    _pendingPlay = false;
    _prevInitialized = _controller.value.isInitialized;
    _prevError = _controller.value.hasError;
    _prevCompleted = false;

    // Apply current loop state to the new controller
    _controller.setLooping(loopNotifier.value);
    _controller.addListener(_onControllerUpdate);

    // Update notifier → viewer_screen VLB rebinds to new controller instance
    currentController.value = _controller;

    if (mounted) setState(() {});
    await _controller.play();

    // Dispose old after new is live — stale deferred seekTo lands on dead instance
    old.dispose();
  }

  void _cancelPrewarm() {
    _prewarmStarted = false;
    _pendingPlay = false;
    final next = _nextController;
    _nextController = null;
    next?.dispose();
  }

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    _controller.addListener(_onControllerUpdate);
    currentController.value = _controller;
    _controller.initialize().catchError((_) {});
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    // Only setState on init/error transitions — not every frame tick
    final curInit = _controller.value.isInitialized;
    final curErr = _controller.value.hasError;
    if (curInit != _prevInitialized || curErr != _prevError) {
      _prevInitialized = curInit;
      _prevError = curErr;
      setState(() {});
    }

    // Start pre-warming as soon as video completes so replay is instant.
    // Skip if looping — ExoPlayer REPEAT_MODE_ALL never fires STATE_ENDED.
    final curCompleted = _controller.value.isCompleted;
    if (curCompleted && !_prevCompleted && !loopNotifier.value) {
      _startPrewarm();
    }
    _prevCompleted = curCompleted;
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _cancelPrewarm(); // disposes _nextController if non-null
    currentController.dispose();
    loopNotifier.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading media...', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (controller.value.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to play media', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: isAudio ? _buildAudioView(theme) : _buildVideoView(),
    );
  }

  Widget _buildAudioView(ThemeData theme) {
    final size = File(widget.filePath).lengthSync();
    final sizeStr = size < 1024
        ? '$size B'
        : size < 1024 * 1024
            ? '${(size / 1024).toStringAsFixed(1)} KB'
            : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.audiotrack, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            widget.fileName,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            sizeStr,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}
