# Fadocx iOS Port Plan

> **Goal**: Full native iOS support for Fadocx using Swift/iOS frameworks — same architecture as Android (platform channels calling native code), no Dart fallbacks, no Android code changes.
>
> **Status**: Planning phase — Apple Developer account pending (1-2 days for approval)
>
> **Strategy**: Mirrors the Android approach. Android has `MainActivity.kt` handling 6 platform channels via Java/Kotlin. iOS will have `AppDelegate.swift` + dedicated Swift handler files handling the **same 6 channels** via native iOS frameworks.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Dart / Flutter Layer                          │
│  (same code — calls platform channels by name, no fallbacks)        │
└──────┬──────────┬──────────┬──────────┬──────────┬────────┬─────────┘
       │          │          │          │          │        │
       ▼          ▼          ▼          ▼          ▼        ▼
┌──────────┐ ┌──────────┐ ┌──────┐ ┌──────────┐ ┌────┐ ┌───────┐
│ doc_parser│ │file_intent│ │  pdf  │ │   lokit  │ │ vid│ │ app_ │
│ Apache POI│ │  Intent   │ │PdfRend│ │LibreOfcKt│ │  🎞│ │settng │
│   ↓       │ │   ↓       │ │  ↓    │ │   ↓      │ │  ↓ │ │  ↓    │
│ CoreXLSX  │ │application│ │PDFKit│ │QuickLook  │ │AVFdn│ │ no-op │
│ + Foundatn│ │(_:open:)  │ │      │ │+ unsupprtd│ │     │ │       │
│   iOS     │ │   iOS     │ │ iOS  │ │   iOS     │ │ iOS │ │ iOS   │
└──────────┘ └──────────┘ └──────┘ └──────────┘ └────┘ └───────┘
                    Same channel names, native iOS implementations
```

**Key principle**: Register the **exact same 6 method channel names** in `AppDelegate.swift` that are registered in `MainActivity.kt`. The Dart code calls channels by name — it doesn't know or care which platform is handling them.

---

## Phase 0: Prerequisites

### 0.1 Apple Developer Account
- [ ] Free Apple ID already configured (basic device deployment)
- [ ] Paid developer program submission submitted
- [ ] **Wait for approval** (1-2 days) before TestFlight distribution
- [ ] Until then: can build & install via Xcode directly (free account = 7-day signing)

### 0.2 Environment Verification
- [ ] Verify Xcode 26.5 is installed → `xcodebuild -version`
- [ ] Verify command line tools → `xcode-select -p`
- [ ] Accept Xcode license → `sudo xcodebuild -license accept`
- [ ] Verify Flutter iOS toolchain → `flutter doctor -v` (check iOS section)
- [ ] iPhone detected via USB → `xcrun xctrace list devices` (confirmed: `iPhone (26.5)`)

### 0.3 Code Signing Setup (Free/Paid Apple ID)
- [ ] Open Xcode workspace: `open ios/Runner.xcworkspace`
- [ ] Select `Runner` target → `Signing & Capabilities` tab
- [ ] Set "Team" to your Apple ID / Developer team
- [ ] Set "Bundle Identifier" to `com.fadseclab.fadocx` (already configured)
- [ ] Ensure "Automatically manage signing" is checked
- [ ] Verify provisioning profile is generated

> **Note**: With a free Apple ID, the app installs for 7 days only. With a paid developer account, it installs permanently (until next year's renewal).

---

## Phase 1: Project Configuration

### 1.1 Enable iOS in pubspec.yaml
```
File: pubspec.yaml

Change description from:
  "Offline-first document viewer for Android, macOS, Windows, and Linux"
To:
  "Offline-first document viewer for iOS, Android, macOS, Windows, and Linux"
```
- [ ] Update `pubspec.yaml:2` — add iOS to description

### 1.2 Add Required Info.plist Permissions
```
File: ios/Runner/Info.plist
```
Add these entries inside the `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Fadocx needs camera access to scan documents and capture images for OCR.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Fadocx needs photo library access to import images for OCR and document processing.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Fadocx needs permission to save processed documents and images.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Fadocx needs microphone access for video recording with audio.</string>
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

**Why**: Without these, the app will crash on first launch when any feature requests camera/photo access. `UIFileSharingEnabled` lets users access app files via iTunes/Files app — essential for the "document browser" workspace model.

- [ ] Add `NSCameraUsageDescription`
- [ ] Add `NSPhotoLibraryUsageDescription`
- [ ] Add `NSPhotoLibraryAddUsageDescription`
- [ ] Add `NSMicrophoneUsageDescription`
- [ ] Add `UIFileSharingEnabled`
- [ ] Add `LSSupportsOpeningDocumentsInPlace`

