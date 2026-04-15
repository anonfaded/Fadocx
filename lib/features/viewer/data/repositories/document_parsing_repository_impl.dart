import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/domain/entities/sheet_entity.dart';
import 'package:fadocx/features/viewer/domain/repositories/document_parsing_repository.dart';
import '../services/cache_service.dart';
import '../services/document_parser_service.dart';
import '../services/platform_channel_service.dart';

/// Production implementation of DocumentParsingRepository
/// 
/// Orchestrates:
/// - Native parsing via platform channels
/// - Fallback to Dart parsing
/// - Result caching with file modification validation
/// - Multiple file format support
class DocumentParsingRepositoryImpl implements DocumentParsingRepository {
  final PlatformChannelService _platformChannel;
  final CacheService _cache;

  DocumentParsingRepositoryImpl({
    required PlatformChannelService platformChannel,
    required CacheService cache,
  })  : _platformChannel = platformChannel,
        _cache = cache;

  @override
  Future<ParsedDocumentEntity> parseSpreadsheet(String filePath) async {
    final ext = filePath.toLowerCase().split('.').last;

    switch (ext) {
      case 'xlsx':
      case 'xls':
        return parseXLSX(filePath, useNativeParsing: true);
      case 'csv':
        return parseCSV(filePath);
      case 'ods':
        return parseODS(filePath);
      case 'json':
        return parseJSON(filePath);
      case 'fadrec':
        // .fadrec is a custom JSON format from FadCam companion app
        return parseFadrec(filePath);
      case 'xml':
        return parseXML(filePath);
      default:
        throw Exception('Unsupported format: $ext');
    }
  }

  /// Parse JSON file - Pure Dart, lightweight, no native needed
  /// JSON is fast in Dart, no fallback required
  @override
  Future<ParsedDocumentEntity> parseJSON(String filePath) async {
    // Check cache first (skip if format is UNKNOWN or invalid)
    final cached = await getCachedParsing(filePath);
    if (cached != null && cached.format != 'UNKNOWN') {
      log.i('Using cached JSON: $filePath');
      return cached;
    }

    try {
      log.i('Parsing JSON (Dart): $filePath');
      final dartResult = await DocumentParserService.parseJSON(filePath);
      final result = _toParsedEntity(dartResult, format: 'JSON');
      log.d('JSON parsed: ${result.textContent?.length} chars');
      await cacheParsing(filePath, result);
      return result;
    } catch (e, st) {
      log.e('JSON parsing failed: $e', e, st);
      rethrow;
    }
  }

  /// Parse .fadrec format (custom JSON from FadCam companion app)
  /// Treat as JSON with special format identification
  @override
  Future<ParsedDocumentEntity> parseFadrec(String filePath) async {
    // Check cache first (skip if format is UNKNOWN or invalid)
    final cached = await getCachedParsing(filePath);
    if (cached != null && cached.format != 'UNKNOWN') {
      log.i('Using cached FADREC: $filePath');
      return cached;
    }

    try {
      log.i('Parsing FADREC (Dart): $filePath');
      final dartResult = await DocumentParserService.parseJSON(filePath);
      final result = _toParsedEntity(dartResult, format: 'FADREC');
      log.d('FADREC parsed as JSON');
      await cacheParsing(filePath, result);
      return result;
    } catch (e, st) {
      log.e('FADREC parsing failed: $e', e, st);
      rethrow;
    }
  }

  /// Parse XML format
  @override
  Future<ParsedDocumentEntity> parseXML(String filePath) async {
    // Check cache first (skip if format is UNKNOWN or invalid)
    final cached = await getCachedParsing(filePath);
    if (cached != null && cached.format != 'UNKNOWN') {
      log.i('Using cached XML: $filePath');
      return cached;
    }

    try {
      log.i('Parsing XML (Dart): $filePath');
      final dartResult = await DocumentParserService.parseXML(filePath);
      final result = _toParsedEntity(dartResult, format: 'XML');
      log.d('XML parsed: valid=${dartResult['isValid']}, elements=${dartResult['elementCount']}');
      await cacheParsing(filePath, result);
      return result;
    } catch (e, st) {
      log.e('XML parsing failed: $e', e, st);
      rethrow;
    }
  }

