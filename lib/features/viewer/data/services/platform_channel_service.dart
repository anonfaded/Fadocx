import 'package:flutter/services.dart';
import 'package:fadocx/core/utils/logger.dart';

/// Exception thrown when platform channel communication fails
class PlatformChannelException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  PlatformChannelException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'PlatformChannelException: [$code] $message\nOriginal: $originalError';
}

/// Handles cross-platform communication for native document parsing
/// 
/// This service abstracts the platform channel logic and provides
/// a clean API for calling native parsers on Android/iOS
/// Single source of truth: all parsing done natively when available
abstract class PlatformChannelService {
  /// Parse document file using native platform parser
  /// 
  /// Supports: XLSX, XLS, CSV, DOCX, ODS, JSON, and more
  /// Returns parsed sheets as `Map<String, dynamic>`
  /// Throws PlatformChannelException on platform errors
  Future<Map<String, dynamic>> parseDocumentNative(String filePath, String format);

  /// Check if native Excel parsing is available on this platform
  Future<bool> isNativeParsingAvailable();
}

/// Concrete implementation using Flutter's MethodChannel
class MethodChannelService implements PlatformChannelService {
  static const _channelName = 'com.fadseclab.fadocx/document_parser';
  late final MethodChannel _channel;

  MethodChannelService() {
    _channel = MethodChannel(_channelName);
  }

  @override
  Future<bool> isNativeParsingAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable') ?? false;
      log.i('Native parsing available: $result');
      return result;
    } catch (e) {
      log.w('Failed to check native parsing availability: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> parseDocumentNative(String filePath, String format) async {
    try {
      log.i('Calling native parser for: $filePath (format: $format)');
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'parseDocument',
        {'filePath': filePath, 'format': format},
      );

      if (result == null) {
        throw PlatformChannelException(
          message: 'Native parser returned null',
          code: 'NULL_RESULT',
        );
      }

      // Recursively convert dynamic map to typed map
      final typedResult = _convertDynamicToTyped(result) as Map<String, dynamic>;
      
      log.i('Native parsing completed: ${typedResult['sheetCount']} sheets');
      return typedResult;
    } on PlatformException catch (e) {
      throw PlatformChannelException(
        message: e.message ?? 'Unknown platform error',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw PlatformChannelException(
        message: 'Unexpected error during native parsing',
        originalError: e,
      );
    }
  }

  /// Recursively convert Map with dynamic type params to Map with String keys
  /// and List with dynamic elements with proper type handling
  dynamic _convertDynamicToTyped(dynamic value) {
    if (value is Map) {
      // Convert map keys to String and recursively convert values
      return Map<String, dynamic>.from(
        value.map((key, val) => MapEntry(
          key.toString(),
          _convertDynamicToTyped(val),
        )),
      );
    } else if (value is List) {
      // Recursively convert list elements
      return value.map(_convertDynamicToTyped).toList();
    } else {
      // Return primitive types as-is
      return value;
    }
  }
}
