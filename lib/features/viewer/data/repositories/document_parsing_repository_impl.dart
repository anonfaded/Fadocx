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
        return parseXLSX(filePath, useNativeParsing: true);
      case 'csv':
        return parseCSV(filePath);
      case 'xls':
        // XLS not yet supported, fallback to dart or throw
        log.w('XLS format not yet supported, attempting Dart parser');
        return _toParsedEntity(await DocumentParserService.parseXLS(filePath));
      default:
        throw Exception('Unsupported spreadsheet format: $ext');
    }
  }

  @override
  Future<ParsedDocumentEntity> parseXLSX(
    String filePath, {
    bool useNativeParsing = false,
  }) async {
    // Check cache first
    final cached = await getCachedParsing(filePath);
    if (cached != null) {
      log.i('Using cached XLSX: $filePath');
      return cached;
    }

    ParsedDocumentEntity result;

    // Try native parsing if available and requested
    if (useNativeParsing) {
      try {
        final nativeAvailable = await _platformChannel.isNativeParsingAvailable();
        if (nativeAvailable) {
          log.i('Using native XLSX parser: $filePath');
          final nativeResult = await _platformChannel.parseExcelNative(filePath);
          result = _toParsedEntity(nativeResult, format: 'XLSX');
          await cacheParsing(filePath, result);
          return result;
        }
      } catch (e) {
        log.w('Native parsing failed, falling back to Dart: $e');
        // Fall through to Dart parser
      }
    }

    // Fallback to Dart parser
    log.i('Using Dart XLSX parser: $filePath');
    final dartResult = await DocumentParserService.parseXLSX(filePath);
    result = _toParsedEntity(dartResult, format: 'XLSX');
    await cacheParsing(filePath, result);
    return result;
  }

  @override
  Future<ParsedDocumentEntity> parseCSV(String filePath) async {
    // Check cache first
    final cached = await getCachedParsing(filePath);
    if (cached != null) {
      return cached;
    }

    log.i('Parsing CSV: $filePath');
    final dartResult = await DocumentParserService.parseCSV(filePath);
    final result = _toParsedEntity(dartResult, format: 'CSV');
    await cacheParsing(filePath, result);
    return result;
  }

  @override
  Future<ParsedDocumentEntity> parseDOCX(String filePath) async {
    // Check cache first
    final cached = await getCachedParsing(filePath);
    if (cached != null) {
      return cached;
    }

    log.i('Parsing DOCX: $filePath');
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
        .cast<Map<String, dynamic>>()
        .map((sheetData) {
          final rows = (sheetData['rows'] as List<dynamic>?)
              ?.cast<List<dynamic>>()
              .map((row) => row.cast<String>().toList())
              .toList() ?? [];

          return SheetEntity(
            name: sheetData['name'] ?? 'Sheet',
            rows: rows,
            rowCount: sheetData['rowCount'] ?? rows.length,
            colCount: sheetData['colCount'] ?? (rows.isNotEmpty ? rows.first.length : 0),
          );
        })
        .toList();
  }
}
