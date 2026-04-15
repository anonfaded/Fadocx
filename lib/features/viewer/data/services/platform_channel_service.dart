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

/// Handles cross-platform communication for native Excel parsing
/// 
/// This service abstracts the platform channel logic and provides
/// a clean API for calling native Excel parsers on Android/iOS
abstract class PlatformChannelService {
  /// Parse XLSX file using native platform parser
  /// 
  /// Returns parsed sheets as `Map<String, dynamic>`
  /// Throws PlatformChannelException on platform errors
  Future<Map<String, dynamic>> parseExcelNative(String filePath);

  /// Check if native Excel parsing is available on this platform
  Future<bool> isNativeParsingAvailable();
}

/// Concrete implementation using Flutter's MethodChannel
class MethodChannelService implements PlatformChannelService {
  static const _channelName = 'com.fadocx/excel_parser';
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
  Future<Map<String, dynamic>> parseExcelNative(String filePath) async {
    try {
      log.i('Calling native Excel parser for: $filePath');
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'parseExcel',
        {'filePath': filePath},
      );

      if (result == null) {
        throw PlatformChannelException(
          message: 'Native parser returned null',
          code: 'NULL_RESULT',
        );
      }

      // Convert dynamic map to typed map
      final typedResult = Map<String, dynamic>.from(result);
      
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
}
