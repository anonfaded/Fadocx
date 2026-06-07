import Flutter
import UIKit

/// Handles incoming file URLs when the app is opened from other apps
/// (Files app, Mail, Safari, etc.).
///
/// Channel: `com.fadseclab.fadocx/file_intent`
/// Android equivalent: MainActivity.kt lines 115-123 (Android Intent system)
///
/// iOS implementation:
///   - AppDelegate.application(_:open:options:) is called by iOS when another
///     app opens a file in Fadocx
///   - The file URL is provided by iOS in a temporary Inbox directory
///   - We copy it to the app's Documents directory for persistent access
///   - Flutter polls via `getOpenFileIntent` to retrieve the path
///
class FileIntentHandler {

    private static var pendingFileURL: URL?

    // MARK: - Called from AppDelegate

    /// Called when iOS opens a file in Fadocx (from Files, Mail, etc.).
    ///
    /// iOS places the file in a temporary Inbox directory:
    ///   `.../Documents/Inbox/filename.ext`
    ///
    /// We copy it to `Documents/` for persistent storage so the file remains
    /// accessible after the app relaunches.
    static func setPendingFile(_ url: URL) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destination = documentsDir.appendingPathComponent(url.lastPathComponent)

        // Remove existing file at destination if present
        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }

        do {
            try FileManager.default.copyItem(at: url, to: destination)
            pendingFileURL = destination
        } catch {
            // If copy fails (e.g., cross-device), try reading and writing
            if let data = try? Data(contentsOf: url) {
                try? data.write(to: destination)
                pendingFileURL = destination
            } else {
                pendingFileURL = url  // fallback to original URL
            }
        }
    }

    // MARK: - Registration

    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/file_intent",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getOpenFileIntent":
                let filePath = pendingFileURL?.path
                pendingFileURL = nil  // consume the intent
                if let path = filePath {
                    result(["filePath": path])
                } else {
                    result(nil)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
