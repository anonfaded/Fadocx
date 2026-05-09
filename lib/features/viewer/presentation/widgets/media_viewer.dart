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
  late final VideoPlayerController controller;
  final ValueNotifier<bool> loopNotifier = ValueNotifier(false);
  bool _loopInProgress = false;

  bool get isAudio => isAudioFormat(widget.filePath);

  void togglePlay() {
    if (controller.value.isPlaying) { controller.pause(); } else { controller.play(); }
  }

  void play() => controller.play();

  void seekTo(Duration d) => controller.seekTo(d);
  void setSpeed(double speed) => controller.setPlaybackSpeed(speed);

  void toggleLoop() {
    loopNotifier.value = !loopNotifier.value;
    if (loopNotifier.value && controller.value.isCompleted && !_loopInProgress) {
      _loopInProgress = true;
      controller.play();
    }
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(File(widget.filePath));
    controller.addListener(_onUpdate);
    controller.initialize().catchError((_) {});
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});

    if (controller.value.isCompleted && loopNotifier.value && !_loopInProgress) {
      _loopInProgress = true;
      controller.play();
    }

    if (_loopInProgress && !controller.value.isCompleted) {
      _loopInProgress = false;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    controller.dispose();
    loopNotifier.dispose();
    super.dispose();
  }

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
          Text(widget.fileName, style: theme.textTheme.titleLarge, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(sizeStr, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
