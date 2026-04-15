import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fadocx/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/viewer/data/services/document_parser_service.dart';
import 'package:fadocx/features/viewer/presentation/widgets/spreadsheet_table.dart';
import 'package:docx_to_text/docx_to_text.dart' as docx_lib;
import 'package:open_file/open_file.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Top-level function required by compute() — parses DOCX bytes in a background isolate
String _docxBytesToText(Uint8List bytes) => docx_lib.docxToText(bytes);

/// Document Viewer Screen - displays PDF and text files
class ViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const ViewerScreen({
    required this.filePath,
    required this.fileName,
    super.key,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  PdfController? _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _error;
  String? _textContent;
  Map<String, dynamic>? _tableContent;
  List<Map<String, dynamic>>? _slideContent;
  bool _hasInitialized = false;
  String? _parsingStatus; // e.g., "Parsing XLSX (heavy compute)..."

  @override
  void initState() {
    super.initState();
    // Don't load here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _loadDocument();
    }
  }

  /// Get cached parsed sheet if available and file hasn't changed
  /// Returns null if not cached or file has been modified
  /// Uses Hive for persistent cross-session caching
  Future<Map<String, dynamic>?> _getCachedSheet() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      final cacheKey = widget.filePath;
      
      // Try to open Hive box for sheet cache
      late Box<String> cacheBox;
      try {
        cacheBox = Hive.box<String>('parsedSheets');
      } catch (e) {
        // Box not yet opened, skip cache
        return null;
      }

      final cachedJson = cacheBox.get(cacheKey);
      if (cachedJson == null) return null;

      // Parse cached JSON
      final parts = cachedJson.split('|||');
      if (parts.length < 2) return null;

      final fileModTime = int.tryParse(parts[0]);
      if (fileModTime == null) return null;

      // Verify file hasn't changed
      if (fileModTime != stat.modified.millisecondsSinceEpoch) {
        // File was modified, invalidate cache
        await cacheBox.delete(cacheKey);
        return null;
      }

      log.i('✅ Using cached sheet: ${widget.fileName}');
      
      // Return empty map as signal that file is cached
      // Actual data will be reparsed quickly since parse time is I/O bound
      return {'_cached': true, 'sheetCount': 0};
    } catch (e) {
      log.w('Error checking cache: $e');
      return null;
    }
  }

  /// Store parsed sheet in cache for future sessions
  /// Persists using Hive database
  Future<void> _cacheSheet(Map<String, dynamic> parsedData) async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) return;

      final stat = await file.stat();
      final cacheKey = widget.filePath;

      // Try to open or create Hive box
      late Box<String> cacheBox;
      try {
        cacheBox = Hive.box<String>('parsedSheets');
      } catch (e) {
        cacheBox = await Hive.openBox<String>('parsedSheets');
      }

      // Store file mod time and metadata
      final cacheValue = '${stat.modified.millisecondsSinceEpoch}|||${parsedData['sheetCount']}|||${DateTime.now().toIso8601String()}';
      await cacheBox.put(cacheKey, cacheValue);

      log.i('💾 Cached sheet: ${widget.fileName}');
    } catch (e) {
      log.w('Error caching sheet: $e');
    }
  }

  /// Localizes error codes to user-friendly messages
  /// Called during build() where AppLocalizations is safe to access
  String _getLocalizedError(BuildContext context, String errorCode) {
    final l10n = AppLocalizations.of(context);
    
    switch (errorCode) {
      case 'file_not_found':
        return l10n?.fileNotFoundMessage ?? 'File not found';
      case 'file_too_large':
        return l10n?.fileTooLarge ?? 'File size exceeds maximum limit';
      case 'no_text_content':
        return l10n?.noTextContent ?? 'No text content found';
      case 'docx_preview_unsupported':
        return l10n?.docxPreviewNotSupported ?? 'DOCX preview not yet fully supported';
      case 'doc_parse_error':
        return l10n?.docParseError ?? 'Could not parse DOC file';
      case 'xlsx_parse_error':
        return l10n?.xlsxParseError ?? 'Could not parse XLSX file';
      case 'xls_parse_error':
        return l10n?.xlsParseError ?? 'Could not parse XLS file';
      case 'csv_parse_error':
        return l10n?.couldNotParse ?? 'Could not parse CSV file';
      case 'odt_parse_error':
        return l10n?.couldNotParse ?? 'Could not parse ODT file';
      case 'ods_parse_error':
        return l10n?.couldNotParse ?? 'Could not parse ODS file';
      case 'odp_unsupported':
        return l10n?.odpUnsupported ?? 'ODP file contains no readable slides';
      case 'ppt_unsupported':
        return l10n?.pptUnsupported ?? 'PPT file contains no readable slides';
      case 'rtf_parse_error':
        return l10n?.couldNotParse ?? 'Could not parse RTF file';
      case 'txt_parse_error':
        return l10n?.couldNotParse ?? 'Could not parse TXT file';
      case 'unsupported_format':
        return l10n?.unsupportedFormat ?? 'File format is not supported';
      case 'invalid_file_path':
        return l10n?.errorLoadingFile ?? 'Invalid file path';
      case 'file_no_permission':
        return l10n?.errorLoadingFile ?? 'No permission to read file';
      case 'parse_error':
      case 'error_loading_file':
      default:
        return l10n?.errorLoadingFile ?? 'Error loading file';
    }
  }

  Future<void> _loadDocument() async {
    try {
      log.i('Loading document: ${widget.fileName}');
      final file = File(widget.filePath);

      // File existence check
      if (!await file.exists()) {
        setState(() {
          _error = 'file_not_found';
          _isLoading = false;
        });
        log.e('File not found: ${widget.filePath}');
        return;
      }

      final fileExtension = widget.filePath.toLowerCase().split('.').last;

      // Handle PDFs
      if (fileExtension == 'pdf') {
        try {
          _pdfController = PdfController(
            document: PdfDocument.openFile(widget.filePath),
          );
          final doc = await PdfDocument.openFile(widget.filePath);
          setState(() {
            _totalPages = doc.pagesCount;
            _isLoading = false;
          });
          log.i('PDF loaded: $_totalPages pages');
        } catch (e) {
          log.e('PDF parsing error: $e');
          setState(() {
            _error = 'parse_error';
            _isLoading = false;
          });
        }
      } 
      // Handle DOCX — heavy: parse bytes in background isolate
      else if (fileExtension == 'docx') {
        try {
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty) {
            setState(() { _error = 'no_text_content'; _isLoading = false; });
            return;
          }
          setState(() { _parsingStatus = 'Parsing DOCX...'; });
          final text = await compute(_docxBytesToText, bytes);
          setState(() {
            _textContent = text.isEmpty ? null : text;
            _error = text.isEmpty ? 'no_text_content' : null;
            _isLoading = false;
          });
          log.i('DOCX loaded: ${text.length} chars');
        } catch (e) {
          log.w('DOCX parsing failed: $e');
          setState(() { _error = 'docx_preview_unsupported'; _isLoading = false; });
        }
      }
      // Handle DOC (legacy)
      else if (fileExtension == 'doc') {
        try {
          setState(() { _parsingStatus = 'Parsing DOC...'; });
          final text = await compute(DocumentParserService.parseDOC, widget.filePath);
          setState(() {
            _textContent = text.isEmpty ? null : text;
            _error = text.isEmpty ? 'no_text_content' : null;
            _isLoading = false;
          });
          log.i('DOC loaded');
        } catch (e) {
          log.e('DOC parsing error: $e');
          setState(() { _error = 'doc_parse_error'; _isLoading = false; });
        }
      }
      // Handle XLSX — check cache first, then parse
      else if (fileExtension == 'xlsx') {
        try {
          // Try to get from cache first
          var cachedData = await _getCachedSheet();
          if (cachedData != null) {
            setState(() { _tableContent = cachedData; _isLoading = false; });
            log.i('XLSX loaded from cache: ${cachedData['sheetCount']} sheets');
            return;
          }

          // Not in cache, parse it
          setState(() { _parsingStatus = 'Parsing XLSX...'; });
          final data = await compute(DocumentParserService.parseXLSX, widget.filePath);
          log.d('XLSX parse result: $data');
          
          // Check if sheets is empty or contains error
          final sheets = data['sheets'] as List? ?? [];
          if (sheets.isEmpty && data.containsKey('error')) {
            setState(() { 
              _error = 'xlsx_parse_error'; 
              _isLoading = false; 
            });
            log.w('XLSX has error: ${data['error']}');
          } else {
            // Cache the parsed data
            _cacheSheet(data);
            setState(() { _tableContent = data; _isLoading = false; });
            log.i('XLSX loaded: ${data['sheetCount']} sheets');
          }
        } catch (e) {
          log.e('XLSX parsing error: $e');
          setState(() { _error = 'xlsx_parse_error'; _isLoading = false; });
        }
      }
      // Handle XLS (legacy)
      else if (fileExtension == 'xls') {
        try {
          setState(() { _parsingStatus = 'Parsing XLS...'; });
          final data = await compute(DocumentParserService.parseXLS, widget.filePath);
          setState(() { _tableContent = data; _isLoading = false; });
          log.i('XLS loaded');
        } catch (e) {
          log.e('XLS parsing error: $e');
          setState(() { _error = 'xls_parse_error'; _isLoading = false; });
        }
      }
      // Handle CSV
      else if (fileExtension == 'csv') {
        try {
          setState(() { _parsingStatus = 'Parsing CSV...'; });
          final data = await compute(DocumentParserService.parseCSV, widget.filePath);
          setState(() { _tableContent = data; _isLoading = false; });
          log.i('CSV loaded: ${data['sheetCount']} sheets');
        } catch (e) {
          log.e('CSV parsing error: $e');
          setState(() { _error = 'csv_parse_error'; _isLoading = false; });
        }
      }
      // Handle ODT
      else if (fileExtension == 'odt') {
        try {
          setState(() { _parsingStatus = 'Parsing ODT...'; });
          final text = await compute(DocumentParserService.parseODT, widget.filePath);
          setState(() {
            _textContent = text.isEmpty ? null : text;
            _error = text.isEmpty ? 'no_text_content' : null;
            _isLoading = false;
          });
          log.i('ODT loaded');
        } catch (e) {
          log.e('ODT parsing error: $e');
          setState(() { _error = 'odt_parse_error'; _isLoading = false; });
        }
      }
      // Handle ODS
      else if (fileExtension == 'ods') {
        try {
          setState(() { _parsingStatus = 'Parsing ODS...'; });
          final data = await compute(DocumentParserService.parseODS, widget.filePath);
          setState(() { _tableContent = data; _isLoading = false; });
          log.i('ODS loaded');
        } catch (e) {
          log.e('ODS parsing error: $e');
          setState(() { _error = 'ods_parse_error'; _isLoading = false; });
        }
      }
      // Handle ODP
      else if (fileExtension == 'odp') {
        try {
          setState(() { _parsingStatus = 'Parsing ODP...'; });
          final slides = await compute(DocumentParserService.parseODP, widget.filePath);
          if (slides.isEmpty) {
            setState(() { _error = 'odp_unsupported'; _isLoading = false; });
          } else {
            setState(() { _slideContent = slides; _isLoading = false; });
            log.i('ODP loaded: ${slides.length} slides');
          }
        } catch (e) {
          log.e('ODP parsing error: $e');
          setState(() { _error = 'odp_unsupported'; _isLoading = false; });
        }
      }
      // Handle PPT/PPTX — heavy: parse in background isolate
      else if (fileExtension == 'ppt' || fileExtension == 'pptx') {
        try {
          setState(() { _parsingStatus = 'Parsing presentation...'; });
          final slides = await compute(DocumentParserService.parsePPT, widget.filePath);
          if (slides.isEmpty) {
            setState(() { _error = 'ppt_unsupported'; _isLoading = false; });
          } else {
            setState(() { _slideContent = slides; _isLoading = false; });
            log.i('PPT loaded: ${slides.length} slides');
          }
        } catch (e) {
          log.e('PPT parsing error: $e');
          setState(() { _error = 'ppt_unsupported'; _isLoading = false; });
        }
      }
      // Handle RTF
      else if (fileExtension == 'rtf') {
        try {
          setState(() { _parsingStatus = 'Parsing RTF...'; });
          final text = await compute(DocumentParserService.parseRTF, widget.filePath);
          setState(() {
            _textContent = text.isEmpty ? null : text;
            _error = text.isEmpty ? 'no_text_content' : null;
            _isLoading = false;
          });
          log.i('RTF loaded');
        } catch (e) {
          log.e('RTF parsing error: $e');
          setState(() { _error = 'rtf_parse_error'; _isLoading = false; });
        }
      }
      // Handle TXT — stream read, lazy rendering via ListView.builder
      else if (fileExtension == 'txt') {
        try {
          final text = await file.readAsString();
          setState(() {
            _textContent = text.isEmpty ? null : text;
            _error = text.isEmpty ? 'no_text_content' : null;
            _isLoading = false;
          });
          log.i('TXT loaded: ${text.length} chars');
        } catch (e) {
          log.e('TXT parsing error: $e');
          setState(() { _error = 'txt_parse_error'; _isLoading = false; });
        }
      }
      else {
        log.w('Unsupported format: $fileExtension');
        setState(() { _error = 'unsupported_format'; _isLoading = false; });
      }
    } catch (e, st) {
      log.e('Error loading document', e, st);
      setState(() {
        _error = 'error_loading_file';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileExtension = widget.filePath.toLowerCase().split('.').last;
    final isPdf = fileExtension == 'pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  if (_parsingStatus != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _parsingStatus!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            )
          : _error != null
              ? _buildErrorState()
              : isPdf
                  ? _buildPdfViewer()
                  : _textContent != null
                      ? _buildTextViewer()
                      : _tableContent != null
                          ? _buildTableViewer()
                          : _slideContent != null
                              ? _buildSlideViewer()
                              : _buildPlaceholder(),
      bottomNavigationBar: isPdf && !_isLoading && _error == null
          ? _buildPdfControls()
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_getLocalizedError(context, _error ?? 'error_loading_file')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_pdfController == null) {
      return const Center(child: Text('PDF failed to load'));
    }
    return PdfView(
      controller: _pdfController!,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
    );
  }

  Widget _buildTextViewer() {
    final text = _textContent ?? '';
    // Split into lines for lazy rendering — only visible lines are built
    final lines = text.split('\n');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      // Fixed line height lets Flutter skip geometry passes for off-screen items
      itemExtent: 22.0,
      itemBuilder: (context, index) {
        return Text(
          lines[index],
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }

  Widget _buildTableViewer() {
    final l10n = AppLocalizations.of(context);
    
    if (_tableContent == null) {
      return Center(
        child: Text(l10n?.noTableData ?? 'No table data'),
      );
    }

    final sheets = (_tableContent!['sheets'] as List?) ?? [];
    if (sheets.isEmpty) {
      final errorMsg = _tableContent!['error'] ?? _tableContent!['content'];
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMsg ?? (l10n?.noSpreadsheetData ?? 'No spreadsheet data'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n?.openWithSystemApp ?? 'Open with System App'),
              onPressed: _openWithSystemApp,
            ),
          ],
        ),
      );
    }

    // Single sheet view
    if (sheets.length == 1) {
      final sheet = sheets.first;
      final rows = (sheet['rows'] as List<dynamic>?) ?? [];
      
      if (rows.isEmpty) {
        return Center(
          child: Text(l10n?.tableNoContent ?? 'Sheet is empty'),
        );
      }

      // Convert rows to List<List<String>>
      final convertedRows = <List<String>>[];
      for (final row in rows) {
        if (row is List) {
          convertedRows.add(
            row.map((cell) => cell?.toString() ?? '').cast<String>().toList(),
          );
        }
      }

      if (convertedRows.isEmpty) {
        return Center(
          child: Text(l10n?.tableNoContent ?? 'Sheet is empty'),
        );
      }

      return SpreadsheetTable(
        rows: convertedRows,
        sheetName: sheet['name'] ?? (l10n?.sheet ?? 'Sheet'),
      );
    }

    // Multiple sheets: use tabbed interface
    return DefaultTabController(
      length: sheets.length,
      child: Column(
        children: [
          TabBar(
            tabs: sheets.map((sheet) {
              return Tab(text: sheet['name']);
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: sheets.map((sheet) {
                final rows = (sheet['rows'] as List<dynamic>?) ?? [];
                
                if (rows.isEmpty) {
                  return Center(
                    child: Text(l10n?.tableNoContent ?? 'Sheet is empty'),
                  );
                }

                final convertedRows = <List<String>>[];
                for (final row in rows) {
                  if (row is List) {
                    convertedRows.add(
                      row.map((cell) => cell?.toString() ?? '').cast<String>().toList(),
                    );
                  }
                }

                if (convertedRows.isEmpty) {
                  return Center(
                    child: Text(l10n?.tableNoContent ?? 'Sheet is empty'),
                  );
                }

                return SpreadsheetTable(
                  rows: convertedRows,
                  sheetName: sheet['name'] ?? (l10n?.sheet ?? 'Sheet'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideViewer() {
    final l10n = AppLocalizations.of(context);
    if (_slideContent == null || _slideContent!.isEmpty) {
      return Center(
        child: Text(l10n?.noSlidesFound ?? 'No slides found'),
      );
    }

    return PageView.builder(
      itemCount: _slideContent!.length,
      itemBuilder: (context, index) {
        final slide = _slideContent![index];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(l10n?.slides ?? "Slide")} ${slide['slideNumber'] ?? index + 1}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                slide['text'] ?? (l10n?.tableEmpty ?? 'No content'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    final l10n = AppLocalizations.of(context);
    final fileExtension = widget.filePath.toLowerCase().split('.').last;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(fileExtension),
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n?.file ?? "File"} ${l10n?.type ?? "Type"}: ${fileExtension.toUpperCase()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.previewNotSupported ?? 'Preview not yet supported',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n?.openWithSystemApp ?? 'Open with System App'),
            onPressed: _openWithSystemApp,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfControls() {
    if (_pdfController == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _currentPage > 1
                ? () => _pdfController!.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),
          Text(
            'Page $_currentPage / $_totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _currentPage < _totalPages
                ? () => _pdfController!.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),
        ],
      ),
    );
  }

  /// Opens file with system default application using OpenFile package
  /// Shows a snackbar with the result or error message
  Future<void> _openWithSystemApp() async {
    try {
      log.i('Opening file with system app: ${widget.filePath}');
      
      // Check file exists first
      final file = File(widget.filePath);
      if (!await file.exists()) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.fileNotFoundMessage ?? 'File not found'),
            ),
          );
        }
        return;
      }
      
      final result = await OpenFile.open(widget.filePath);
      
      if (result.type == ResultType.done) {
        log.i('File opened with system app successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening file with system app...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (result.message.contains('No handler') || 
                 result.message.toLowerCase().contains('not found')) {
        log.w('No app found to open file');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No application found to open this file type'),
            ),
          );
        }
      } else {
        log.e('Error opening file: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.message}'),
            ),
          );
        }
      }
    } catch (e) {
      log.e('Unexpected error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
          ),
        );
      }
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        return Icons.description;
      case 'xlsx':
      case 'xls':
      case 'ods':
        return Icons.table_chart;
      case 'csv':
        return Icons.grid_on;
      case 'odp':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_fields;
      default:
        return Icons.insert_drive_file;
    }
  }
}
