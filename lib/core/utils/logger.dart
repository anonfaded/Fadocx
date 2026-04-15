import 'package:logger/logger.dart';

/// Global logger instance - use as: log.e(), log.w(), log.i(), log.d(), log.v()
final log = AppLogger();

/// Custom logger with logcat-style formatting and colors
class AppLogger {
  late Logger _logger;

  AppLogger() {
    _logger = Logger(
      printer: _CustomPrinter(),
      level: Level.debug,
    );
  }

  /// ERROR level - Critical errors and exceptions
  void e(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// WARNING level - Unexpected conditions
  void w(dynamic message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  /// INFO level - Important app events
  void i(dynamic message) {
    _logger.i(message);
  }

  /// DEBUG level - Debug information
  void d(dynamic message) {
    _logger.d(message);
  }

  /// VERBOSE level - Detailed tracing (alias for trace)
  void v(dynamic message) {
    _logger.t(message);
  }

  /// TRACE level - Very detailed tracing
  void t(dynamic message) {
    _logger.t(message);
  }
}

/// Custom printer with logcat-style formatting
class _CustomPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final emoji = PrettyPrinter().levelEmojis?[event.level] ?? '';
    final time = DateTime.now().toString().split('.')[0];

    String output = '$emoji $time [${event.level.name.toUpperCase()}]';

    if (event.message != null) {
      output += ' ${event.message}';
    }

    if (event.error != null) {
      output += '\n❌ ERROR: ${event.error}';
    }

    if (event.stackTrace != null) {
      output += '\n${'═' * 80}\n${event.stackTrace}\n${'═' * 80}';
    }

    return [output];
  }
}
