import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fadocx/core/utils/logger.dart';

/// Service to handle file intents from other apps (Android)
/// When user opens a file with our app from Files app or another app,
/// this service captures and routes to the viewer
class FileIntentService {
  static const _channel = MethodChannel('com.fadseclab.fadocx/file_intent');
  static final _fileIntentController = StreamController<String>.broadcast();

  /// Stream to listen for file intents from other apps
  static Stream<String> get fileIntentStream => _fileIntentController.stream;

  /// Initialize the file intent listener
  static Future<void> initialize() async {
    try {
      // Get any pending file intent from app startup
      final result = await _channel.invokeMethod<Map>('getOpenFileIntent');
      
      if (result != null && result['filePath'] != null) {
        final filePath = result['filePath'] as String;
        log.i('Initial file intent at app start: $filePath');
        _fileIntentController.add(filePath);
      }
    } catch (e) {
      log.w('Error initializing file intent service: $e');
    }
  }

  /// Dispose the service
  static void dispose() {
    _fileIntentController.close();
  }
}
