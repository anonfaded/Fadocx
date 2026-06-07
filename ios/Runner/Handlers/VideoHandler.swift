import Flutter
import UIKit
import AVFoundation

/// Handles video frame extraction using AVFoundation.
///
/// Channel: `com.fadseclab.fadocx/video`
/// Android equivalent: MainActivity.kt lines 282-309 (MediaMetadataRetriever)
///
/// iOS implementation uses AVAssetImageGenerator (built-in, no external deps).
///
class VideoHandler {

    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/video",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "extractVideoFrame":
                guard let args = call.arguments as? [String: Any],
                      let filePath = args["filePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS",
                                        message: "Missing filePath", details: nil))
                    return
                }
                let timeUs = (args["timeUs"] as? NSNumber)?.int64Value ?? 0
                extractFrame(filePath: filePath, timeUs: timeUs, result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Frame Extraction

    private static func extractFrame(filePath: String, timeUs: Int64,
                                      result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: filePath)
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = CMTime(value: timeUs, timescale: 1_000_000)

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
            if let cgImage = image {
                let uiImage = UIImage(cgImage: cgImage)
                guard let pngData = uiImage.pngData() else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "ENCODE_FAILED",
                                            message: "Failed to encode frame as PNG", details: nil))
                    }
                    return
                }
                DispatchQueue.main.async {
                    result(FlutterStandardTypedData(bytes: pngData))
                }
            } else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "EXTRACTION_FAILED",
                                        message: error?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            }
        }
    }
}