  /// Parse ODS (OpenDocument Spreadsheet)
  @override
  Future<ParsedDocumentEntity> parseODS(String filePath) async {
    // Check cache first (skip if format is UNKNOWN or invalid)
    final cached = await getCachedParsing(filePath);
    if (cached != null && cached.format != 'UNKNOWN') {
      log.i('Using cached ODS: $filePath');
      return cached;
    }

    try {
      log.i('Parsing ODS (Dart): $filePath');
      final dartResult = await DocumentParserService.parseODS(filePath);
      final result = _toParsedEntity(dartResult, format: 'ODS');
      log.d('ODS parsed: ${result.sheets.length} sheets');
      await cacheParsing(filePath, result);
      return result;
    } catch (e, st) {
      log.e('ODS parsing failed: $e', e, st);
      rethrow;
    }
  }

  @override
  Future<ParsedDocumentEntity> parseXLSX(
    String filePath, {
    bool useNativeParsing = false,
  }) async {
    // Check cache first (skip if format is UNKNOWN or invalid)
    final cached = await getCachedParsing(filePath);
    if (cached != null && cached.format != 'UNKNOWN') {
      log.i('Using cached XLSX: $filePath (format: ${cached.format})');
      return cached;
    }

    // Determine format from file extension
    final format = filePath.toLowerCase().endsWith('.xls') ? 'XLS' : 'XLSX';
    log.i('Parsing $format (NATIVE, no fallback): $filePath');

    // XLSX/XLS MUST use native parsing - no fallback
    // These are heavy formats, native is REQUIRED for performance
    try {
      log.d('Calling native parser channel for $format...');
      final nativeResult = await _platformChannel.parseDocumentNative(filePath, format);
      
      log.d('Native parser returned: sheets=${nativeResult['sheetCount']}, format=${nativeResult['format']}');
      
      final result = _toParsedEntity(nativeResult, format: format);
      
      log.i('Successfully parsed $format: ${result.sheets.length} sheets');
      await cacheParsing(filePath, result);
      return result;
    } catch (e, st) {
      log.e('NATIVE PARSING FAILED for $format: $e', e, st);
      log.d('Failed file path: $filePath');
      log.d('Native channel may not be available or file may be corrupted');
      rethrow; // Let it fail - this is critical
    }
  }

  @override
  Future<ParsedDocumentEntity> parseCSV(String filePath) async {
    // Check cache first (skip if format is UNKNOWN or invalid)
    final cached = await getCachedParsing(filePath);
    if (cached != null && cached.format != 'UNKNOWN') {
      log.i('Using cached CSV: $filePath');
      return cached;
    }

    try {
      log.i('Parsing CSV (Dart): $filePath');
      final dartResult = await DocumentParserService.parseCSV(filePath);
      final result = _toParsedEntity(dartResult, format: 'CSV');
      log.d('CSV parsed: ${result.sheets.length} sheets, rows=${result.sheets.firstOrNull?.rowCount}');
      await cacheParsing(filePath, result);
      return result;
    } catch (e, st) {
      log.e('CSV parsing failed: $e', e, st);
      rethrow;
    }
  }

  @override
  Future<ParsedDocumentEntity> parseDOCX(String filePath) async {
    // Check cache first
    final cached = await getCachedParsing(filePath);
    if (cached != null) {
      return cached;
    }

    log.i('Parsing DOCX (Dart): $filePath');
    
    // DOCX: Pure Dart, no native needed - lightweight format
    final textContent = await DocumentParserService.parseDOCX(filePath);
    final result = ParsedDocumentEntity(
      format: 'DOCX',
      sheets: [],
      sheetCount: 0,
      parsedAt: DateTime.now(),
      sourceFilePath: filePath,
      textContent: textContent,
    );
    await cacheParsing(filePath, result);
    return result;
  }

  @override
  Future<ParsedDocumentEntity> parseDOC(String filePath) async {
    // Check cache first
    final cached = await getCachedParsing(filePath);
    if (cached != null) {
      return cached;
    }

    log.i('Parsing DOC (Dart): $filePath');
    
    // DOC: Legacy Word format, extract text via Dart parser
    final textContent = await DocumentParserService.parseDOC(filePath);
    final result = ParsedDocumentEntity(
      format: 'DOC',
      sheets: [],
      sheetCount: 0,
      parsedAt: DateTime.now(),
      sourceFilePath: filePath,
      textContent: textContent,
    );
    await cacheParsing(filePath, result);
    return result;
  }