### 1.3 Register Supported Document Types (Info.plist)
```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>PDF Document</string>
        <key>LSHandlerRank</key>
        <string>Default</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.adobe.pdf</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Microsoft Office Documents</string>
        <key>LSHandlerRank</key>
        <string>Default</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>org.openxmlformats.spreadsheetml.sheet</string>
            <string>org.openxmlformats.wordprocessingml.document</string>
            <string>org.openxmlformats.presentationml.presentation</string>
            <string>com.microsoft.word.doc</string>
            <string>com.microsoft.excel.xls</string>
            <string>com.microsoft.powerpoint.ppt</string>
            <string>public.comma-separated-values-text</string>
            <string>public.plain-text</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Images</string>
        <key>LSHandlerRank</key>
        <string>Default</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.image</string>
        </array>
    </dict>
</array>
```

This registers Fadocx as a handler for these document types when opened from other apps (Files, Mail, Safari, etc.).

- [ ] Add `CFBundleDocumentTypes` for PDF
- [ ] Add `CFBundleDocumentTypes` for Office documents
- [ ] Add `CFBundleDocumentTypes` for images

### 1.4 iOS Flavors (Beta/Prod)

Android has `prod` and `beta` flavors with different bundle IDs and app names. iOS needs the same.

**Approach**: Create separate Xcode build configurations.

Files to create:
- `ios/Flutter/prod.xcconfig`
- `ios/Flutter/beta.xcconfig`

**prod.xcconfig**:
```
#include "Generated.xcconfig"
BUNDLE_ID=com.fadseclab.fadocx
APP_NAME=Fadocx
```

**beta.xcconfig**:
```
#include "Generated.xcconfig"
BUNDLE_ID=com.fadseclab.fadocx.beta
APP_NAME=Fadocx Beta
```

Then in `project.pbxproj`, configure two build configurations per scheme pointing to these xcconfigs, with different `PRODUCT_BUNDLE_IDENTIFIER` values. (Detailed Xcode project edits needed — will cross that bridge during implementation.)

- [ ] Create `ios/Flutter/prod.xcconfig`
- [ ] Create `ios/Flutter/beta.xcconfig`
- [ ] Configure Xcode project for flavor-specific bundle IDs
- [ ] Configure Xcode project for flavor-specific app names
- [ ] Verify `flutter build ios --flavor prod` and `--flavor beta` work

### 1.5 iOS App Icons
- [ ] Update `flutter_launcher_icons-beta.yaml`: change `ios: false` to `ios: true`
- [ ] Update `flutter_launcher_icons-prod.yaml`: change `ios: false` to `ios: true`
- [ ] Add iOS icon image assets (1024x1024) if needed
- [ ] Run `flutter pub run flutter_launcher_icons -f flutter_launcher_icons-prod.yaml`
- [ ] Run `flutter pub run flutter_launcher_icons -f flutter_launcher_icons-beta.yaml`

### 1.6 iOS Splash Screen
- [ ] Verify `flutter_native_splash` iOS configuration in pubspec.yaml
- [ ] Run `flutter pub run flutter_native_splash:create` to regenerate for iOS

### 1.7 pubspec.lock & Dependencies
- [ ] Run `flutter pub get` to ensure all packages resolve for iOS
- [ ] Run `cd ios && pod install --repo-update` to install CocoaPods dependencies

---

## Phase 2: Native iOS Handler Files (Swift)

This is the core of the port. We create dedicated Swift handler classes — one per platform channel — mirroring the Android architecture where `MainActivity.kt` handles all channels.

**Directory structure to create**:
```
ios/Runner/
├── AppDelegate.swift              ← Modified to register handlers
├── Handlers/
│   ├── DocumentParserHandler.swift   ← Channel: document_parser
│   ├── PdfHandler.swift              ← Channel: pdf
│   ├── LOKitHandler.swift            ← Channel: lokit
│   ├── VideoHandler.swift            ← Channel: video
│   ├── FileIntentHandler.swift       ← Channel: file_intent
│   └── AppSettingsHandler.swift      ← Channel: app_settings
├── Models/
│   └── PdfDocumentManager.swift      ← PDF state management
├── Info.plist
└── ...
```

### 2.0 AppDelegate.swift — Hub Registration
```
File: ios/Runner/AppDelegate.swift
```
Modified to register all 6 method channel handlers:

```swift
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
        
        // Register all 6 platform channel handlers
        DocumentParserHandler.register(with: controller)
        PdfHandler.register(with: controller)
        LOKitHandler.register(with: controller)
        VideoHandler.register(with: controller)
        FileIntentHandler.register(with: controller)
        AppSettingsHandler.register(with: controller)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle incoming file URLs (open-with intent)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        FileIntentHandler.setPendingFile(url)
        return super.application(app, open: url, options: options)
    }
}
```

- [ ] Create `Handlers/` and `Models/` directories under `ios/Runner/`
- [ ] Modify `AppDelegate.swift` to register all handlers
- [ ] Add `application(_:open:options:)` override for file intents

---

### 2.1 DocumentParserHandler.swift — Channel: `com.fadseclab.fadocx/document_parser`

**Android equivalent**: `MainActivity.kt` lines 71-113 (uses Apache POI via reflection)
**iOS approach**: Swift-native parsing via CoreXLSX (SPM) + Foundation

