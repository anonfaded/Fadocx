import '../entities/parsed_document_entity.dart';

/// Abstract repository defining the contract for document parsing
/// This allows swapping implementations (Dart, Native, Mock, etc.)
abstract class DocumentParsingRepository {
  /// Parse a spreadsheet file (XLSX, CSV, XLS)
  /// 
  /// Throws exceptions on parsing errors
  /// Returns ParsedDocumentEntity with all sheets and metadata
  Future<ParsedDocumentEntity> parseSpreadsheet(String filePath);

  /// Parse XLSX specifically with optional native parsing
  ///
  /// This method can use either Dart or native (platform channel) parsing
  /// depending on platform availability and configuration
  Future<ParsedDocumentEntity> parseXLSX(
    String filePath, {
    bool useNativeParsing = false,
  });

  /// Parse CSV file
  Future<ParsedDocumentEntity> parseCSV(String filePath);

  /// Parse ODS (OpenDocument Spreadsheet) file
  Future<ParsedDocumentEntity> parseODS(String filePath);

  /// Parse JSON file
  Future<ParsedDocumentEntity> parseJSON(String filePath);

  /// Parse FADREC custom format (JSON-based)
  Future<ParsedDocumentEntity> parseFadrec(String filePath);

  /// Parse XML file
  Future<ParsedDocumentEntity> parseXML(String filePath);

  /// Parse DOCX file
  Future<ParsedDocumentEntity> parseDOCX(String filePath);

  /// Parse DOC file (legacy Word format)
  Future<ParsedDocumentEntity> parseDOC(String filePath);

  /// Get cached parsing result if available and file unchanged
  ///
  /// Returns null if:
  /// - No cache exists for this file
  /// - File has been modified since caching
  /// - Cache has expired
  Future<ParsedDocumentEntity?> getCachedParsing(String filePath);

  /// Cache a parsing result for future access
  ///
  /// Should invalidate if file is modified
  Future<void> cacheParsing(String filePath, ParsedDocumentEntity document);

  /// Clear all cached parsing data
  Future<void> clearCache();

  /// Check if file has been modified since last parsing
  Future<bool> isFileModified(String filePath, DateTime lastParsed);
}
