# Fadocx Build Script Guide

## Quick Start

```bash
./build.sh
```

Then select from the interactive menu.

## Architecture Support

### ✅ Supported
- **arm64-v8a** (64-bit ARM) — Pixel 7 Pro and most modern Android devices
  - All native libraries available (LibreOffice, PDFBox, Tesseract, etc.)
  - Full functionality

### ❌ Not Supported
- **armeabi-v7a** (32-bit ARM) — Missing LibreOffice native code
- **x86_64** (Intel/AMD) — Missing LibreOffice native code

**Why?** Your app requires LibreOffice native code (`liblo-native-code.so` - 203MB) which is only compiled for arm64-v8a. This is a dependency limitation, not a choice.

## Build Script Menu

### PRODUCTION BUILDS

#### Option 1: Build & Install Prod (Release)
```bash
flutter build apk --flavor prod --release --split-per-abi --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk
```
- **Flavor**: Prod (package: `com.fadseclab.fadocx`)
- **Build Type**: Release (R8 minified, optimized)
- **Size**: ~346MB
- **Use**: Testing production build on device

#### Option 2: Build Prod (Release Only)
```bash
flutter build apk --flavor prod --release --split-per-abi --target-platform android-arm64
```
- **Same as Option 1 but without installing**
- **Use**: Build for manual installation later

### BETA BUILDS

#### Option 3: Build & Install Beta (Release)
```bash
flutter build apk --flavor beta --release --split-per-abi --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-beta-release.apk
```
- **Flavor**: Beta (package: `com.fadseclab.fadocx.beta`)
- **Build Type**: Release (R8 minified, optimized)
- **Size**: ~346MB
- **Use**: Testing beta features on device
- **Note**: Can coexist with Prod on same device

#### Option 4: Build Beta (Release Only)
```bash
flutter build apk --flavor beta --release --split-per-abi --target-platform android-arm64
```
- **Same as Option 3 but without installing**
- **Use**: Build for manual installation later

### DEVELOPMENT

#### Option 5: Dev: Run Prod (Debug)
```bash
flutter run --flavor prod
```
- **Build Type**: Debug (not minified, larger ~400MB)
- **Features**: Hot reload, live debugging
- **Use**: Active development with instant feedback
- **Controls**: 
  - Press `r` to hot reload
  - Press `R` to hot restart
  - Press `q` to quit

#### Option 6: Dev: Run Beta (Debug)
```bash
flutter run --flavor beta
```
- **Same as Option 5 but for Beta flavor**
- **Use**: Testing beta-specific features during development

#### Option 7: Dev: Build Prod (Debug)
```bash
flutter build apk --flavor prod --debug --split-per-abi --target-platform android-arm64
```
- **Build Type**: Debug (not minified, larger ~400MB)
- **Use**: Build without running (manual install later)

#### Option 8: Dev: Build Beta (Debug)
```bash
flutter build apk --flavor beta --debug --split-per-abi --target-platform android-arm64
```
- **Same as Option 7 but for Beta flavor**

### MANAGEMENT

#### Option 9: Uninstall Prod
```bash
adb uninstall com.fadseclab.fadocx
```
- Removes production app from device

#### Option 0: Uninstall Beta
```bash
adb uninstall com.fadseclab.fadocx.beta
```
- Removes beta app from device

#### Option q: Exit
Closes the build script.

## Build Sizes

| Build Type | Size | Optimization | Use Case |
|-----------|------|--------------|----------|
| Release | ~346MB | R8 minification + Flutter tree-shaking | Production testing |
| Debug | ~400MB | No minification | Development |

## Flavor Differences

### Beta
- Package: `com.fadseclab.fadocx.beta`
- App Name: "Fadocx Beta"
- Icon: `assets/fadocx_beta.png`
- Can coexist with Prod on same device

### Prod
- Package: `com.fadseclab.fadocx`
- App Name: "Fadocx"
- Icon: `assets/fadocx.png`
- Production version

## Optimization Details

### R8 Minification (Release builds only)
- ✅ Enabled in release builds
- Minifies Java bytecode (POI, XMLBeans, etc.)
- Keeps critical classes unobfuscated (POI, logging, JNI)
- Reduces DEX size from 51MB → ~15-20MB

### Flutter Tree-Shaking (All builds)
- ✅ Enabled in all builds
- Removes unused Dart code
- Reduces app size by ~2-3%

### Result
- **Before optimization**: 434MB (no minification)
- **After optimization**: 346MB (with R8 + tree-shaking)
- **Savings**: 88MB (20% reduction)

## Version Code Management

Current version code: **2002**

When you build, the version code increments to prevent "downgrade detected" errors. If you see:
```
INSTALL_FAILED_VERSION_DOWNGRADE: Downgrade detected
```

Update `android/app/build.gradle.kts`:
```kotlin
val appVersionCode = 2003  // Increment this
```

## Troubleshooting

### "No devices connected"
```bash
adb devices
# Make sure your device shows up and is in "device" state
```

### "INSTALL_FAILED_NO_MATCHING_ABIS"
- Your device doesn't support arm64-v8a (very unlikely on modern devices)
- Check device architecture: `adb shell getprop ro.product.cpu.abi`

### "INSTALL_FAILED_VERSION_DOWNGRADE"
- You're trying to install an older version code
- Increment `appVersionCode` in `android/app/build.gradle.kts`

### Build takes too long
- First build: ~3-5 minutes (Gradle setup)
- Subsequent builds: ~2-3 minutes
- This is normal

### Hot reload not working (Option 5/6)
- Make sure you're using `flutter run` (not `flutter build`)
- Check that your device is connected: `adb devices`
- Some changes require hot restart (`R`) instead of hot reload (`r`)

## Commands Reference

### Manual commands (if not using script)

**Build arm64 release APK:**
```bash
flutter build apk --flavor prod --release --split-per-abi --target-platform android-arm64
```

**Build arm64 debug APK:**
```bash
flutter build apk --flavor prod --debug --split-per-abi --target-platform android-arm64
```

**Run with hot reload:**
```bash
flutter run --flavor prod
```

**Install manually:**
```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk
```

**Uninstall:**
```bash
adb uninstall com.fadseclab.fadocx
```

**View logs:**
```bash
adb logcat -s "Fadocx.DocumentParser"
```

**Check device architecture:**
```bash
adb shell getprop ro.product.cpu.abi
```

## Development Workflow

### For Active Development
1. Use **Option 5** or **Option 6** (`flutter run`)
2. Make code changes
3. Press `r` for hot reload (fast)
4. If hot reload fails, press `R` for hot restart
5. Press `q` to quit

### For Testing Release Build
1. Use **Option 1** or **Option 3** (Build & Install)
2. Test on device
3. Make changes
4. Repeat

### For Building APK to Share
1. Use **Option 2** or **Option 4** (Build only)
2. APK is ready at `build/app/outputs/flutter-apk/app-arm64-v8a-{flavor}-release.apk`
3. Share the APK file

## Next Steps

1. Run `./build.sh`
2. Select option 1 (Build & Install Prod)
3. Test all 4 formats (XLSX, XLS, DOC, DOCX)
4. Send logcat output to confirm everything works

---

**Note**: This script is interactive and shows all commands before executing them. You can see exactly what's happening at each step.

**Supported Architectures**: arm64-v8a only (64-bit ARM)
