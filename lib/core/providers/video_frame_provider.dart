import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../services/video_frame_extractor.dart';

/// Async provider for caching extracted video frame bytes
/// Automatically extracts and caches first frame via VideoFrameExtractor
final videoFrameProvider = FutureProvider.family<Uint8List?, String>(
  (ref, filePath) async {
    return VideoFrameExtractor.extractFrame(filePath);
  },
);
