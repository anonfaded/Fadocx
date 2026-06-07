import Flutter
import UIKit

/// Handles app settings channel — no-op on iOS.
///
/// Channel: `com.fadseclab.fadocx/app_settings`
/// Android equivalent: MainActivity.kt lines 271-280
///   (opens Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
///
/// iOS has no concept of "manage all files access" — the app runs in a sandbox
/// where it can only access its own Documents directory and files explicitly
/// opened by the user via UIDocumentPicker or open-with intent.
///
/// All methods return success with nil to prevent MissingPluginException crashes.
///
class AppSettingsHandler {

    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/app_settings",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "openManageAllFilesSettings":
                // iOS is sandboxed — no equivalent settings page exists
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
