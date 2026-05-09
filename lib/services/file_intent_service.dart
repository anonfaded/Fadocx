import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

final log = Logger();

/// Service to handle file intents from other apps (Android)
/// When user opens a file with our app from Files app or another app,
/// this service captures and routes to the viewer
class FileIntentService {
  static const _channel = MethodChannel('com.fadseclab.fadocx/file_intent');
  static final _fileIntentController = StreamController<String>.broadcast();
  static bool _initialized = false;

  /// Stream to listen for file intents from other apps
  static Stream<String> get fileIntentStream => _fileIntentController.stream;

  /// Returns true once the service has been initialized
  static bool get isInitialized => _initialized;

  /// Initialize the file intent listener
  /// Call this once at app startup (after stream listener is set up).
  /// 1. Registers a handler for push-based intents from Kotlin (warm start)
  /// 2. Polls for any pending cold-start intent stored by Kotlin
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register handler for push-based intents from Kotlin (e.g. onNewIntent)
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFileIntent') {
        final filePath = call.arguments as String?;
        if (filePath != null && filePath.isNotEmpty) {
          log.i('Push-based file intent received: $filePath');
          _fileIntentController.add(filePath);
        }
      }
      return null;
    });

    // Poll for any cold-start pending intent
    try {
      final result = await _channel.invokeMethod<Map>('getOpenFileIntent');
      if (result != null && result['filePath'] != null) {
        final filePath = result['filePath'] as String;
        log.i('Cold-start file intent: $filePath');
        _fileIntentController.add(filePath);
      }
    } catch (e) {
      log.w('Error initializing file intent service: $e');
    }
  }

  /// Dispose the service
  static void dispose() {
    _channel.setMethodCallHandler(null);
    _fileIntentController.close();
    _initialized = false;
  }
}
