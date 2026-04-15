/// Base failure class for error handling in domain layer
/// Enables type-safe error handling across the app
abstract class Failure {
  final String message;
  Failure({required this.message});

  @override
  String toString() => 'Failure: $message';
}

/// File not found error
class FileNotFoundFailure extends Failure {
  FileNotFoundFailure({String? filePath})
      : super(message: 'File not found: $filePath');
}

/// Permission denied error
class PermissionDeniedFailure extends Failure {
  PermissionDeniedFailure({String? permission})
      : super(message: 'Permission denied: $permission');
}

/// Unsupported file format error
class UnsupportedFileFormatFailure extends Failure {
  UnsupportedFileFormatFailure({String? fileType})
      : super(message: 'Unsupported file format: $fileType');
}

/// File parsing error (corrupted, invalid, etc.)
class FileParsingFailure extends Failure {
  final String? details;

  FileParsingFailure({this.details, String? fileName})
      : super(message: 'Error parsing file: $fileName\n${details ?? ''}');
}

/// Storage error
class StorageFailure extends Failure {
  StorageFailure({String? details})
      : super(message: 'Storage error: ${details ?? 'Unknown'}');
}

/// Network error (Phase 2+)
class NetworkFailure extends Failure {
  NetworkFailure({String? message})
      : super(message: message ?? 'Network error');
}

/// Sync error (Phase 2+)
class SyncFailure extends Failure {
  SyncFailure({String? message}) : super(message: message ?? 'Sync failed');
}

/// Unknown/generic error
class UnknownFailure extends Failure {
  UnknownFailure({String? message})
      : super(message: message ?? 'Unknown error occurred');
}

/// Result type for Either-like behavior (without external dependency)
/// Success holds data, Failure holds error
abstract class Result<T> {
  const Result();

  /// Execute if success
  R fold<R>(
    R Function(Failure) onFailure,
    R Function(T) onSuccess,
  );

  /// Execute if success, return result
  Future<R> foldAsync<R>(
    Future<R> Function(Failure) onFailure,
    Future<R> Function(T) onSuccess,
  ) async {
    if (this is ResultSuccess<T>) {
      return onSuccess((this as ResultSuccess<T>).data);
    } else {
      return onFailure((this as ResultFailure<T>).failure);
    }
  }

  /// Check if success
  bool get isSuccess => this is ResultSuccess<T>;

  /// Check if failure
  bool get isFailure => this is ResultFailure<T>;
}

/// Success result
class ResultSuccess<T> extends Result<T> {
  final T data;

  const ResultSuccess(this.data);

  @override
  R fold<R>(
    R Function(Failure) onFailure,
    R Function(T) onSuccess,
  ) {
    return onSuccess(data);
  }

  @override
  String toString() => 'ResultSuccess($data)';
}

/// Failure result
class ResultFailure<T> extends Result<T> {
  final Failure failure;

  const ResultFailure(this.failure);

  @override
  R fold<R>(
    R Function(Failure) onFailure,
    R Function(T) onSuccess,
  ) {
    return onFailure(failure);
  }

  @override
  String toString() => 'ResultFailure($failure)';
}
