# Developer & Agent Guide: Fadocx Optimization

## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
-Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness
  
### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

#### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

---

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

## Build Flavors

Fadocx supports two build flavors: **beta** and **prod**.

### Beta Flavor
- **Package Name:** `com.fadseclab.fadocx.beta`
- **App Name:** Fadocx Beta
- **Icon:** `assets/fadocx_beta.png`
- **Run Command:** `flutter run --flavor beta`
- **Build APK (per-ABI):** `flutter build apk --flavor beta --release --split-per-abi --target-platform android-arm,android-arm64`
- **Build APK (universal):** `flutter build apk --flavor beta --release`

### Prod Flavor
- **Package Name:** `com.fadseclab.fadocx`
- **App Name:** Fadocx
- **Icon:** `assets/fadocx.png`
- **Run Command:** `flutter run --flavor prod`
- **Build APK (per-ABI):** `flutter build apk --flavor prod --release --split-per-abi --target-platform android-arm,android-arm64`
- **Build APK (universal):** `flutter build apk --flavor prod --release`

### Size Optimization Notes
- Always use `--split-per-abi --target-platform android-arm,android-arm64` for release builds
- This generates separate APKs per architecture (arm64 ~68MB, armv7 ~59MB vs universal ~96MB)
- BouncyCastle post-quantum crypto resources are excluded via `packaging.resources.excludes` in build.gradle.kts
- `flutter run` automatically picks the correct ABI for the connected device

### Setup
- Flavors are configured in `android/app/build.gradle.kts` using `flavorDimensions` and `productFlavors`
- App name per flavor uses `manifestPlaceholders["appName"]` in build.gradle.kts
- AndroidManifest.xml references `${appName}` for `android:label`
- For iOS, create schemes in Xcode with matching bundle identifiers
- Regenerate icons after changes: `flutter pub run flutter_launcher_icons`

## Custom UI Design Patterns

### Inverted Rounded Corners (Sidebar Flares)
This pattern creates a "tab" or "sheet" that appears to grow out of a screen edge using concave (inward) curves instead of standard convex rounded corners.

**Implementation Details:**
1. **CustomPaint + Path.cubicTo**: Use `Path.cubicTo` to create smooth S-curves (flares) that transition from a screen edge into the main body of the element.
2. **Layering (Stack)**: Use a `Stack` where the background (containing the flares) is in one layer and the content is in another.
3. **ClipBehavior.none**: Ensure the parent `Stack` has `clipBehavior: Clip.none` if the flares need to extend into the "safe area" or beyond the content boundaries.
4. **Coordinate Mapping**: The body should be offset (e.g., by `radius`) to allow the flares to occupy the space above/below or to the side of the main content area.

**Visual Reference:** Similar to how Google Chrome tabs blend into the top toolbar. In Fadocx, this is used on the `ViewerScreen` sidebar to blend it into the screen's left boundary.

## Flutter Animation Best Practices

### The Golden Rule: Never Use TweenAnimationBuilder for Prop-Driven Animations
`TweenAnimationBuilder` is a **StatelessWidget wrapper** — when the parent calls `setState()`, the widget is recreated from scratch, and the animation starts fresh from `begin`. It appears as an "instant swap" instead of animating.

### Correct Pattern: StatefulWidget + AnimationController + didUpdateWidget

Use this pattern when an animation responds to a **parent prop change** (e.g., `isOpen`, `isExpanded`, `isVisible`):

```dart
class AnimatedHamburgerIcon extends StatefulWidget {
  final bool isOpen;  // Prop that drives animation
  final VoidCallback onPressed;
  
  const AnimatedHamburgerIcon({
    super.key,
    required this.isOpen,
    required this.onPressed,
  });
}

class _AnimatedHamburgerIconState extends State<AnimatedHamburgerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.isOpen ? 1.0 : 0.0,  // Start at correct value!
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedHamburgerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Use _animation.value (0.0-1.0) to drive your animation
        final factor = 0.35 + (_animation.value * 0.35);
        return CustomPaint(
          painter: HamburgerPainter(bottomLineFactor: factor),
        );
      },
    );
  }
}
```

### Why This Works
- `didUpdateWidget` fires when the parent rebuilds but the widget instance is **reused** (same key, same type)
- The `AnimationController` lives in the widget's State and **persists** through parent rebuilds
- When prop changes, `didUpdateWidget` calls `.forward()` or `.reverse()` on the existing controller — smooth animation from current value

### Common Pitfall: Race Condition with Child State
If you read the animation state from a child widget via `GlobalKey.currentState` in a getter, there's a race condition:
```dart
bool get _showSidebarDrawer {
  // Bug: reading child's state before child has rebuilt
  final viewerState = _pdfViewerKey.currentState as dynamic;
  return viewerState?.showSidebar ?? false;
}
```
Fix: Track the state directly in the parent as a simple `bool` field, updated atomically.

### Animation Performance Tips
1. **Reduce BackdropFilter sigma**: Keep blur at 8 or below (20 is very expensive)
2. **Wrap animated widgets in RepaintBoundary**: Prevents repainting the entire parent tree
3. **Avoid calling heavy build functions during animation**: Use early returns for zero values
4. **Use TickerProviderStateMixin (not SingleTickerProviderStateMixin)** when you need multiple AnimationControllers
5. **Always wrap third-party widgets with internal state in RepaintBoundary**: This prevents their expensive internal rebuilds when parent calls setState

### pdfrx Null Check Error (LayoutBuilder)
If you see `Null check operator used on a null value` in pdfrx's LayoutBuilder, it's because pdfrx's internal state is being destroyed when the parent rebuilds. Fix by:

1. Use `GlobalKey<State<ModernPdfViewer>>` (not ValueKey) - the GlobalKey persists state across rebuilds
2. Wrap the viewer in `RepaintBoundary` to isolate its repaints

```dart
late GlobalKey<State<ModernPdfViewer>> _pdfViewerKey;

@override
void initState() {
  super.initState();
  _pdfViewerKey = GlobalKey<State<ModernPdfViewer>>();
}

Widget _buildContentViewer() {
  return RepaintBoundary(
    child: ModernPdfViewer(
      key: _pdfViewerKey,
      // ...
    ),
  );
}
```

**Agent Workflow Rules**

- **Incremental Changes**: Make small, targeted edits rather than large rewrites to avoid breaking Dart syntax and minimize debugging time.
- **Logging**: Always use `import 'package:logger/logger.dart';` and add logs when debugging or adding features to track and debug easily.
- **Todo First**: Always create a detailed, long todo list before starting work on any bug or feature; include edge cases, assumptions, and explicit context-gathering steps.
- **Never Assume**: Never assume—validate by gathering context (inputs, code paths, configs, etc.) before starting work.
- **Broader Research**: Use Context7 MCP for research or to broaden your search and understanding before coding or debugging.
- **Find Root Cause**: Diagnose and document the root cause before attempting fixes—avoid patching symptoms without understanding why they occur.
- **Run Analysis**: Run `flutter analyze` (or the appropriate static analysis for the project) after making changes and address reported issues before finalizing.
- **Document Decisions**: Record investigative steps, rationale, and the root-cause analysis back in the todo or the issue tracker so future reviewers see context.
