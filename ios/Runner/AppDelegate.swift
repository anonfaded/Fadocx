import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // Register all 6 platform channel handlers (mirrors Android's MainActivity.kt)
        DocumentParserHandler.register(with: controller)
        PdfHandler.register(with: controller)
        LOKitHandler.register(with: controller)
        VideoHandler.register(with: controller)
        FileIntentHandler.register(with: controller)
        AppSettingsHandler.register(with: controller)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Handle incoming file URLs from other apps (Files, Mail, Safari, etc.)
    ///
    /// Android equivalent: Intent.ACTION_VIEW handling in MainActivity.kt
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        FileIntentHandler.setPendingFile(url)
        return super.application(app, open: url, options: options)
    }
}
