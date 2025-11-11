# GNSS AIDL Stub Headers for Vanilla AOSP

## Overview

Vanilla AOSP for Pixel devices does not build AIDL GNSS HAL C++ headers because Pixel devices use the standard Android location framework instead of direct HAL access.

However, gecko-b2g's geolocation code includes AIDL GNSS support (guarded by `#if defined(AIDL_GNSS)`), which requires these headers to compile even though they won't be used at runtime on Pixel devices.

These stub headers provide the minimum type definitions needed for compilation.

## Stub Headers

### Core GNSS Interfaces
- **IGnss.h** - Main GNSS interface with position mode enums and methods
- **IGnssCallback.h** - GNSS callback interface with capability flags and status values
- **BnGnssCallback.h** - Native (server-side) GNSS callback binder stub

### Assisted GNSS
- **IAGnssCallback.h** - Assisted GNSS callback interface with APN types
- **BnAGnssCallback.h** - Native AGNSS callback binder stub

### Visibility Control
- **visibility_control/IGnssVisibilityControlCallback.h** - NFW notification callback interface
- **visibility_control/BnGnssVisibilityControlCallback.h** - Native visibility control callback stub

## Integration

These headers are copied to the b2g-sysroot during the build process. The build system should be configured to copy these stubs to `$objdir/b2g-sysroot/include/android/hardware/gnss/` before compilation.

## Implementation Status

All classes inherit from `android::RefBase` to work with Android's `sp<>` smart pointer system. Methods are pure virtual stubs - they will never be called on Pixel devices as the runtime code path uses the standard Android location framework.

## Build Notes

Created for Android 14 (API 34) vanilla AOSP build for Google Pixel 6a (bluejay).

Last updated: 2025-01-11
