# Developer & Agent Guide: Fadocx Optimization

## Managing pdfrx WASM Modules (Size Optimization)
The `pdfrx` library bundles a 4MB WASM module for web support, which is unnecessary for Android/Native builds.

### To Remove (Pre-Build)
Run this command after `flutter pub get` and before `flutter build`:
```bash
dart run pdfrx:remove_wasm_modules
```

### To Restore (For Web Support)
```bash
dart run pdfrx:remove_wasm_modules --revert
```

## Startup Optimization Best Practices
1. **Zero-Dependency MainActivity:** Ensure `MainActivity.kt` has ZERO direct imports of heavy third-party libraries (POI, PDFBox). Use reflection for initialization and method channel handlers to keep the classloader from hitting bottlenecks.
2. **Reflection-based Lazy Loading:** Load heavy parser classes only when their specific MethodChannel is called.
3. **Optimized Gradle Properties:** Use `android.enableR8.fullMode=true` and `org.gradle.jvmargs` with sufficient memory to speed up DEXing and shrinking.
4. **Hive Boxes:** Only open `settings` box in `main()`. Defer `recent_files` and `cache` boxes until needed.
5. **UI Deferral:** In `HomeScreen`, use `WidgetsBinding.instance.addPostFrameCallback` to defer data loading until the first frame is rendered.

## Flutter Best Practices
1. **State Management:** Use Riverpod `Notifier` or `AsyncNotifier`. Avoid legacy `StateNotifier`.
2. **UI Performance:** Use `const` constructors everywhere possible. Avoid heavy logic in `build()` methods.
3. **Clean Architecture:** Strictly separate layers: `Presentation` (Widgets), `Domain` (Entities/Logic), and `Data` (Repositories/DataSources).
4. **Localization:** Never hardcode strings. Use `AppLocalizations.of(context)!` via `.arb` files.
5. **Error Handling:** Use `Result` patterns (Success/Failure) in Repositories to handle exceptions gracefully without crashing.

## Android Native Best Practices
1. **Thread Management:** Always run heavy I/O or parsing (POI, PDFBox) on background threads. Use `runOnUiThread` for returning results to Flutter.
2. **ProGuard/R8:** Maintain `proguard-rules.pro` to prevent reflection-based classes (like `NativeDocumentParser`) from being stripped or renamed.
3. **Manifest:** Ensure all `intent-filter` configurations are precise to avoid unnecessary app launches.
4. **Permissions:** Check and request permissions (Camera, Storage) via Flutter's `permission_handler` before calling native code.

## App Icon & Splash Screen Update Workflow
When updating app branding or icons, follow this workflow:

### 1. Update App Launcher Icon
- **File:** `assets/fadocx.png` (1:1 square ratio, minimum 1024x1024px recommended)
- **After update:** Run `flutter pub run flutter_launcher_icons` to generate platform-specific launcher icons
- **Generates:** Android `mipmap-*` directories and iOS `AppIcon.appiconset`

### 2. Update App Bar & Splash Screen Icon
- **File:** `assets/fadocx_header_landscape_png.png` (2:1 landscape ratio, e.g., 1024x512px)
- **Usage:** App bar header (80x32px in app) and splash screen background
- **After update:** Run `flutter pub run flutter_native_splash:create` to regenerate native splash screen
- **Generates:** Native Android and iOS splash screen assets

### 3. Configuration References
- **Launcher icons config:** `pubspec.yaml` → `flutter_launcher_icons` section
- **Splash screen config:** `pubspec.yaml` → `flutter_native_splash` section

### Important Notes
- Always update icons BEFORE running `flutter build` or `flutter pub get`
- Both commands modify native platform files; regenerate after any asset changes
- Test on both Android and iOS after regeneration to ensure correct scaling

**Agent Workflow Rules**

- **Todo First**: Always create a detailed, long todo list before starting work on any bug or feature; include edge cases, assumptions, and explicit context-gathering steps.
- **Never Assume**: Never assume—validate by gathering context (inputs, code paths, configs, etc.) before starting work.
- **Broader Research**: Use Context7 MCP for research or to broaden your search and understanding before coding or debugging.
- **Find Root Cause**: Diagnose and document the root cause before attempting fixes—avoid patching symptoms without understanding why they occur.
- **Run Analysis**: Run `flutter analyze` (or the appropriate static analysis for the project) after making changes and address reported issues before finalizing.
- **Document Decisions**: Record investigative steps, rationale, and the root-cause analysis back in the todo or the issue tracker so future reviewers see context.
