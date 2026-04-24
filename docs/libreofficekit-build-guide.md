# LibreOfficeKit Android Build Guide

## Overview
Build LibreOffice core for Android to produce `liblo-native-code.so` for Fadocx document viewing and editing.

## Prerequisites

| Requirement | Minimum |
|---|---|
| OS | x86_64 Linux (Ubuntu/Debian/Kali amd64) |
| Disk | 50 GB free on build partition |
| RAM | 16 GB |
| CPU | 4+ cores |
| NDK | r27c |
| SDK | Android command-line tools + platforms;android-34 + build-tools;34.0.0 |
| Java | OpenJDK 17+ |
| Ant | Apache Ant (for Java extensions build) |

Verify architecture first:
```bash
uname -m   # MUST output: x86_64
df -h /    # Need 50GB+ free
```

## Step 1 — Install Build Dependencies

```bash
sudo apt update
sudo apt install -y build-essential git autoconf automake libtool pkg-config \
  libx11-dev libxext-dev libxrender-dev libxt-dev libxrandr-dev \
  libgl1-mesa-dev libglu1-mesa-dev libfontconfig1-dev \
  gperf bison flex libxml2-utils wget unzip ant openjdk-17-jdk
```

## Step 2 — Download Android NDK (r27c)

```bash
mkdir -p /mnt/linux2/lokit-build
cd /mnt/linux2/lokit-build
wget https://dl.google.com/android/repository/android-ndk-r27c-linux.zip
unzip android-ndk-r27c-linux.zip
```

## Step 3 — Setup Android SDK

If `~/Android/Sdk` already exists as a directory with platforms/build-tools, skip this step.

```bash
# If ~/Android/Sdk is a file (not directory), remove it first:
rm -f ~/Android/Sdk

# Download and install command-line tools
cd /mnt/linux2/lokit-build
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
mkdir -p ~/Android/Sdk/cmdline-tools
unzip commandlinetools-linux-11076708_latest.zip -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest

# Install required components
yes | ~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager \
  --sdk_root=$HOME/Android/Sdk \
  "platforms;android-34" "build-tools;34.0.0" "platform-tools"

# Verify
ls ~/Android/Sdk/platforms/   # Should show: android-34/
ls ~/Android/Sdk/build-tools/  # Should show: 34.0.0/
```

## Step 4 — Clone LibreOffice Core

```bash
cd /mnt/linux2/lokit-build
git clone https://github.com/LibreOffice/core.git --depth=1
cd core
```

## Step 5 — Configure

```bash
./autogen.sh \
  --with-distro=LibreOfficeAndroidAarch64 \
  --with-android-ndk=/mnt/linux2/lokit-build/android-ndk-r27c \
  --with-android-sdk=$HOME/Android/Sdk
```

For armv7 (second ABI), use `--with-distro=LibreOfficeAndroidArmv7`.

## Step 6 — Build

```bash
make -j$(nproc)
```

Duration: 2-6 hours. Output: `liblo-native-code.so` in build directory.

## Step 7 — Extract Artifacts

```bash
find . -name "liblo-native-code.so" -type f
find instdir/ -name "*.so" -type f -exec ls -lh {} \;
```

## Step 8 — Smoke Test

1. Copy `liblo-native-code.so` into Android app `jniLibs/arm64-v8a/`
2. Load via JNI: `System.loadLibrary("lo-native-code")`
3. Call `libreofficekit_hook_2()` then `documentLoad()` on a test DOCX
4. Verify page count returns

## Troubleshooting

| Error | Fix |
|---|---|
| `--with-android-ndk is mandatory` | Pass `--with-android-ndk=/path` or symlink to `external/android-ndk/` |
| `--with-android-sdk is mandatory` | Pass `--with-android-sdk=/path` or symlink to `external/android-sdk-linux/` |
| `NDK version >= 27.* required` | Download NDK r27c+ |
| `does not point to an Android SDK` | Run `sdkmanager "platforms;android-34" "build-tools;34.0.0"` |
| `no flex found in $PATH` | `sudo apt install -y flex` |
| `Ant not found` | `sudo apt install -y ant` |
| `C compiler cannot create executables` | Host is aarch64 — must use x86_64/amd64 machine |
| `~/Android/Sdk: Not a directory` | `rm ~/Android/Sdk` (it's a file), then re-run SDK install steps |
| Out of memory during linking | Add 16G swap: `sudo fallocate -l 16G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile` |
| Build fails at specific module | `make clean` in that module, retry |

## Reference Links

- https://github.com/LibreOffice/core/blob/master/android/README.md
- https://collaboraonline.github.io/post/build-code-android/
- https://wiki.documentfoundation.org/Development/BuildingForAndroid
