import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:logger/logger.dart';

final log = Logger();

/// Service to parse and extract data from various document formats
class DocumentParserService {
  /// Parse XLS format (legacy Excel)
  /// Returns a simplified table structure as map
  static Future<Map<String, dynamic>> parseXLS(String filePath) async {
    try {
      log.i('Parsing XLS file: $filePath');

      // XLS is a complex binary format - native parser on Android handles this
      // For Dart fallback, we can only extract basic info
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      // Basic check for OLE2 compound file signature
      if (fileBytes.length >= 8) {
        final signature = String.fromCharCodes(fileBytes.take(8));
        if (signature == '\u00D0\u00CF\u0011\u00E0\u00A1\u00B1\u001A') {
          log.i('Valid OLE2 compound file detected for XLS');
          return {
            'sheets': [],
            'format': 'XLS',
            'note':
                'Native parser required for full XLS support. Basic structure detected.',
          };
        }
      }

      throw Exception('Invalid or unsupported XLS file format');
    } catch (e, st) {
      log.e('Error parsing XLS', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse XLSX format (modern Excel)
  ///
  /// XLSX is fully handled by the native Android parser via Apache POI
  /// (platform channel: PlatformChannelService.parseDocument).
  /// This stub exists only so call-sites compile on all platforms — it always
  /// throws [UnsupportedError] to force callers onto the native path.
  static Future<Map<String, dynamic>> parseXLSX(String filePath) async {
    log.w('Dart-side parseXLSX stub called for $filePath — use native parser');
    throw UnsupportedError(
      'XLSX parsing requires the native Android parser. '
      'Use PlatformChannelService.parseDocument() for XLSX files.',
    );
  }

  /// Parse CSV format
  /// Returns a single sheet structure
  static Future<Map<String, dynamic>> parseCSV(String filePath) async {
    try {
      log.i('Parsing CSV file: $filePath');
      final file = File(filePath);
      final content = await file.readAsString();

      // Simple CSV parsing - split by newlines and commas
      final lines = content.split('\n');
      final rows = <List<String>>[];

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        // Handle basic CSV parsing (quoted fields, escaped commas)
        final cells = <String>[];
        var currentCell = StringBuffer();
        var inQuotes = false;

        for (int i = 0; i < line.length; i++) {
          final char = line[i];

          if (char == '"') {
            inQuotes = !inQuotes;
          } else if (char == ',' && !inQuotes) {
            cells.add(currentCell.toString().trim());
            currentCell.clear();
          } else {
            currentCell.write(char);
          }
        }

        // Add last cell
        if (currentCell.isNotEmpty) {
          cells.add(currentCell.toString().trim());
        }

        if (cells.isNotEmpty) {
          rows.add(cells);
        }
      }

      return {
        'sheets': [
          {
            'name': 'Sheet1',
            'rows': rows,
            'rowCount': rows.length,
            'colCount': rows.isNotEmpty ? rows.first.length : 0,
          }
        ],
        'format': 'CSV',
        'sheetCount': 1,
      };
    } catch (e, st) {
      log.e('Error parsing CSV', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse ODT format (OpenDocument Text)
  /// Returns text content
  static Future<String> parseODT(String filePath) async {
    try {
      log.i('Parsing ODT file: $filePath');
      return await _parseOpenDocumentFormat(filePath, 'ODT');
    } catch (e, st) {
      log.e('Error parsing ODT', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse ODS format (OpenDocument Spreadsheet)
  /// Returns table structure
  static Future<Map<String, dynamic>> parseODS(
    String filePath, {
    int? maxRowsPerSheet,
    int? maxCols,
    int? maxSheets,
  }) async {
    try {
      log.i('Parsing ODS file: $filePath');
      return await _parseOpenDocumentSpreadsheet(
        filePath,
        maxRowsPerSheet: maxRowsPerSheet,
        maxCols: maxCols,
        maxSheets: maxSheets,
      );
    } catch (e, st) {
      log.e('Error parsing ODS', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse ODP format (OpenDocument Presentation)
  /// Returns slides data
  static Future<List<Map<String, dynamic>>> parseODP(String filePath) async {
    try {
      log.i('Parsing ODP file: $filePath');
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final slides = <Map<String, dynamic>>[];

      // ODP contains slides as XML files
      for (var i = 1;; i++) {
        final slideFile = archive.findFile('ppt/slides/slide$i.xml');
        if (slideFile == null) break;

        try {
          final slideXml = utf8.decode(slideFile.content as List<int>);
          final document = XmlDocument.parse(slideXml);

          // Extract text from slide
          final texts = <String>[];
          for (var elem in document.findAllElements('a:t')) {
            texts.add(elem.innerText);
          }

          slides.add({
            'slideNumber': i,
            'text': texts.join('\n'),
          });
          log.d('Parsed ODP slide $i');
        } catch (e) {
          log.w('Could not parse ODP slide $i: $e');
        }
      }

      log.i('ODP parsed: ${slides.length} slides');
      return slides;
    } catch (e, st) {
      log.e('Error parsing ODP', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse RTF format (Rich Text Format)
  /// Returns plain text (formatting stripped)
  static Future<String> parseRTF(String filePath) async {
    try {
      log.i('Parsing RTF file: $filePath');
      final file = File(filePath);
      final content = await file.readAsString();

      // Simple RTF text extraction - remove RTF control codes
      String text = content;

      // Remove RTF header
      text = text.replaceFirst(RegExp(r'^\{\\rtf1[^}]*\}'), '');

      // Remove control words and symbols
      text = text.replaceAll(RegExp(r'\\[a-z]+\d*\s?'), '');
      text = text.replaceAll(RegExp(r'\\[^a-z]'), '');
      text = text.replaceAll(RegExp(r'\{|\}'), '');

      // Clean up extra whitespace
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      log.i('RTF extracted: ${text.length} characters');
      return text;
    } catch (e, st) {
      log.e('Error parsing RTF', error: e, stackTrace: st);
      rethrow;
    }
  }

  // Helper: Parse generic ODF text format (ODT)
  static Future<String> _parseOpenDocumentFormat(
    String filePath,
    String format,
  ) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // ODF files are ZIP archives containing XML
      final contentFile = archive.findFile('content.xml');
      if (contentFile == null) {
        throw Exception('content.xml not found in $format file');
      }

      final xmlContent = utf8.decode(contentFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);

      // Extract all text nodes
      final texts = <String>[];
      for (var elem in document.findAllElements('text:p')) {
        texts.add(elem.innerText);
      }

      log.i('$format parsed: ${texts.join().length} characters');
      return texts.join('\n');
    } catch (e) {
      log.e('Error parsing ODF format $format: $e');
      rethrow;
    }
  }

  // Helper: Parse ODS (spreadsheet)
  static Future<Map<String, dynamic>> _parseOpenDocumentSpreadsheet(
    String filePath, {
    int? maxRowsPerSheet,
    int? maxCols,
    int? maxSheets,
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final contentFile = archive.findFile('content.xml');
      if (contentFile == null) {
        throw Exception('content.xml not found in ODS file');
      }

      final xmlContent = utf8.decode(contentFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);

      final sheets = <Map<String, dynamic>>[];
      final rowLimit = maxRowsPerSheet ?? 1 << 30;
      final colLimit = maxCols ?? 1 << 30;
      final sheetLimit = maxSheets ?? 1 << 30;

      // Parse each table (sheet)
      for (var table in document.findAllElements('table:table')) {
        if (sheets.length >= sheetLimit) {
          break;
        }

        final sheetName =
            table.getAttribute('table:name') ?? 'Sheet${sheets.length + 1}';
        final rows = <List<String>>[];

        // Parse rows
        for (var row in table.findAllElements('table:table-row')) {
          if (rows.length >= rowLimit) {
            break;
          }

          final rowRepeat =
              int.tryParse(row.getAttribute('table:number-rows-repeated') ?? '') ??
              1;
          final cells = <String>[];

          for (var cell in row.findElements('table:table-cell')) {
            final cellText = cell.innerText.trim();
            final cellRepeat =
                int.tryParse(
                      cell.getAttribute('table:number-columns-repeated') ?? '',
                    ) ??
                    1;

            for (var repeatIndex = 0;
                repeatIndex < cellRepeat && cells.length < colLimit;
                repeatIndex++) {
              cells.add(cellText);
            }

            if (cells.length >= colLimit) {
              break;
            }
          }

          if (cells.any((cell) => cell.isNotEmpty)) {
            for (var repeatIndex = 0;
                repeatIndex < rowRepeat && rows.length < rowLimit;
                repeatIndex++) {
              rows.add(List<String>.from(cells));
            }
          } else if (rows.isEmpty) {
            // Preserve an initial empty row for empty-sheet previews.
            rows.add(cells);
          }
        }

        sheets.add({
          'name': sheetName,
          'rows': rows,
          'rowCount': rows.length,
          'colCount': rows.isNotEmpty ? rows.first.length : 0,
        });
      }

      log.i('ODS parsed: ${sheets.length} sheets');
      return {
        'sheets': sheets,
        'format': 'ODS',
      };
    } catch (e) {
      log.e('Error parsing ODS: $e');
      rethrow;
    }
  }

  // Helper: Extract text from binary data
  static String _extractTextFromBytes(List<int> bytes) {
    final buffer = StringBuffer();

    // Simple binary text extraction - looks for readable ASCII sequences
    var currentWord = StringBuffer();

    for (final byte in bytes) {
      if (byte >= 32 && byte < 127) {
        // Printable ASCII
        currentWord.writeCharCode(byte);
      } else {
        if (currentWord.length > 4) {
          // Only include words with length > 4 to avoid artifacts
          buffer.write(currentWord.toString());
          buffer.write('\n');
        }
        currentWord.clear();
      }
    }

    if (currentWord.length > 4) {
      buffer.write(currentWord.toString());
    }

    return buffer.toString();
  }

  /// Parse PPT format (PowerPoint)
  /// Returns slides data similar to ODP
  static Future<List<Map<String, dynamic>>> parsePPT(String filePath) async {
    try {
      log.i('Parsing PPT file: $filePath');
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      try {
        // Try new format (PPTX)
        return await _parsePPTX(bytes);
      } catch (e) {
        log.i('PPT is old format, extracting text from binary: $e');
        // Fall back to binary text extraction for old PPT format
        final text = _extractTextFromBytes(bytes);
        return [
          {
            'slideNumber': 1,
            'text':
                text.isEmpty ? 'Could not extract text from PPT file' : text,
          }
        ];
      }
    } catch (e, st) {
      log.e('Error parsing PPT', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse PPTX format (Modern PowerPoint - essentially same as ODP internally)
  static Future<List<Map<String, dynamic>>> _parsePPTX(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final slides = <Map<String, dynamic>>[];

      // PPTX contains slides in ppt/slides/ directory
      for (var i = 1;; i++) {
        final slideFile = archive.findFile('ppt/slides/slide$i.xml');
        if (slideFile == null) break;

        try {
          final slideXml = utf8.decode(slideFile.content as List<int>);
          final document = XmlDocument.parse(slideXml);

          // Extract text from slide
          final texts = <String>[];
          for (var elem in document.findAllElements('a:t')) {
            final text = elem.innerText.trim();
            if (text.isNotEmpty) {
              texts.add(text);
            }
          }

          slides.add({
            'slideNumber': i,
            'text': texts.isEmpty ? '[Slide $i - no text]' : texts.join('\n'),
          });
          log.d('Parsed PPTX slide $i');
        } catch (e) {
          log.w('Could not parse PPTX slide $i: $e');
        }
      }

      if (slides.isEmpty) {
        throw Exception('No slides found in PPTX');
      }

      log.i('PPTX parsed: ${slides.length} slides');
      return slides;
    } catch (e) {
      log.w('PPTX parsing failed: $e');
      rethrow;
    }
  }

  /// Parse DOCX format (Modern Word)
  /// Returns text content as string
  static Future<String> parseDOCX(String filePath) async {
    try {
      log.i('Parsing DOCX file: $filePath');
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // DOCX files are ZIP archives containing XML
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentFile = archive.findFile('word/document.xml');

      if (documentFile == null) {
        throw Exception('word/document.xml not found in DOCX file');
      }

      final xmlContent = utf8.decode(documentFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);

      // Extract all text nodes from paragraphs and runs
      final texts = <String>[];
      for (var elem in document.findAllElements('w:p')) {
        final pText = elem.innerText.trim();
        if (pText.isNotEmpty) {
          texts.add(pText);
        }
      }

      log.i('DOCX extracted: ${texts.join().length} characters');
      return texts.join('\n');
    } catch (e, st) {
      log.e('Error parsing DOCX', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse JSON format - converts to tabular representation
  /// Returns sheets with data as rows
  static Future<Map<String, dynamic>> parseJSON(String filePath) async {
    try {
      log.i('Parsing JSON file: $filePath');
      final file = File(filePath);
      final content = await file.readAsString();

      final jsonData = jsonDecode(content);

      // Convert JSON to tabular format
      if (jsonData is List) {
        // Array of objects → table
        if (jsonData.isEmpty) {
          return {
            'sheets': [],
            'format': 'JSON',
            'sheetCount': 0,
          };
        }

        // Get all keys from first object
        if (jsonData.first is! Map) {
          throw Exception('JSON array must contain objects');
        }

        final firstRow = jsonData.first as Map;
        final columnNames = firstRow.keys.toList();

        final rows = <List<String>>[];

        // Header row
        rows.add(columnNames.cast<String>());

        // Data rows
        for (var item in jsonData) {
          if (item is! Map) continue;
          final row = <String>[];
          for (var key in columnNames) {
            row.add((item[key]?.toString()) ?? '');
          }
          rows.add(row);
        }

        return {
          'sheets': [
            {
              'name': 'Data',
              'rows': rows,
              'rowCount': rows.length,
              'colCount': columnNames.length,
            }
          ],
          'format': 'JSON',
          'sheetCount': 1,
          'textContent': content,
        };
      } else if (jsonData is Map) {
        // Object → single row or nested sheets
        final rows = <List<String>>[];
        rows.add(['Key', 'Value']);

        jsonData.forEach((key, value) {
          rows.add([key.toString(), value.toString()]);
        });

        return {
          'sheets': [
            {
              'name': 'Data',
              'rows': rows,
              'rowCount': rows.length,
              'colCount': 2,
            }
          ],
          'format': 'JSON',
          'sheetCount': 1,
          'textContent': content,
        };
      } else {
        throw Exception('JSON must be an object or array');
      }
    } catch (e, st) {
      log.e('Error parsing JSON', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse XML format
  /// Returns raw XML content and basic structure info
  static Future<Map<String, dynamic>> parseXML(String filePath) async {
    try {
      log.i('Parsing XML file: $filePath');
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('XML file does not exist: $filePath');
      }

      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        throw Exception('XML file is empty');
      }

      // Try to parse and validate XML structure
      try {
        final document = XmlDocument.parse(content);
        final rootName = document.rootElement.name.local;
        final elementCount = document.rootElement.descendants.length;

        log.i(
            'XML parsed successfully. Root: $rootName, Elements: $elementCount');

        return {
          'content': content,
          'textContent': content,
          'format': 'XML',
          'rootElement': rootName,
          'elementCount': elementCount,
          'isValid': true,
        };
      } catch (parseError) {
        log.w('XML parsing failed: $parseError. Returning raw content.');

        // Return raw content even if parsing failed
        return {
          'content': content,
          'textContent': content,
          'format': 'XML',
          'isValid': false,
          'parseError': parseError.toString(),
        };
      }
    } catch (e, st) {
      log.e('Error reading XML file', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Parse TXT format - Plain text file
  /// Returns text content with proper encoding handling and large file support
  static Future<String> parseTXT(String filePath) async {
    try {
      log.i('Parsing TXT file: $filePath');
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('TXT file does not exist: $filePath');
      }

      final fileSizeBytes = await file.length();
      final fileSizeMB = fileSizeBytes / (1024 * 1024);

      // For very large files (>50MB), read a preview to prevent memory issues
      const maxPreviewSizeMB = 50;
      if (fileSizeMB > maxPreviewSizeMB) {
        log.w('Large TXT file detected: $fileSizeMB MB. Reading preview only.');
        final bytes = await file.openRead(0, maxPreviewSizeMB * 1024 * 1024).toList();
        final combinedBytes = <int>[];
        for (var chunk in bytes) {
          combinedBytes.addAll(chunk);
        }
        
        try {
          // Try UTF-8 first
          var content = utf8.decode(combinedBytes, allowMalformed: true);
          content += '\n\n[Preview truncated - file is ${fileSizeMB.toStringAsFixed(1)} MB]';
          log.i('TXT preview extracted: ${content.length} characters');
          return content;
        } catch (e) {
          log.e('Error decoding TXT preview: $e');
          rethrow;
        }
      }

      // For normal-sized files, read entire content
      String content;
      try {
        // Try UTF-8 first (most common)
        content = await file.readAsString(encoding: utf8);
      } catch (utf8Error) {
        log.w('UTF-8 decoding failed, trying latin-1: $utf8Error');
        try {
          // Fallback to latin-1 (ISO-8859-1)
          final bytes = await file.readAsBytes();
          content = latin1.decode(bytes);
        } catch (latin1Error) {
          log.w('Latin-1 decoding failed, using UTF-8 with malformed tolerance');
          final bytes = await file.readAsBytes();
          content = utf8.decode(bytes, allowMalformed: true);
        }
      }

      if (content.trim().isEmpty) {
        log.w('TXT file is empty or contains only whitespace');
        return '';
      }

      // Normalize line endings to \n for consistency
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      log.i('TXT extracted: ${content.length} characters, ${content.split('\n').length} lines');
      return content;
    } catch (e, st) {
      log.e('Error parsing TXT', error: e, stackTrace: st);
      rethrow;
    }
  }
}
