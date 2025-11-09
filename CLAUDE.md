# KaiOS gecko-b2g Repository Analysis

## Overview

This is KaiOS Technologies' fork of mozilla-b2g/gecko-b2g, maintained as the Gecko rendering engine with Gonk (Android-based OS layer) support. This repository represents a **modern, actively maintained** B2G/Firefox OS codebase.

**Repository Status**: Active (last push: August 15, 2024)
**Branch**: gonk (default)
**Gecko Version**: 123.0a1 (February 2024)

## Android Version Support

This repository supports **multiple Android versions**, making it far more modern than the legacy mozilla-b2g codebase:

| Platform Version | Android Version | API Level | Sysroot Script | NDK Version | Status |
|-----------------|-----------------|-----------|----------------|-------------|---------|
| 23 | Android 6.0 (Marshmallow) | 23 | N/A (legacy script) | r17b | Legacy support via build-b2g_m.sh |
| 27+ | Android 8.1+ (Oreo) | 27+ | create-b2g-sysroot.sh | r21d | Supported |
| 29 | Android 10 | 29 | create-b2g-sysroot.sh | r21d | Supported |
| 30 | Android 11 | 30 | create-b2g-sysroot-aosp11.sh | r21d | Supported |
| 33 | Android 13 (Tiramisu) | 33 | create-b2g-sysroot-aosp13.sh | r25b | Supported |
| 34 | **Android 14 (Upside Down Cake)** | 34 | create-b2g-sysroot-aosp14.sh | r26c | **Fully Supported** |

### Architecture Support

All Android versions support multiple architectures:
- **ARM** (32-bit): arm-linux-androideabi
- **ARM64** (64-bit): aarch64-linux-android
- **x86** (32-bit): i686-linux-android
- **x86_64** (64-bit): x86_64-linux-android

## Key Files

### Build Scripts
- **build-b2g.sh**: Main build script for Android 27+ (supports versions 27, 29, 30, 33, 34)
- **build-b2g_m.sh**: Legacy build script specifically for Android M (API 23)
- **mozconfig-b2g**: Gecko build configuration
- **gonk.md**: Build instructions and documentation

### Sysroot Creation Scripts
Located in `taskcluster/scripts/misc/`:
- `create-b2g-sysroot.sh` - Default for Android 27, 29
- `create-b2g-sysroot-aosp11.sh` - Android 11 (API 30)
- `create-b2g-sysroot-aosp13.sh` - Android 13 (API 33)
- `create-b2g-sysroot-aosp14.sh` - Android 14 (API 34)

## Build Requirements

### Environment Variables

**Required for all builds:**
- `GONK_PATH`: Path to the root of your Gonk/Android directory
- `GONK_PRODUCT_NAME`: Device name (look at `$GONK_PATH/out/target/product`)
- `PLATFORM_VERSION`: Android API level (27, 29, 30, 33, or 34)
- `TARGET_ARCH`: Architecture (arm, arm64, x86, x86_64)

**Optional:**
- `GECKO_OBJDIR`: Custom build output directory (defaults to objdir-*)
- `VARIANT`: Set to "user" for production builds
- `CLANG_PATH`: Path to clang binaries (defaults to ~/.mozbuild/clang/bin)
- `PYTHON_PATH`: Python path (defaults to /usr/bin)

### NDK Requirements

The build system automatically uses the appropriate NDK version based on `PLATFORM_VERSION`:
- **Android 34**: NDK r26c
- **Android 33**: NDK r25b
- **Android 27-30**: NDK r21d

NDKs are expected at: `~/.mozbuild/android-ndk-<version>/`

## Build Instructions

### Option 1: Android M (API 23) - Legacy

For Android 6.0 Marshmallow support:

```bash
# Prerequisites
export GONK_PATH=/path/to/android-m-b2g
export GONK_PRODUCT_NAME=generic  # or your device name

# Bootstrap Gecko dependencies
./mach bootstrap
# Choose option 4: GeckoView/Firefox for Android

# Build
./build-b2g_m.sh
```

### Option 2: Android 14 (API 34) - Modern

For the latest Android 14 support:

```bash
# Prerequisites
export PLATFORM_VERSION=34
export GONK_PATH=/path/to/android-14-aosp
export GONK_PRODUCT_NAME=generic_arm64  # or your device
export TARGET_ARCH=arm64

# Bootstrap Gecko dependencies (first time only)
./mach bootstrap
# Choose option 4: GeckoView/Firefox for Android

# Build
./build-b2g.sh

# Package
./build-b2g.sh package
```

The build output will be in: `obj-<target-triple>/dist/b2g-*.tar.gz`

### Option 3: Android 11/13 (API 30/33) - Intermediate

Same as Option 2, but set `PLATFORM_VERSION` to 30 or 33.

## Where to Get the Android Base (GONK_PATH)

You need an Android AOSP build or a B2G Android fork. Options:

