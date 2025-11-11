# Building Gecko-B2G for Pixel 6a (Android 14)

This guide documents the complete process for building gecko-b2g with Android 14 support for Pixel 6a using vanilla AOSP.

## Prerequisites

### System Requirements
- **OS**: Linux (tested on Pop!_OS 24.04)
- **CPU**: Multi-core (8+ cores recommended)
- **RAM**: 32GB+ recommended
- **Disk**: 250GB+ free space
  - ~150GB for AOSP source
  - ~100GB for AOSP build output
  - Additional space for gecko-b2g build

### Required Tools
- Python 3.11 or 3.12 (NOT 3.14)
- Rust 1.79.0 (NOT 1.80+, due to time crate incompatibility)
- GCC 13 or 14
- Git
- Repo tool (for AOSP)

## Step 1: Build AOSP for Pixel 6a

### 1.1 Download AOSP

```bash
mkdir -p ~/android14-aosp
cd ~/android14-aosp

# Initialize repo for Android 14
repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r73
repo sync -c -j8  # Takes 2-4 hours, ~150GB
```

### 1.2 Build AOSP

Use the provided build script:

```bash
cd ~/android14-aosp
./build-pixel6a.sh
```

Or build manually:

```bash
cd ~/android14-aosp
source build/envsetup.sh
lunch aosp_bluejay-ap2a-userdebug
make -j12  # Adjust -j based on CPU cores
```

**Build time**: 2-4 hours
**Output**: `out/target/product/bluejay/`

### 1.3 Optional: Vendor Binaries

For full device functionality, download proprietary binaries:
1. Visit: https://developers.google.com/android/drivers#bluejay
2. Download for build AP2A.240905.003.F1
3. Extract and run the self-extracting scripts in the AOSP directory

## Step 2: Bootstrap Gecko-B2G

### 2.1 Set Up Environment

```bash
cd ~/gecko-b2g
source setup-pixel6a-env.sh
```

This script will:
- Configure Python 3.12 (avoiding 3.14 compatibility issues)
- Set GCC to version 13
- Set environment variables for Android 14 ARM64 build
- Check for required Rust components

### 2.2 Install Rust Requirements

```bash
# Install Rust 1.79.0 (REQUIRED - 1.80+ has time crate incompatibility)
rustup install 1.79.0
rustup default 1.79.0

# Install Android ARM64 target
rustup target add aarch64-linux-android

# IMPORTANT: If you have a newer 'stable' toolchain, remove it
# The build system hardcodes the path to stable-x86_64-unknown-linux-gnu
rustup toolchain uninstall stable 2>/dev/null || true
cd ~/.rustup/toolchains
ln -sf 1.79.0-x86_64-unknown-linux-gnu stable-x86_64-unknown-linux-gnu
cd -

# Install cbindgen 0.26.0 (C bindings generator)
# IMPORTANT: Use version 0.26.0, not the latest (0.29.x has parsing issues)
cargo install cbindgen --version 0.26.0
```

**Important Notes:**
- Gecko-b2g requires Rust 1.79.0 due to a dependency on `time` crate 0.3.23, which is incompatible with Rust 1.80+
- The build system's configure script hardcodes the path `~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu`, so we create a symlink to ensure it finds Rust 1.79.0
- If you already have a newer Rust version installed, the commands above will remove the stable channel and create the necessary symlink

### 2.3 Bootstrap Gecko

```bash
./mach bootstrap
```

When prompted:
- Choose: **1. Boot2Gecko**
- Git configuration: **n** (unless you want git-cinnabar)

**Note**: Several bugs in the bootstrap code were fixed (see "Bugs Fixed" section below).

## Step 3: Build Gecko-B2G

```bash
./build-b2g.sh
```

**Build time**: 1-3 hours
**Output**: `objdir-bluejay-arm64/dist/b2g-*.tar.gz`

### Monitor Build Progress

```bash
# In another terminal
tail -f objdir-bluejay-arm64/*.log
```

## Step 4: Package (Optional)

```bash
./build-b2g.sh package
```

## Environment Variables Reference

Set by `setup-pixel6a-env.sh`:

| Variable | Value | Purpose |
|----------|-------|---------|
| `GONK_PATH` | `/home/aubrey/Work/android14-aosp` | AOSP root directory |
| `GONK_PRODUCT_NAME` | `bluejay` | Pixel 6a device codename |
| `PLATFORM_VERSION` | `34` | Android 14 API level |
| `TARGET_ARCH` | `arm64` | Target architecture |
| `GECKO_OBJDIR` | `objdir-bluejay-arm64` | Build output directory |
| `CC` | `/usr/bin/gcc-13` | C compiler |
| `CXX` | `/usr/bin/g++-13` | C++ compiler |

## Bugs Fixed During Development

The following bugs in the gecko-b2g codebase were identified and fixed:

### 1. Python 3.14 Incompatibility
**File**: Environment configuration
**Issue**: Python 3.14 AST API changes broke mach build system
**Fix**: Use Python 3.12 via PATH priority