  @override
  Future<ParsedDocumentEntity?> getCachedParsing(String filePath) async {
    try {
      final cachedResult = await _cache.getCachedParsing(filePath);
      if (cachedResult != null) {
        // For now, reconstruct basic entity from cached data
        // In production, store the full entity serialized
        return ParsedDocumentEntity(
          format: cachedResult['format'] ?? 'UNKNOWN',
          sheets: _buildSheetEntities(cachedResult['sheets'] ?? []),
          sheetCount: cachedResult['sheetCount'] ?? 0,
          parsedAt: DateTime.now(),
          sourceFilePath: filePath,
          textContent: cachedResult['textContent'],
        );
      }
    } catch (e) {
      log.w('Failed to get cached parsing: $e');
    }
    return null;
  }

  @override
  Future<void> cacheParsing(
    String filePath,
    ParsedDocumentEntity document,
  ) async {
    try {
      final data = {
        'format': document.format,
        'sheetCount': document.sheetCount,
        'sheets': document.sheets
            .map((s) => {
                  'name': s.name,
                  'rows': s.rows,
                  'rowCount': s.rowCount,
                  'colCount': s.colCount,
                })
            .toList(),
        'textContent': document.textContent,
      };

      await _cache.cacheParsing(filePath, data);
    } catch (e) {
      log.e('Failed to cache parsing: $e');
      // Don't throw - caching is optional
    }
  }

  @override
  Future<void> clearCache() => _cache.clearCache();

  @override
  Future<bool> isFileModified(String filePath, DateTime lastParsed) async {
    return !await _cache.isCacheValid(filePath, lastParsed);
  }

  /// Convert parser result map to ParsedDocumentEntity
  ParsedDocumentEntity _toParsedEntity(
    Map<String, dynamic> parserResult, {
    String? format,
  }) {
    final sheets = _buildSheetEntities(parserResult['sheets'] ?? []);

    return ParsedDocumentEntity(
      format: format ?? parserResult['format'] ?? 'UNKNOWN',
      sheets: sheets,
      sheetCount: parserResult['sheetCount'] ?? sheets.length,
      parsedAt: DateTime.now(),
      sourceFilePath: parserResult['filePath'] ?? '',
      textContent: parserResult['textContent'],
    );
  }

  /// Build SheetEntity list from parser result
  List<SheetEntity> _buildSheetEntities(List<dynamic> sheetsData) {
    return sheetsData
        .map((sheetData) {
          // Handle both Map<String, dynamic> and Map<dynamic, dynamic>
          final sheet = sheetData is Map<String, dynamic>
              ? sheetData
              : _convertDynamicMapToTyped(sheetData as Map);
          
          final rows = (sheet['rows'] as List<dynamic>?)
              ?.map((row) {
                if (row is List<String>) {
                  return row;
                }
                // Handle mixed types in row data
                return (row as List<dynamic>).map((e) => e.toString()).toList();
              })
              .toList() ?? [];

          // Determine max column count from all rows
          final maxColCount = rows.fold<int>(
            0,
            (max, row) => max > row.length ? max : row.length,
          );

          // Normalize all rows to have the same column count
          final normalizedRows = rows.map((row) {
            if (row.length == maxColCount) {
              return row;
            }
            final normalized = List<String>.from(row);
            if (normalized.length < maxColCount) {
              normalized.addAll(List<String>.filled(maxColCount - normalized.length, ''));
            } else {
              normalized.length = maxColCount;
            }
            return normalized;
          }).toList();

          return SheetEntity(
            name: sheet['name'] as String? ?? 'Sheet',
            rows: normalizedRows,
            rowCount: normalizedRows.length,
            colCount: maxColCount,
          );
        })
        .toList();
  }

  /// Convert Map with dynamic keys to typed Map with String keys
  Map<String, dynamic> _convertDynamicMapToTyped(Map map) {
    return Map<String, dynamic>.from(
      map.map((key, value) => MapEntry(
        key.toString(),
        _convertDynamicValue(value),
      )),
    );
  }

  /// Recursively convert dynamic values to typed values
  dynamic _convertDynamicValue(dynamic value) {
    if (value is Map) {
      return _convertDynamicMapToTyped(value);
    } else if (value is List) {
      return value.map(_convertDynamicValue).toList();
    } else {
      return value;
    }
  }
}
