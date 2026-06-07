import Flutter
import UIKit
import PDFKit

/// Handles PDF rendering, text extraction, and page operations using PDFKit.
///
/// Channel: `com.fadseclab.fadocx/pdf`
/// Android equivalent: MainActivity.kt lines 125-163 (android.graphics.pdf.PdfRenderer)
///
/// iOS implementation uses Apple's built-in PDFKit framework (iOS 11+).
/// No external dependencies needed.
///
class PdfHandler {
    // MARK: - State
    /// Maps file paths to open PDFDocument instances (mirrors Android's pdfRenderers map).
    private static var documents: [String: PDFDocument] = [:]
    private static let queue = DispatchQueue(label: "com.fadseclab.fadocx.pdf", qos: .userInitiated)

    // MARK: - Registration

    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/pdf",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS",
                                    message: "Missing arguments", details: nil))
                return
            }

            switch call.method {
            case "openPdf":
                openPdf(args: args, result: result)
            case "closePdf":
                closePdf(args: args, result: result)
            case "getPageCount":
                getPageCount(args: args, result: result)
            case "renderPage":
                renderPage(args: args, result: result)
            case "extractPageText":
                extractPageText(args: args, result: result)
            case "extractTextWithPositions":
                extractTextWithPositions(args: args, result: result)
            case "getPageSize":
                getPageSize(args: args, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Helpers

    private static func getDocument(for filePath: String) -> PDFDocument? {
        if let doc = documents[filePath] { return doc }
        let url = URL(fileURLWithPath: filePath)
        guard let doc = PDFDocument(url: url) else { return nil }
        documents[filePath] = doc
        return doc
    }

    private static func getPage(for filePath: String, pageNumber: Int) -> PDFPage? {
        guard let doc = getDocument(for: filePath) else { return nil }
        guard pageNumber >= 0, pageNumber < doc.pageCount else { return nil }
        return doc.page(at: pageNumber)
    }

    // MARK: - Methods

    private static func openPdf(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath", details: nil))
            return
        }
        queue.async {
            let url = URL(fileURLWithPath: filePath)
            guard FileManager.default.fileExists(atPath: filePath) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "FILE_NOT_FOUND", message: "PDF not found", details: nil))
                }
                return
            }
            guard let doc = PDFDocument(url: url) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PDF_OPEN_FAILED", message: "Failed to open PDF", details: nil))
                }
                return
            }
            documents[filePath] = doc
            DispatchQueue.main.async { result(nil) }
        }
    }

    private static func closePdf(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath", details: nil))
            return
        }
        documents.removeValue(forKey: filePath)
        result(nil)
    }

    private static func getPageCount(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath", details: nil))
            return
        }
        queue.async {
            guard let doc = getDocument(for: filePath) else {
                DispatchQueue.main.async { result(0) }
                return
            }
            DispatchQueue.main.async { result(Int32(doc.pageCount)) }
        }
    }

    private static func renderPage(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String,
              let pageNumber = args["pageNumber"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath or pageNumber", details: nil))
            return
        }
        let width = (args["width"] as? Int?)??800
        let height = (args["height"] as? Int?)??1200

        queue.async {
            guard let page = getPage(for: filePath, pageNumber: pageNumber) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PAGE_NOT_FOUND", message: "Page \(pageNumber) not found", details: nil))
                }
                return
            }

            let thumbnailSize = CGSize(width: width, height: height)
            // PDFPage.thumbnail uses a box type; PDFDisplayBox.mediaBox is the standard
            let thumbnail = page.thumbnail(of: thumbnailSize, for: .mediaBox)

            guard let pngData = thumbnail.pngData() else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "RENDER_FAILED", message: "Failed to encode thumbnail", details: nil))
                }
                return
            }

            DispatchQueue.main.async {
                result([
                    "bytes": FlutterStandardTypedData(bytes: pngData),
                    "width": Int32(thumbnail.size.width),
                    "height": Int32(thumbnail.size.height),
                ])
            }
        }
    }

    private static func extractPageText(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String,
              let pageNumber = args["pageNumber"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath or pageNumber", details: nil))
            return
        }
        queue.async {
            guard let page = getPage(for: filePath, pageNumber: pageNumber) else {
                DispatchQueue.main.async { result("") }
                return
            }
            let text = page.attributedString?.string ?? ""
            DispatchQueue.main.async { result(text) }
        }
    }

    private static func extractTextWithPositions(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String,
              let pageNumber = args["pageNumber"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath or pageNumber", details: nil))
            return
        }
        queue.async {
            guard let page = getPage(for: filePath, pageNumber: pageNumber) else {
                DispatchQueue.main.async { result([]) }
                return
            }

            // Use PDFKit's selection by line to get positioned text
            let pageBounds = page.bounds(for: .mediaBox)
            var selections: [PDFSelection] = []

            // Walk through lines by incrementing y-position
            let step: CGFloat = 12.0
            var y: CGFloat = 0
            while y < pageBounds.height {
                let rect = CGRect(x: 0, y: y, width: pageBounds.width, height: step)
                if let sel = page.selection(for: rect) {
                    if !(sel.string?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                        selections.append(sel)
                    }
                }
                y += step
            }

            var textItems: [[String: Any]] = []
            for sel in selections {
                let text = sel.string ?? ""
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                for bounds in sel.segments()?.map({ $0.bounds }) ?? [] {
                    textItems.append([
                        "text": text.trimmingCharacters(in: .whitespacesAndNewlines),
                        "x": Double(bounds.origin.x),
                        "y": Double(bounds.origin.y),
                        "w": Double(bounds.width),
                        "h": Double(bounds.height),
                    ])
                }
            }

            DispatchQueue.main.async { result(textItems) }
        }
    }

    private static func getPageSize(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String,
              let pageNumber = args["pageNumber"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath or pageNumber", details: nil))
            return
        }
        queue.async {
            guard let page = getPage(for: filePath, pageNumber: pageNumber) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PAGE_NOT_FOUND", message: "Page \(pageNumber) not found", details: nil))
                }
                return
            }
            let bounds = page.bounds(for: .mediaBox)
            DispatchQueue.main.async {
                result(["width": Double(bounds.width), "height": Double(bounds.height)])
            }
        }
    }
}