### 2. GCC-12 Not Found
**File**: Build environment
**Issue**: cffi looking for gcc-12 which doesn't exist
**Fix**: Export `CC=/usr/bin/gcc-13` and `CXX=/usr/bin/g++-13`

### 3. Deprecated MACH_USE_SYSTEM_PYTHON
**File**: Environment configuration
**Issue**: Variable deprecated, causing assertion failures
**Fix**: Removed variable, let mach auto-detect

### 4. Missing os_arch Argument
**File**: `python/mozboot/mozboot/linux_common.py:73`
**Issue**: `ensure_android()` called without required `os_arch` parameter
**Fix**: Added `os_arch = platform.machine()` and passed to function

### 5. NDK r26c Download URL (404)
**File**: `python/mozboot/mozboot/android.py:685`
**Issue**: Google changed NDK r26c naming from `android-ndk-r26c-linux-x86_64.zip` to `android-ndk-r26c-linux.zip`
**Fix**: Special case handling for r26c URL format

### 6. Undefined state_dir Variable
**File**: `python/mozboot/mozboot/bootstrap.py:327`
**Issue**: `state_dir` and `checkout_root` used without being passed as parameters
**Fix**: Added parameters to function signature and call site

### 7. Wrong install_toolchain_artifact Arguments
**File**: `python/mozboot/mozboot/linux_common.py:81`
**Issue**: Passing extra arguments that function doesn't accept
**Fix**: Removed `state_dir` and `checkout_root` arguments

### 8. Missing ensure_b2g_packages Method
**File**: `python/mozboot/mozboot/linux_common.py:83`
**Issue**: Bootstrap framework expects `ensure_b2g_packages()` method
**Fix**: Added stub method

### 9. AOSP Sysroot Missing Files
**File**: `taskcluster/scripts/misc/create-b2g-sysroot-aosp14.sh:16`
**Issue**: Script expects B2G-specific libraries not in vanilla AOSP
**Fix**: Added `--ignore-missing-args` to rsync and error handling

### 10. ARCH_FOLDER Auto-Detection
**File**: `taskcluster/scripts/misc/create-b2g-sysroot-aosp14.sh:73`
**Issue**: Empty `TARGET_ARCH_VARIANT` and `TARGET_CPU_VARIANT` causing wrong paths
**Fix**: Auto-detect actual arch folder from AOSP build output

### 11. libvold_binder.a Hash Subdirectory
**File**: `taskcluster/scripts/misc/create-b2g-sysroot-aosp14.sh:439`
**Issue**: File in hash subdirectory, not at expected path
**Fix**: Use `find` to locate file dynamically

### 12. cbindgen Duplicate Key
**File**: `servo/ports/geckolib/cbindgen.toml:343`
**Issue**: Duplicate "Keyframe" entry causing TOML parse error
**Fix**: Removed duplicate entry

### 13. cbindgen Version Incompatibility
**File**: Build environment
**Issue**: cbindgen 0.29.x has stricter parsing, fails with "expected identifier or integer"
**Fix**: Downgrade to cbindgen 0.26.0

### 14. Missing Graphics Common V5 Headers
**File**: `taskcluster/scripts/misc/create-b2g-sysroot-aosp14.sh:348`
**Issue**: Pixel 6a has graphics.common V5, script only included V4
**Fix**: Added V5 headers path to sysroot includes

### 15. Rust 1.80+ Time Crate Incompatibility
**File**: Build environment / Cargo dependencies
**Issue**: time crate 0.3.23 incompatible with Rust 1.80+ (API change in type inference)
**Fix**: Use Rust 1.79.0 instead of 1.80+
**Impact**: Requires clean rebuild when switching Rust versions

### 16. Configure Script Hardcoded Stable Toolchain Path
**File**: Build system configure script
**Issue**: Configure script uses hardcoded path `~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin/rustc` instead of detecting default toolchain
**Fix**: Create symlink from `stable-x86_64-unknown-linux-gnu` to `1.79.0-x86_64-unknown-linux-gnu`
**Impact**: Required when installing versioned Rust toolchain (e.g., `rustup install 1.79.0`)

## Differences: KaiOS Build vs Vanilla AOSP

### Missing Libraries in Vanilla AOSP
These libraries exist in KaiOS builds but not vanilla AOSP:
- `binder_b2g_stub.so`
- `binder_b2g_connectivity_interface-V1-cpp.so`
- `binder_b2g_system_interface-V1-cpp.so`
- `binder_b2g_telephony_interface-V1-cpp.so`
- `binder_b2g_remotesimunlock_interface-V1-cpp.so`

### Different HAL Versions
Pixel 6a uses different HAL versions than KaiOS reference devices:
- Some WiFi HALs (@1.0-1.5) not present
- Some Radio HALs have different versions
- `libsuspend.so` removed in newer AOSP

**Impact**: Gecko-b2g builds successfully without these, but some B2G-specific features may not be available.

## Troubleshooting

### Error: "can't find crate for `std`" (Rust)
**Solution**: Install Android target
```bash
rustup target add aarch64-linux-android
```