| Android (Apache POI) | iOS (Swift-native) |
|---------------------|-------------------|
| `XSSFWorkbook` / `HSSFWorkbook` | **CoreXLSX** package for `.xlsx` (SPM) |
| `HWPFDocument` / `XWPFDocument` | **NSAttributedString** with document attributes |
| CSV via `BufferedReader` | **NSString** `.components(separatedBy:)` |

#### Methods to implement:

| Method | Args | Response | iOS Implementation |
|--------|------|----------|-------------------|
| `parseDocument` | filePath, format, maxRows, maxCols, maxSheets | JSON string of parsed data | Format-specific parser |
| `isAvailable` | — | `true` | Always available |

#### Format Handling:
| Format | Library | Implementation |
|--------|---------|---------------|
| `xlsx` | **CoreXLSX** (SPM) | Open workbook → iterate shared strings → iterate rows → return JSON-serializable structure |
| `csv` | Foundation | Read file as String → split by newlines → split by commas → return rows |
| `doc` | Foundation | `NSAttributedString(fileAtPath:)` with `.docFormat` document type — extract plain text |
| `docx` | Foundation | `NSAttributedString(fileAtPath:)` with `.officeOpenXML` format (iOS 15+) — extract text |
| `xls` | **Limited** | `.xls` is binary OLE2 format. Foundation doesn't handle it directly. Two options: (a) convert via QuickLook, or (b) return unsupported error. Recommend returning structured error for .xls until a Swift solution is found. |
| `ods` | **Not supported** | Return error — no native iOS reader for OpenDocument spreadsheets |

**Dependencies**:
- CoreXLSX (via Swift Package Manager) — https://github.com/CoreOffice/CoreXLSX
- Requires Xcode project SPM integration

**Implementation Plan**:
```swift
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
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
                    return
                }
                parseDocument(filePath: filePath, format: format, args: args, result: result)
            case "isAvailable":
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private static func parseDocument(filePath: String, format: String, args: [String: Any], result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: filePath)
        
        switch format.lowercased() {
        case "xlsx":
            parseXLSX(url: url, args: args, result: result)
        case "csv":
            parseCSV(url: url, args: args, result: result)
        case "doc", "docx":
            parseWordDocument(url: url, format: format, result: result)
        default:
            result(FlutterError(code: "UNSUPPORTED_FORMAT", message: "Format \(format) not supported on iOS", details: nil))
        }
    }
}
```

- [ ] Create `Handlers/DocumentParserHandler.swift`
- [ ] Implement `parseXLSX()` using CoreXLSX
- [ ] Implement `parseCSV()` using Foundation
- [ ] Implement `parseWordDocument()` using NSAttributedString
- [ ] Add CoreXLSX via SPM in Xcode
- [ ] Register handler in AppDelegate
- [ ] Test with sample .xlsx, .csv, .docx, .doc files

---

### 2.2 PdfHandler.swift — Channel: `com.fadseclab.fadocx/pdf`

**Android equivalent**: `MainActivity.kt` lines 125-163 (uses Android `PdfRenderer`)
**iOS approach**: `PDFKit` framework (built-in, no external deps)

PDFKit is Apple's first-party PDF framework — extremely capable:
- `PDFDocument` — load, save, page count
- `PDFPage` — render thumbnails, extract text, get bounds
- Built-in, zero dependencies

| Android (PdfRenderer) | iOS (PDFKit) |
|-----------------------|-------------|
| `PdfRenderer()` | `PDFDocument(url:)` |
| `openPage()` | `document.page(at:)` |
| `render()` + `Bitmap` | `page.thumbnail(of:for:)` |
| `getPageCount()` | `document.pageCount` |
| `close()` | Deinit / nil the document |

#### Methods to implement:

| Method | Args | Response | iOS Implementation |
|--------|------|----------|-------------------|
| `openPdf` | filePath | success | `PDFDocument(url:)` — store in dictionary |
| `closePdf` | filePath | success | Remove from dictionary |
| `getPageCount` | filePath | Int | `document.pageCount` |
| `renderPage` | filePath, pageNumber, width, height | FlutterStandardTypedData (PNG bytes) | `page.thumbnail(of: for:)` → PNG data |
| `extractPageText` | filePath, pageNumber | String | `page.attributedString` or `document.string` |
| `extractTextWithPositions` | filePath, pageNumber | JSON array of {text, x, y, w, h} | Use `PDFPage.selections(for:)` + bounding boxes |
| `getPageSize` | filePath, pageNumber | {width, height} | `page.bounds(for:)` |

