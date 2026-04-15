import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/data/providers/repository_providers.dart';

/// State class for parsed document with loading/error handling
class ParsedDocumentState {
  final ParsedDocumentEntity? document;
  final bool isLoading;
  final String? error;
  final String? parsingStatus;

  const ParsedDocumentState({
    this.document,
    this.isLoading = false,
    this.error,
    this.parsingStatus,
  });

  /// Convenience getters
  bool get hasError => error != null;
  bool get hasData => document != null;

  ParsedDocumentState copyWith({
    ParsedDocumentEntity? document,
    bool? isLoading,
    String? error,
    String? parsingStatus,
  }) {
    return ParsedDocumentState(
      document: document ?? this.document,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      parsingStatus: parsingStatus,
    );
  }
}

/// ViewModel for managing document parsing using modern Riverpod Notifier pattern
class DocumentViewerNotifier extends Notifier<ParsedDocumentState> {
  late String _filePath;
  late String _fileName;

  @override
  ParsedDocumentState build() {
    return const ParsedDocumentState();
  }

  /// Initialize with file path and name, then load document
  Future<void> initializeAndLoad(String filePath, String fileName) async {
    _filePath = filePath;
    _fileName = fileName;
    await loadDocument();
  }

  /// Load and parse the document
  Future<void> loadDocument() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = await ref.read(documentParsingRepositoryProvider.future);
      final extension = _fileName.toLowerCase().split('.').last;

      state = state.copyWith(parsingStatus: 'Loading $extension...');

      ParsedDocumentEntity document;

      switch (extension) {
        case 'xlsx':
          document = await repository.parseXLSX(
            _filePath,
            useNativeParsing: true,
          );
        case 'csv':
          document = await repository.parseCSV(_filePath);
        case 'docx':
          document = await repository.parseDOCX(_filePath);
        default:
          throw Exception('Unsupported file format: $extension');
      }

      state = ParsedDocumentState(
        document: document,
        isLoading: false,
      );

      log.i('Document loaded successfully: $_fileName');
    } catch (e, st) {
      log.e('Error loading document: $e', e, st);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider for document viewing - single instance shared across screens
/// Usage:
/// ```dart
/// final notifier = ref.read(documentViewerProvider.notifier);
/// await notifier.initializeAndLoad(filePath, fileName);
/// final docState = ref.watch(documentViewerProvider);
/// ```
final documentViewerProvider =
    NotifierProvider<DocumentViewerNotifier, ParsedDocumentState>(() {
  return DocumentViewerNotifier();
});