### Error: "Cannot find cbindgen"
**Solution**: Install cbindgen 0.26.0 specifically
```bash
cargo install cbindgen --version 0.26.0
```

### Error: cbindgen parsing errors ("expected identifier or integer")
**Cause**: cbindgen 0.29.x is too new and has stricter parsing
**Solution**: Downgrade to cbindgen 0.26.0
```bash
cargo install cbindgen --version 0.26.0 --force
cbindgen --version  # Verify it shows 0.26.0
```

### Error: "type annotations needed for `Box<_>`" (time crate)
**Error Message**: `error[E0282]: type annotations needed... this is an inference error on crate 'time' caused by an API change in Rust 1.80.0`
**Cause**: Rust 1.80+ is incompatible with time crate 0.3.23
**Solution**: Downgrade to Rust 1.79.0 and ensure stable toolchain is removed
```bash
rustup install 1.79.0
rustup default 1.79.0
rustup target add aarch64-linux-android  # Re-add Android target

# Remove stable toolchain and create symlink to 1.79.0
rustup toolchain uninstall stable 2>/dev/null || true
cd ~/.rustup/toolchains
ln -sf 1.79.0-x86_64-unknown-linux-gnu stable-x86_64-unknown-linux-gnu
cd -

rm -rf objdir-bluejay-arm64  # Clean build directory
source setup-pixel6a-env.sh
./build-b2g.sh  # Rebuild from scratch
```

### Error: "can't find crate for `std`" with stable toolchain path
**Error Message**: `Cannot compile for aarch64-unknown-linux-android with /home/aubrey/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin/rustc`
**Cause**: Build system looks for `stable-x86_64-unknown-linux-gnu` but only versioned toolchain exists
**Solution**: Create symlink from stable to 1.79.0 toolchain
```bash
cd ~/.rustup/toolchains
ln -sf 1.79.0-x86_64-unknown-linux-gnu stable-x86_64-unknown-linux-gnu
cd -
```

### Error: Python version issues
**Solution**: Ensure Python 3.12 is first in PATH
```bash
export PATH=/usr/bin:$PATH
python3 --version  # Should show 3.12.x
```

### Error: AOSP libraries not found
**Solution**: Verify AOSP build completed successfully
```bash
ls $GONK_PATH/out/target/product/bluejay/system/lib64/*.so | wc -l
# Should show 650+ files
```

### Error: rsync errors during sysroot creation
**Expected**: Some files don't exist in vanilla AOSP - this is normal
**Action**: Build continues if essential files are present

## Architecture Notes

### Sysroot Creation
The build process creates a sysroot containing:
1. **System libraries** (~100) from `out/target/product/bluejay/system/lib64/`
2. **Generated headers** (AIDL/HIDL) from `out/soong/.intermediates/`
3. **Source headers** from AOSP source tree

### Build Flow
1. **Sysroot creation**: Extracts necessary files from AOSP build
2. **Configure**: Gecko's configure script validates environment
3. **Compile**: Gecko + Gonk components compiled for Android ARM64
4. **Package**: Produces tarball with Gecko engine and B2G runtime

## File Structure

```
gecko-b2g/
├── setup-pixel6a-env.sh          # Environment configuration script
├── build-b2g.sh                  # Main build script
├── mozconfig-b2g                 # Gecko build configuration
├── objdir-bluejay-arm64/         # Build output directory
│   ├── b2g-sysroot/              # Extracted AOSP files
│   │   ├── libs/                 # System libraries
│   │   └── include/              # Headers
│   └── dist/                     # Final build artifacts
└── taskcluster/scripts/misc/
    └── create-b2g-sysroot-aosp14.sh  # Sysroot extraction script

android14-aosp/
├── build-pixel6a.sh              # AOSP build script
└── out/target/product/bluejay/   # AOSP build output
    ├── system/lib64/             # System libraries
    └── apex/                     # APEX modules
```

## Next Steps

Once the build completes:

1. **Extract the package**:
   ```bash
   cd objdir-bluejay-arm64/dist
   tar xzf b2g-*.tar.gz
   ```

2. **Deploy to device**: (requires additional steps)
   - Flash the Pixel 6a with the AOSP build
   - Push gecko-b2g components to device
   - Configure B2G runtime

3. **Development cycle**:
   ```bash
   # Make changes to gecko code
   ./build-b2g.sh              # Incremental rebuild
   ./build-b2g.sh package      # Repackage
   ```

## References

- **AOSP**: https://source.android.com/
- **NDK Downloads**: https://developer.android.com/ndk/downloads
- **Pixel Factory Images**: https://developers.google.com/android/images
- **Pixel Drivers**: https://developers.google.com/android/drivers#bluejay
- **KaiOS gecko-b2g**: https://github.com/kaiostech/gecko-b2g
- **Original CLAUDE.md**: See CLAUDE.md in repository root

## Credits

Built on the KaiOS gecko-b2g fork, adapted for vanilla AOSP builds on Pixel 6a hardware.