### 1. KaiOS B2G Repository
Check: https://github.com/kaiostech/B2G
This repository should have manifests for building compatible Android bases.

### 2. Build AOSP Yourself
For Android 14:
```bash
# Download AOSP
repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r1
repo sync

# Build AOSP
source build/envsetup.sh
lunch aosp_arm64-userdebug  # or your target
make -j$(nproc)
```

### 3. Existing B2G Android M
If you have the Android M B2G checkout mentioned in gonk.md:
```bash
git clone --branch emulator-m https://github.com/gabrielesvelto/B2G
cd B2G
# Follow build instructions in that repo
```

## KaiOS 4.0 Context

KaiOS 4.0 (announced December 2024, devices shipping 2025):
- **Android Base**: Android 14
- **Gecko Engine**: Version 123
- **First 5G feature phones**
- **Chipset**: Qualcomm SM4635
- **Privacy Features**: Total Cookie Protection, supercookie protections
- **New APIs**: Declarative Shadow DOM, AVIF images, Clipboard API

This repository is the **production codebase** for KaiOS 4.0, meaning it's actively maintained and tested on real devices.

## Relationship to Original B2G

**Original mozilla-b2g**:
- Last active: 2016-2017
- Android base: 5.1.1 Lollipop (with experimental Android 10)
- Gecko: Version 43
- Status: Archived and unmaintained

**This gecko-b2g fork (KaiOS)**:
- Currently active: 2024
- Android base: Up to Android 14
- Gecko: Version 123
- Status: Production use in KaiOS devices
- **9 years newer** than mozilla-b2g

## Code Version Detection

The codebase uses preprocessor checks for Android version compatibility:

```c
#if ANDROID_VERSION >= 34
    // Android 14+ code
#elif ANDROID_VERSION >= 30
    // Android 11+ code
#elif ANDROID_VERSION >= 23
    // Android 6+ code
#endif
```

Supported versions found in code: 17, 18, 19, 21, 22, 23, 27, 29, 30, 33, 34

## Next Steps

### Immediate Actions

1. **Choose Your Target Android Version**
   - Android M (23): Easiest to start, can use gabrielesvelto's repo
   - Android 14 (34): Most modern, requires AOSP or KaiOS partnership

2. **Get the Android Base**
   - Option A: Clone and build gabrielesvelto's B2G for Android M
   - Option B: Build AOSP 14 from scratch
   - Option C: Contact KaiOS about access to their B2G Android 14 base

3. **Set Up Build Environment**
   ```bash
   # Install dependencies
   ./mach bootstrap

   # Set environment variables
   export GONK_PATH=/your/android/path
   export GONK_PRODUCT_NAME=generic
   export PLATFORM_VERSION=34  # or 23 for Android M
   export TARGET_ARCH=arm64

   # Build
   ./build-b2g.sh
   ```

### Investigation Needed

- [ ] Does KaiOS publish their B2G Android base manifests?
- [ ] Can we access KaiOS 4.0 Android 14 base?
- [ ] What device are we targeting (emulator, specific hardware)?
- [ ] Do we need custom device APIs or system services?

### Questions to Answer

1. **Target Device**: Emulator, specific phone model, or custom hardware?
2. **Customization Level**: UI only, or deep system modifications?
3. **Android Version Strategy**: Start with M and migrate, or go straight to 14?
4. **Relationship with KaiOS**: Fork independently, or seek collaboration?

## Resources

- **This Repository**: https://github.com/kaiostech/gecko-b2g
- **KaiOS B2G**: https://github.com/kaiostech/B2G
- **KaiOS Developer Portal**: https://kaios.dev
- **Gonk Documentation**: See gonk.md in this repo
- **KaiOS 4.0 Announcement**: https://kaios.dev/2024/12/whats-coming-in-kaios-4.0/

## Comparison: Legacy vs Modern

| Aspect | mozilla-b2g (Old) | kaiostech/gecko-b2g (This Repo) |
|--------|------------------|----------------------------------|
| Status | Archived (2016) | Active (2024) |
| Gecko | 43 (2015) | 123 (2024) |
| Android | 5.1.1 / 6.0 | 6.0 - 14.0 |
| Maintenance | None | Commercial backing (KaiOS) |
| Documentation | Outdated | Current |
| Production Use | None | KaiOS devices worldwide |
| Difficulty to Update | Extremely Hard | Maintained for you |

## Conclusion

**This is a game-changer.** Instead of trying to update a 9-year-old codebase (mozilla-b2g), you now have access to a **modern, actively maintained B2G stack** that already runs on Android 14 with Gecko 123.

The hard work of:
- Updating Gecko from v43 to v123 (9 years of changes)
- Porting to modern Android (Lollipop to Android 14)
- Handling HAL changes (old HAL → HIDL → AIDL)
- Modernizing build system
- Implementing modern security (SELinux, etc.)

**Has already been done by KaiOS.**

Your path forward is to build on their work rather than reinventing it.