**State management**: Maintain a dictionary of open `PDFDocument` instances (matching Android's `pdfRenderers` map).

```swift
class PdfHandler {
    private static var documents: [String: PDFDocument] = [:]
    
    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/pdf",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { call, result in
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", ...))
                return
            }
            switch call.method {
            case "openPdf": openPdf(args: args, result: result)
            case "closePdf": closePdf(args: args, result: result)
            case "getPageCount": getPageCount(args: args, result: result)
            case "renderPage": renderPage(args: args, result: result)
            case "extractPageText": extractPageText(args: args, result: result)
            case "extractTextWithPositions": extractTextWithPositions(args: args, result: result)
            case "getPageSize": getPageSize(args: args, result: result)
            default: result(FlutterMethodNotImplemented)
            }
        }
    }
}
```

- [ ] Create `Handlers/PdfHandler.swift`
- [ ] Implement `openPdf` / `closePdf` (document state management)
- [ ] Implement `getPageCount` (PDFDocument.pageCount)
- [ ] Implement `renderPage` (PDFPage.thumbnail → PNG)
- [ ] Implement `extractPageText` (PDFPage.attributedString)
- [ ] Implement `extractTextWithPositions` (PDFPage.selections + bounds)
- [ ] Implement `getPageSize` (PDFPage.bounds(for:))
- [ ] Register handler in AppDelegate
- [ ] Test with multi-page PDF

---

### 2.3 VideoHandler.swift — Channel: `com.fadseclab.fadocx/video`

**Android equivalent**: `MainActivity.kt` lines 282-309 (uses `MediaMetadataRetriever`)
**iOS approach**: `AVFoundation` — `AVAssetImageGenerator`

| Android (MediaMetadataRetriever) | iOS (AVFoundation) |
|----------------------------------|-------------------|
| `MediaMetadataRetriever()` | `AVAsset(url:)` + `AVAssetImageGenerator` |
| `.setDataSource(filePath)` | `AVAsset(url:)` |
| `.getFrameAtTime(timeUs)` | `generator.copyCGImage(at:)` |
| `Bitmap.compress(PNG)` | `UIImagePNGRepresentation` |

#### Methods to implement:

| Method | Args | Response | iOS Implementation |
|--------|------|----------|-------------------|
| `extractVideoFrame` | filePath, timeUs | FlutterStandardTypedData (PNG bytes) | `AVAssetImageGenerator.copyCGImage(at: actualTime:)` → UIImage → PNG data |

```swift
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
                    result(FlutterError(code: "INVALID_ARGS", ...))
                    return
                }
                let timeUs = (args["timeUs"] as? NSNumber)?.int64Value ?? 0
                extractFrame(filePath: filePath, timeUs: timeUs, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private static func extractFrame(filePath: String, timeUs: Int64, result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: filePath)
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(value: timeUs, timescale: 1_000_000)
        
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
            if let image = image {
                let uiImage = UIImage(cgImage: image)
                if let data = uiImage.pngData() {
                    result(FlutterStandardTypedData(bytes: data))
                } else {
                    result(FlutterError(code: "ENCODE_FAILED", ...))
                }
            } else {
                result(FlutterError(code: "EXTRACTION_FAILED", message: error?.localizedDescription, details: nil))
            }
        }
    }
}
```

> **Note**: `generateCGImagesAsynchronously` is the preferred API. For the blocking/sync version, use `copyCGImage(at:actualTime:)`. Match whichever pattern the Dart side expects (sync vs async — the channel itself is inherently async).

- [ ] Create `Handlers/VideoHandler.swift`
- [ ] Implement `extractFrame` using `AVAssetImageGenerator`
- [ ] Register handler in AppDelegate
- [ ] Test with .mp4 file

---

### 2.4 LOKitHandler.swift — Channel: `com.fadseclab.fadocx/lokit`

**Android equivalent**: `MainActivity.kt` lines 165-268 (uses LibreOfficeKit JNI)
**iOS approach**: **QuickLook** for compatible formats + unsupported error for ODP/ODS

**Critical constraint**: LibreOffice does not compile for iOS. There is no native C++ library for rendering ODP/ODS/PPT/PPTX on iOS. However, Apple's **QuickLook framework** (`QLPreviewController`) can render:
- ✅ Microsoft Office: PPT, PPTX, DOC, DOCX, XLS, XLSX
- ✅ PDF, images, text, RTF
- ❌ OpenDocument: ODP, ODS, ODG, ODT

#### Architecture Decision

On Android, LibreOfficeKit renders documents page-by-page as raw bitmaps, and the Flutter widget assembles them into a custom viewer. On iOS, we cannot do this. Instead:

**For QuickLook-supported formats** (PPT, PPTX, DOC, DOCX, XLS, XLSX):
- The LOKit channel handler will detect the format and **present QLPreviewController natively** from the Swift side
- `loadDocument` → opens QLPreviewController as a full-screen modal → returns success
- `renderPage`, `getPageCount`, etc. → return empty/zero (QuickLook handles all rendering)
- The Flutter viewer widget receives back a response that tells it "handled natively, no rendering needed"

**For unsupported formats** (ODP, ODS):
- `loadDocument` returns error: "FORMAT_NOT_SUPPORTED"
- Flutter widget shows user-friendly error

**Alternative (simpler) approach**: Add a new dedicated method channel `com.fadseclab.fadocx/quicklook` on iOS only, and have the Flutter viewer screen detect iOS and use this channel instead of the LOKit channel. But this requires Dart changes. Since the user wants native iOS channel handlers, the cleanest path is:
1. LOKit channel on iOS handles `loadDocument` by opening QuickLook and returning a special response
2. The existing Flutter viewer widget needs minimal modification to detect this response

| Android (LibreOfficeKit) | iOS (QuickLook) |
|--------------------------|-----------------|
| `LOKitWrapper.init()` | No-op on iOS |
| `loadDocument(path)` | Present QLPreviewController, return "handled_by_quicklook" |
| `renderPage(part, w, h)` | Return empty (no pixel-by-pixel rendering) |
| `getPageCount()` | Return 0 (rendered by QuickLook, not page-by-page) |
| `closeDocument()` | Dismiss QLPreviewController |

```swift
class LOKitHandler: NSObject, QLPreviewControllerDataSource {
    private static var previewURL: URL?
    private static var previewController: QLPreviewController?
    
    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/lokit",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "init":
                result(true)  // "init" always succeeds
            case "loadDocument":
                guard let args = call.arguments as? [String: Any],
                      let filePath = args["filePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", ...))
                    return
                }
                loadDocument(filePath: filePath, controller: controller, result: result)
            case "renderPage", "renderPageFit", "renderPageHighQuality", "renderTextPage":
                result(["bytes": FlutterStandardTypedData(bytes: Data()), "part": 0, "width": 0, "height": 0])
            case "getDocumentInfo":
                result(["parts": 0, "documentParts": 0, "pages": 0, "pageSize": ["width": 0, "height": 0]])
            case "getPageCount":
                result(0)
            case "extractText", "extractPartText":
                result("")
            case "closeDocument":
                previewController?.dismiss(animated: true)
                previewURL = nil
                result(true)
            case "destroy":
                previewURL = nil
                previewController = nil
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private static func loadDocument(filePath: String, controller: FlutterViewController, result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: filePath)
        let ext = url.pathExtension.lowercased()
        
        // Formats QuickLook can handle
        let quickLookFormats = ["ppt", "pptx", "doc", "docx", "xls", "xlsx", "pdf", "rtf", "txt", "csv"]
        
        if quickLookFormats.contains(ext) {
            previewURL = url
            let qlController = QLPreviewController()
            qlController.dataSource = LOKitHandler.shared
            controller.present(qlController, animated: true)
            previewController = qlController
            result(true)
        } else {
            // ODP, ODS, etc. — not supported on iOS
            result(FlutterError(
                code: "FORMAT_NOT_SUPPORTED",
                message: "\(ext.uppercased()) files are not supported on iOS. Use a Mac or Android device to view this format.",
                details: nil
            ))
        }
    }
    
    // QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        LOKitHandler.previewURL! as NSURL
    }
}
```

- [ ] Create `Handlers/LOKitHandler.swift`
- [ ] Implement QuickLook presentation for compatible formats
- [ ] Implement format detection (PPT/PPTX/DOC/DOCX/XLS/XLSX → QuickLook, ODP/ODS → error)
- [ ] Register handler in AppDelegate
- [ ] Coordinate with Flutter viewer widget behavior (handling "handled_natively" response)

---

### 2.5 FileIntentHandler.swift — Channel: `com.fadseclab.fadocx/file_intent`

**Android equivalent**: `MainActivity.kt` lines 115-123 + `handleFileIntent()` method
**iOS approach**: `UIApplicationDelegate.application(_:open:options:)` in AppDelegate

| Android (Intent) | iOS (AppDelegate) |
|------------------|-------------------|
| `intent.action == ACTION_VIEW` | `application(_:open:options:)` |
| `intent.data` → file URI | `url` parameter (file URL) |
| Copy to app storage | Copy from temporary inbox to Documents |

#### Methods to implement:

| Method | Args | Response | iOS Implementation |
|--------|------|----------|-------------------|
| `getOpenFileIntent` | — | `{filePath: string}` or null | Return most recently opened file URL (then clear) |

```swift
class FileIntentHandler {
    private static var pendingFileURL: URL?
    
    static func setPendingFile(_ url: URL) {
        // Copy file from temporary inbox to app's Documents directory
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destination = documentsDir.appendingPathComponent(url.lastPathComponent)
        
        try? FileManager.default.copyItem(at: url, to: destination)
        pendingFileURL = destination
    }
    
    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/file_intent",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getOpenFileIntent":
                let filePath = pendingFileURL?.path
                pendingFileURL = nil  // Clear after reading
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
```

> **Important**: When iOS opens a file in Fadocx (from Files app, Mail, etc.), the system places it in a temporary "Inbox" directory. Our handler copies it to the app's Documents directory for persistent access before returning the path.

- [ ] Create `Handlers/FileIntentHandler.swift`
- [ ] Implement `setPendingFile()` with inbox → Documents copy logic
- [ ] Implement `getOpenFileIntent` channel method
- [ ] Wire `application(_:open:options:)` in AppDelegate
- [ ] Register handler in AppDelegate

---

### 2.6 AppSettingsHandler.swift — Channel: `com.fadseclab.fadocx/app_settings`

**Android equivalent**: `MainActivity.kt` lines 271-280 (opens `MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` settings)
**iOS approach**: **No-op** — iOS has no equivalent concept. The app operates in a sandbox with no external storage access.

| Android | iOS |
|---------|-----|
| `Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` | Sandboxed — no file management settings. Return success (do nothing). |

#### Methods to implement:

| Method | Args | Response | iOS Implementation |
|--------|------|----------|-------------------|
| `openManageAllFilesSettings` | — | null | No-op (iOS is sandboxed, no settings to open) |

```swift
class AppSettingsHandler {
    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.fadseclab.fadocx/app_settings",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "openManageAllFilesSettings":
                // iOS is sandboxed — no equivalent settings page
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
```

- [ ] Create `Handlers/AppSettingsHandler.swift`
- [ ] Implement `openManageAllFilesSettings` as no-op
- [ ] Register handler in AppDelegate

---

## Phase 3: Storage & File Browsing (iOS Sandbox Adaptation)

This requires Dart-level changes (unlike the platform channels above where only the native side changes). The storage model is fundamentally different.

### 3.1 Storage Service
**File**: `lib/core/services/storage_service.dart`

On Android, `getExternalStorageDirectories()` returns paths like `/storage/emulated/0/Documents`. On iOS, the app is sandboxed.

**iOS approach**: Use `getApplicationDocumentsDirectory()` for the app sandbox and optionally use `UIDocumentPickerViewController` (called from native side) to let users import files.

**Change needed**: `StorageService` needs to detect the platform and use the correct path provider API.

```dart
// Current Android-only:
final dirs = await getExternalStorageDirectories(type: StorageDirectory.documents);

// iOS-compatible:
import 'dart:io' show Platform;
import 'package:path_provider/path_provider.dart';

Future<List<Directory>> getStorageDirectories() async {
  if (Platform.isAndroid) {
    return await getExternalStorageDirectories(type: StorageDirectory.documents);
  } else {
    return [await getApplicationDocumentsDirectory()];
  }
}
```

- [ ] Update `StorageService` to handle iOS paths
- [ ] Ensure forward-slash path handling is compatible (iOS uses same POSIX paths)

### 3.2 Browse Screen
**File**: `lib/features/home/presentation/screens/browse_screen.dart`

Android scans fixed paths like `/storage/emulated/0/Documents`. iOS cannot scan the system filesystem.

**iOS approach**: 
- Read the app's sandbox `Documents` directory (files imported via UIDocumentPicker or received via open-with intent)
- Use `UIDocumentPickerViewController` (from native channel) to let users import files from Files app

**Change needed**: On iOS, the browse screen reads from the app's sandbox and provides an "Import" button that triggers `UIDocumentPickerViewController`.

- [ ] Add iOS-specific document directory scanning in BrowseScreen
- [ ] Create new channel or method for triggering `UIDocumentPickerViewController` from Dart (or use existing `file_picker` plugin)

### 3.3 Path Display
**File**: `lib/features/home/presentation/screens/browse_screen.dart` line 98

Current code:
```dart
Platform.isAndroid ? '/storage/emulated/0' : Platform.environment['HOME']
```

On iOS, `Platform.environment['HOME']` may not be reliable. Better to use the path_provider directory.

- [ ] Update path shortening logic for iOS

---

## Phase 4: Flutter/Dart Adjustments

### 4.1 Import platform detection
- [ ] Ensure `dart:io` imports are clean (they already exist in needed files)
- [ ] Add `Platform.isIOS` checks where needed (e.g., viewer routing)

### 4.2 Viewer Screen for iOS
- [ ] In `viewer_screen.dart` or `lokit_viewer_notifier.dart`, add logic to detect iOS
- [ ] On iOS, skip LOKit page-by-page rendering (since QuickLook handles it natively)
- [ ] Show `QLPreviewController`-compatible response handling

### 4.3 Graceful Format Unsupported
- [ ] For ODP/ODS on iOS, show a user-friendly error instead of crashing
- [ ] This can be handled in the LOKitHandler error response

### 4.4 File Picker Integration
- [ ] Use `file_picker` plugin's `openFile()` on iOS (already works)
- [ ] Verify it integrates with the document viewer flow

---

## Phase 5: Build & Deploy

### 5.1 Pod Dependencies
- [ ] Run `cd ios && pod install --repo-update`
- [ ] Verify all pods resolve (check Podfile.lock)

### 5.2 Swift Package Manager
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Add CoreXLSX via File → Add Package Dependencies → `https://github.com/CoreOffice/CoreXLSX`
- [ ] Verify Swift build succeeds

### 5.3 First Build (Debug)
```bash
# Build for iOS simulator (for testing without device)
flutter build ios --debug --simulator

# Build for connected iPhone (debug)
flutter run

# Or build .app for manual install
flutter build ios --debug
```
- [ ] Build for simulator → verify compilation
- [ ] Build for device with free Apple ID → verify signing
- [ ] Install on iPhone via Xcode or `flutter run`

### 5.4 Test Core Features
- [ ] App launches without crash
- [ ] PDF viewing works
- [ ] Camera/photo access works (permissions)
- [ ] Image viewing works
- [ ] OCR works
- [ ] Audio/video playback works
- [ ] XLSX document parsing works
- [ ] CSV document parsing works
- [ ] PPT/PPTX opens in QuickLook
- [ ] DOC/DOCX opens/parses
- [ ] ODP/ODS shows "unsupported" gracefully

### 5.5 Release Build (After Apple Developer approval)
```bash
# Production release
flutter build ios --flavor prod --release

# Beta release  
flutter build ios --flavor beta --release
```
- [ ] Build release for prod flavor
- [ ] Build release for beta flavor
- [ ] Validate archive in Xcode Organizer
- [ ] Deploy via TestFlight for beta testing
- [ ] Submit to App Store Connect

---

## iOS Frameworks Reference

| iOS Framework | Purpose | Built-in? | Docs |
|--------------|---------|-----------|------|
| **PDFKit** | PDF rendering, thumbnails, text extraction | ✅ Built-in (iOS 11+) | [PDFKit](https://developer.apple.com/documentation/pdfkit) |
| **AVFoundation** | Video frame extraction, audio/video playback | ✅ Built-in | [AVFoundation](https://developer.apple.com/documentation/avfoundation) |
| **QuickLook** | Preview Office docs, PDFs, images (native viewer) | ✅ Built-in | [QuickLook](https://developer.apple.com/documentation/quicklook) |
| **CoreXLSX** | Read .xlsx files (Swift library) | ❌ SPM package | [CoreXLSX](https://github.com/CoreOffice/CoreXLSX) |
| **Foundation** | CSV parsing, document text extraction via NSAttributedString | ✅ Built-in | [NSAttributedString](https://developer.apple.com/documentation/foundation/nsattributedstring) |

---

## Channel Map Summary

| # | Channel Name | Android Implementation | iOS Implementation | Status |
|---|-------------|----------------------|--------------------|--------|
| 1 | `com.fadseclab.fadocx/document_parser` | Apache POI (Java) | CoreXLSX + NSAttributedString (Swift) | 📋 Plan |
| 2 | `com.fadseclab.fadocx/pdf` | PdfRenderer (Java) | PDFKit (Swift) | 📋 Plan |
| 3 | `com.fadseclab.fadocx/lokit` | LibreOfficeKit (JNI C++) | QuickLook (Swift) | 📋 Plan |
| 4 | `com.fadseclab.fadocx/video` | MediaMetadataRetriever (Java) | AVAssetImageGenerator (Swift) | 📋 Plan |
| 5 | `com.fadseclab.fadocx/file_intent` | Intent (Java) | application(_:open:) (Swift) | 📋 Plan |
| 6 | `com.fadseclab.fadocx/app_settings` | Settings Intent (Java) | No-op (Swift) | 📋 Plan |

---

## File Change Summary

### New Files to Create (iOS Native)
| File | Purpose |
|------|---------|
| `ios/Runner/Handlers/DocumentParserHandler.swift` | Document parsing via CoreXLSX + Foundation |
| `ios/Runner/Handlers/PdfHandler.swift` | PDF operations via PDFKit |
| `ios/Runner/Handlers/LOKitHandler.swift` | QuickLook-based document viewing |
| `ios/Runner/Handlers/VideoHandler.swift` | Video frame extraction via AVFoundation |
| `ios/Runner/Handlers/FileIntentHandler.swift` | File open-with handling |
| `ios/Runner/Handlers/AppSettingsHandler.swift` | No-op app settings |
| `ios/Runner/Models/PdfDocumentManager.swift` | PDF document state management |
| `ios/Flutter/prod.xcconfig` | Prod flavor config |
| `ios/Flutter/beta.xcconfig` | Beta flavor config |

### Existing Files to Modify
| File | Changes |
|------|---------|
| `ios/Runner/AppDelegate.swift` | Register all 6 handlers, add open URL handler |
| `ios/Runner/Info.plist` | Add camera/photo permissions, document types, file sharing |
| `pubspec.yaml` | Update description, iOS icon config |
| `flutter_launcher_icons-prod.yaml` | Set `ios: true` |
| `flutter_launcher_icons-beta.yaml` | Set `ios: true` |
| `lib/core/services/storage_service.dart` | Add iOS path support |
| `lib/features/home/presentation/screens/browse_screen.dart` | iOS path display + document picker |

### Files NOT to Touch
| File | Why |
|------|-----|
| `android/app/src/main/kotlin/com/fadseclab/fadocx/MainActivity.kt` | Android native code — must remain unchanged |
| `android/` (any file) | Entire Android directory untouched |
| `lib/features/viewer/data/services/lokit_service.dart` | Works as-is; channel calls same on iOS |
| `lib/features/viewer/presentation/providers/lokit_viewer_notifier.dart` | Works as-is if channel response format is compatible |
| Any `.kt` or `.java` file | Android codebase untouched |

---

## Testing Checklist (Post-Implementation)

### Basic
- [ ] App icon appears correctly on iPhone
- [ ] App launches without crash
- [ ] Splash screen displays correctly
- [ ] Navigation works (tabs, drawers)

### PDF
- [ ] PDF opens and displays
- [ ] PDF pages render correctly
- [ ] PDF thumbnail generation works
- [ ] PDF text extraction works
- [ ] PDF page count is accurate
- [ ] PDF page navigation works

### Document Parsing
- [ ] XLSX file parses correctly (rows, sheets)
- [ ] CSV file parses correctly
- [ ] DOC file extracts text
- [ ] DOCX file extracts text

### Office Documents (QuickLook)
- [ ] PPT opens in QuickLook
- [ ] PPTX opens in QuickLook
- [ ] DOC/DOCX opens in QuickLook
- [ ] XLS/XLSX opens in QuickLook
- [ ] QLPreviewController dismisses correctly
- [ ] ODP shows unsupported error
- [ ] ODS shows unsupported error

### Camera & Photos
- [ ] Camera permission dialog appears
- [ ] Camera capture works
- [ ] Photo library permission dialog appears
- [ ] Image picker works
- [ ] OCR works on captured images

### Media
- [ ] Video playback works
- [ ] Video thumbnail extraction works
- [ ] Audio playback works

### File Management
- [ ] Open PDF from Files app → opens in Fadocx
- [ ] Open XLSX from Files app → opens in Fadocx
- [ ] Browse app sandbox documents
- [ ] File picker imports documents

### Performance
- [ ] App memory usage is reasonable
- [ ] Large PDFs load without crashing
- [ ] Video frame extraction completes in reasonable time

---

## Pro Tips

1. **Test early, test often**: After Phase 2 (even 1-2 handlers), do a test build. Don't wait until all 6 are done.

2. **Swift Concurrency**: iOS handlers can use `async/await` for readability. The channel callback (`result`) must be called on the main thread — use `DispatchQueue.main.async` or `await MainActor.run`.

3. **Channel response types**: Flutter's `MethodChannel` passes data through `NSJSONSerialization` + custom codecs. Ensure all maps, arrays, strings, numbers, and `FlutterStandardTypedData` (for byte data) are used consistently — match the Android response format exactly.

4. **Xcode playground for quick prototyping**: Before wiring into Flutter, test PDFKit/CoreXLSX/AVFoundation code in an Xcode playground to verify logic.

5. **Fastlane for TestFlight**: Once the developer account is approved, set up Fastlane for streamlined TestFlight deployment (see `fastlane/` directory if it exists, or create one).

6. **`flutter analyze`**: After any Dart changes, run `flutter analyze` to catch type/lint issues. No new lint errors should be introduced.

7. **`flutter build ios --no-codesign`**: For quick compilation-only checks (no device connected), use `--no-codesign` to skip the signing step.

---

> **Progress Tracker**
>
> Total items: ~75 checkable boxes
>
> Phase 0: ✅ Complete (Xcode signing pending — user will do at end)
> Phase 1: ✅ Complete
>   - 1.1 Description updated ✅
>   - 1.2 Info.plist permissions ✅
>   - 1.3 Document types ✅
>   - 1.4 Flavors skipped (iOS prod-only) ✅
>   - 1.5 App icons configured (prod only) ✅
>   - 1.6 Splash screen regenerated ✅
>   - 1.7 `flutter pub get` + `pod install` ✅
> Phase 2: ✅ Complete (all 6 handlers + AppDelegate)
>   - 2.0 AppDelegate.swift — 6 handler registrations + open URL handler ✅
>   - 2.1 DocumentParserHandler.swift — CoreXLSX stub + CSV + DOC/DOCX ✅
>   - 2.2 PdfHandler.swift — PDFKit full implementation ✅
>   - 2.3 VideoHandler.swift — AVFoundation frame extraction ✅
>   - 2.4 LOKitHandler.swift — QuickLook + unsupported format error ✅
>   - 2.5 FileIntentHandler.swift — open-with file handling ✅
>   - 2.6 AppSettingsHandler.swift — no-op ✅
> Phase 3: ✅ Complete
>   - 3.1 StorageService — iOS `getApplicationDocumentsDirectory()` ✅
>   - 3.2 BrowseScreen — iOS sandbox scan, skip permissions ✅
>   - 3.3 Path display — iOS-friendly short path ✅
> Phase 4: ✅ Complete (LOKit handled by QuickLook natively, no Dart changes needed)
> Phase 5: ⏳ Blocked — iOS 26.5 platform needs to finish downloading in Xcode
>   - Website: Open Xcode → Settings → Components → iOS 26.5 (download)
>   - Signing: Set Apple ID team in Runner target
>   - SPM: Add CoreXLSX package
