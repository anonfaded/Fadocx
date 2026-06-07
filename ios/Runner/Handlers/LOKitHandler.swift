import Flutter
import UIKit
import QuickLook

/// Handles Office document viewing via QuickLook.
///
/// Channel: `com.fadseclab.fadocx/lokit`
/// Android equivalent: MainActivity.kt lines 165-268 (LibreOfficeKit JNI)
///
/// CRITICAL CONSTRAINT: LibreOffice does NOT compile for iOS. There is no C++ library
/// for rendering ODP/ODS/PPT/PPTX on iOS.
///
/// Instead, we use Apple's QuickLook framework (QLPreviewController) which can natively
/// preview Microsoft Office formats:
///   ✅ PPT, PPTX, DOC, DOCX, XLS, XLSX
///   ✅ PDF, images, text, RTF
///   ❌ ODP, ODS — return unsupported error
///
/// For QuickLook-compatible formats: `loadDocument` presents QLPreviewController as
/// a full-screen native modal. The Flutter render methods return empty values since
/// QuickLook handles all rendering.
///
class LOKitHandler: NSObject, QLPreviewControllerDataSource {

    private static var previewURL: URL?
    private static weak var previewController: QLPreviewController?
    private static weak var presentingController: UIViewController?

    /// Formats that QuickLook can preview natively.
    private static let quickLookFormats: Set<String> = [
        "ppt", "pptx", "doc", "docx", "xls", "xlsx",
        "pdf", "rtf", "txt", "csv", "png", "jpg", "jpeg",
        "gif", "bmp", "tiff",
    ]

    // MARK: - Registration

    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/lokit",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "init":
                result(true)

            case "loadDocument":
                guard let args = call.arguments as? [String: Any],
                      let filePath = args["filePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS",
                                        message: "Missing filePath", details: nil))
                    return
                }
                loadDocument(filePath: filePath, controller: controller, result: result)

            case "renderPage", "renderPageFit", "renderPageHighQuality", "renderTextPage":
                // QuickLook handles rendering natively — return empty
                let emptyData = FlutterStandardTypedData(bytes: Data())
                result([
                    "bytes": emptyData,
                    "part": 0,
                    "width": 0,
                    "height": 0,
                ])

            case "getDocumentInfo":
                result([
                    "parts": 0,
                    "documentParts": 0,
                    "pages": 0,
                    "pageSize": ["width": 0, "height": 0],
                ])

            case "getPageCount":
                result(0)

            case "extractText", "extractPartText":
                result("")

            case "closeDocument":
                dismissQuickLook(result: result)

            case "destroy":
                previewURL = nil
                previewController?.dismiss(animated: true)
                previewController = nil
                presentingController = nil
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - QuickLook Presentation

    private static func loadDocument(filePath: String,
                                      controller: FlutterViewController,
                                      result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: filePath)
        let ext = url.pathExtension.lowercased()

        guard quickLookFormats.contains(ext) else {
            result(FlutterError(
                code: "FORMAT_NOT_SUPPORTED",
                message: "\(ext.uppercased()) files cannot be viewed on iOS. "
                        + "Open this file on a Mac or Android device.",
                details: nil
            ))
            return
        }

        guard FileManager.default.fileExists(atPath: filePath) else {
            result(FlutterError(code: "FILE_NOT_FOUND",
                                message: "File not found", details: nil))
            return
        }

        previewURL = url
        presentingController = controller

        let ql = QLPreviewController()
        ql.dataSource = LOKitHandler.shared
        ql.modalPresentationStyle = .fullScreen
        controller.present(ql, animated: true)
        previewController = ql

        result(true)
    }

    private static func dismissQuickLook(result: @escaping FlutterResult) {
        previewController?.dismiss(animated: true)
        previewURL = nil
        previewController = nil
        presentingController = nil
        result(true)
    }

    // MARK: - QLPreviewControllerDataSource

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return LOKitHandler.previewURL != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController,
                           previewItemAt index: Int) -> QLPreviewItem {
        return LOKitHandler.previewURL! as NSURL
    }
}
