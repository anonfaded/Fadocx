import Flutter
import UIKit
import Foundation

/// Handles document parsing for XLSX, CSV, DOC, DOCX formats.
///
/// Channel: `com.fadseclab.fadocx/document_parser`
/// Android equivalent: MainActivity.kt (Apache POI via reflection)
///
/// iOS implementations:
///   - XLSX: CoreXLSX (SPM dependency — add via Xcode)
///   - CSV:  NSString.components(separatedBy:)
///   - DOC:  NSAttributedString with .docFormat
///   - DOCX: NSAttributedString with .officeOpenXML (iOS 15+)
///
/// Dependencies:
///   - CoreXLSX: https://github.com/CoreOffice/CoreXLSX (add via SPM in Xcode)
///
class DocumentParserHandler {

    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/document_parser",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "parseDocument":
                guard let args = call.arguments as? [String: Any],
                      let filePath = args["filePath"] as? String,
                      let format = args["format"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS",
                                        message: "Missing required arguments: filePath, format",
                                        details: nil))
                    return
                }
                let maxRows = args["maxRows"] as? Int ?? 0
                let maxCols = args["maxCols"] as? Int ?? 0
                let maxSheets = args["maxSheets"] as? Int ?? 0

                DispatchQueue.global(qos: .userInitiated).async {
                    parseDocument(filePath: filePath, format: format,
                                  maxRows: maxRows, maxCols: maxCols,
                                  maxSheets: maxSheets, result: result)
                }

            case "isAvailable":
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Dispatch

    private static func parseDocument(filePath: String, format: String,
                                       maxRows: Int, maxCols: Int,
                                       maxSheets: Int,
                                       result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            DispatchQueue.main.async {
                result(FlutterError(code: "FILE_NOT_FOUND",
                                    message: "File not found at \(filePath)", details: nil))
            }
            return
        }

        switch format.lowercased() {
        case "xlsx":
            parseXLSX(url: url, maxRows: maxRows, maxCols: maxCols, maxSheets: maxSheets, result: result)
        case "csv":
            parseCSV(url: url, maxRows: maxRows, maxCols: maxCols, result: result)
        case "doc":
            parseWordDocument(url: url, format: format, result: result)
        case "docx":
            parseWordDocument(url: url, format: format, result: result)
        default:
            DispatchQueue.main.async {
                result(FlutterError(code: "UNSUPPORTED_FORMAT",
                                    message: "Format '\(format)' is not supported on iOS",
                                    details: nil))
            }
        }
    }

    // MARK: - XLSX (CoreXLSX)

    /// Parses .xlsx files using the CoreXLSX library.
    ///
    /// NOTE: CoreXLSX must be added via Swift Package Manager:
    ///   Xcode → File → Add Package Dependencies → https://github.com/CoreOffice/CoreXLSX
    ///
    /// If CoreXLSX is not available, this will return a dependency error.
    private static func parseXLSX(url: URL, maxRows: Int, maxCols: Int,
                                   maxSheets: Int,
                                   result: @escaping FlutterResult) {
        // CoreXLSX integration:
        //
        // import CoreXLSX
        //
        // do {
        //     let file = try XLSXFile(filepath: url.path)
        //     var workbookJson: [String: Any] = [:]
        //     let workbook = try file.parseWorkbook()
        //     let sheetCount = min(maxSheets > 0 ? maxSheets : Int.max,
        //                          workbook.sheets.sheets.count)
        //
        //     for (index, path) in workbook.sheets.sheets.prefix(sheetCount).enumerated() {
        //         let worksheet = try file.parseWorksheet(at: path.name)
        //         let sharedStrings = try file.parseSharedStrings()
        //         // Convert to rows/cols respecting maxRows/maxCols
        //         // Build a JSON-serializable structure
        //     }
        //
        //     var jsonData: [String: Any] = [:]
        //     jsonData["sheets"] = workbookJson
        //     jsonData["sheetCount"] = sheetCount
        //     let jsonString = String(data: try JSONSerialization.data(withJSONObject: jsonData), encoding: .utf8)
        //     DispatchQueue.main.async { result(jsonString) }
        // } catch {
        //     DispatchQueue.main.async { result(FlutterError(code: "XLSX_PARSE_ERROR", ...)) }
        // }

        DispatchQueue.main.async {
            result(FlutterError(
                code: "DEPENDENCY_MISSING",
                message: "XLSX parsing requires CoreXLSX. Add via SPM: https://github.com/CoreOffice/CoreXLSX",
                details: nil
            ))
        }
    }

    // MARK: - CSV (Foundation)

    private static func parseCSV(url: URL, maxRows: Int, maxCols: Int,
                                  result: @escaping FlutterResult) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            let rowLimit = maxRows > 0 ? min(maxRows, lines.count) : lines.count
            var rows: [[String]] = []

            for i in 0..<rowLimit {
                let columns = parseCSVLine(lines[i])
                let colLimit = maxCols > 0 ? min(maxCols, columns.count) : columns.count
                rows.append(Array(columns.prefix(colLimit)))
            }

            let resultDict: [String: Any] = [
                "rows": rows,
                "rowCount": rows.count,
                "totalRows": lines.count,
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: resultDict)
            let jsonString = String(data: jsonData, encoding: .utf8)

            DispatchQueue.main.async { result(jsonString) }
        } catch {
            DispatchQueue.main.async {
                result(FlutterError(code: "CSV_PARSE_ERROR",
                                    message: error.localizedDescription, details: nil))
            }
        }
    }

    /// Simple RFC-compatible CSV line parser (handles quoted fields).
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }

    // MARK: - DOC / DOCX (NSAttributedString)

    private static func parseWordDocument(url: URL, format: String,
                                           result: @escaping FlutterResult) {
        do {
            let documentType: NSAttributedString.DocumentAttributeKey
            if format == "docx" {
                if #available(iOS 15.0, *) {
                    documentType = .officeOpenXML
                } else {
                    // iOS 14 and below: try reading as plain text
                    let text = try String(contentsOf: url, encoding: .utf8)
                    let resultDict: [String: Any] = ["text": text, "format": "docx", "fallback": true]
                    let jsonData = try JSONSerialization.data(withJSONObject: resultDict)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    DispatchQueue.main.async { result(jsonString) }
                    return
                }
            } else {
                documentType = .docFormat
            }

            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: documentType,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ]

            let attributed = try NSAttributedString(url: url, options: options, documentAttributes: nil)
            let text = attributed.string

            let resultDict: [String: Any] = ["text": text, "format": format]
            let jsonData = try JSONSerialization.data(withJSONObject: resultDict)
            let jsonString = String(data: jsonData, encoding: .utf8)

            DispatchQueue.main.async { result(jsonString) }
        } catch {
            DispatchQueue.main.async {
                result(FlutterError(code: "DOC_PARSE_ERROR",
                                    message: error.localizedDescription, details: nil))
            }
        }
    }
}
