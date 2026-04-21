import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/core/services/storage_service.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/data/providers/repository_providers.dart';

final log = Logger();

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
  String _filePath = '';
  String _fileName = '';

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
    if (_filePath.isEmpty) {
      log.e('loadDocument called before initializeAndLoad');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(documentParsingRepositoryProvider);
      // Use filePath for extension detection (more reliable than display name)
      final extension =
          _extractExtension(_filePath) ?? _extractExtension(_fileName) ?? '';

      state = state.copyWith(parsingStatus: 'Loading $extension...');

      ParsedDocumentEntity document;

      // Route to appropriate parser based on file extension
      // Must match all formats supported in DocumentParsingRepositoryImpl
      switch (extension) {
        // Spreadsheet formats
        case 'xlsx':
        case 'xls':
          log.d('Routing to parseXLSX for: $extension');
          document = await repository.parseXLSX(
            _filePath,
            useNativeParsing: true,
          );
        case 'csv':
          log.d('Routing to parseCSV');
          document = await repository.parseCSV(_filePath);
        case 'ods':
          log.d('Routing to parseODS');
          document = await repository.parseODS(_filePath);

        // Data formats
        case 'json':
          log.d('Routing to parseJSON');
          document = await repository.parseJSON(_filePath);
        case 'fadrec':
          log.d('Routing to parseFadrec');
          document = await repository.parseFadrec(_filePath);
        case 'xml':
          log.d('Routing to parseXML');
          document = await repository.parseXML(_filePath);

        // Document formats
        case 'docx':
          log.d('Routing to parseDOCX');
          document = await repository.parseDOCX(_filePath);
        case 'doc':
          log.d('Routing to parseDOC');
          document = await repository.parseDOC(_filePath);

        // Presentation formats (PPT, PPTX, ODP - all require LibreOffice, Coming Soon)
        case 'ppt':
        case 'pptx':
        case 'odp':
          log.d('Routing to parsePPT');
          document = await repository.parsePPT(_filePath);

        case 'pdf':
          log.d('Routing to PDF viewer');
          document = ParsedDocumentEntity(
            format: 'PDF',
            sheets: const [],
            sheetCount: 0,
            parsedAt: DateTime.now(),
            sourceFilePath: _filePath,
          );

        default:
          log.e(
              'Unsupported file format received: "$extension" (path: $_filePath)');
          throw Exception(
              'Unsupported file format: ${extension.isEmpty ? '(no extension)' : extension}');
      }

      state = ParsedDocumentState(
        document: document,
        isLoading: false,
      );

      log.i(
          'Document loaded successfully: $_fileName (format: ${document.format})');

      // Auto-cache document to fadocx_docs folder
      try {
        await StorageService.cacheDocument(_filePath, _fileName);
        log.i('Document cached: $_fileName');
      } catch (e) {
        log.w('Failed to cache document: $e');
      }
    } catch (e, st) {
      log.e('Error loading document: $e', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Extract file extension from a path or filename, returns null if none found
  String? _extractExtension(String path) {
    if (path.isEmpty) return null;
    final name = path.split('/').last;
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx == -1 || dotIdx == name.length - 1) return null;
    final ext = name.substring(dotIdx + 1).toLowerCase();
    return ext.isEmpty ? null : ext;
  }
}

/// Provider for document viewing - autoDispose so state resets on each viewer screen
/// Usage:
/// ```dart
/// final notifier = ref.read(documentViewerProvider.notifier);
/// await notifier.initializeAndLoad(filePath, fileName);
/// final docState = ref.watch(documentViewerProvider);
/// ```
final documentViewerProvider =
    NotifierProvider.autoDispose<DocumentViewerNotifier, ParsedDocumentState>(
        () {
  return DocumentViewerNotifier();
});
