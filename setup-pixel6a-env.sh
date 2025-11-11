#!/bin/bash
#
# Environment setup for building gecko-b2g with Pixel 6a AOSP base
# Source this file before building: source setup-pixel6a-env.sh
#

# CRITICAL: Use system Python 3.12, not Linuxbrew Python 3.14
# Python 3.14 is too new and causes AST compatibility issues
export PATH=/usr/bin:$PATH

# Don't set MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE - let mach auto-detect
# This allows mach to create a proper virtualenv with correct package versions
unset MACH_USE_SYSTEM_PYTHON
unset MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE

# Force use of gcc-13 (cffi looks for gcc-12 which doesn't exist)
export CC=/usr/bin/gcc-13
export CXX=/usr/bin/g++-13

# Ensure host (x86_64) builds use system compiler, not Android NDK
# This is needed for Rust crates that build native code for the host
export CC_x86_64_unknown_linux_gnu=/usr/bin/gcc-13
export CXX_x86_64_unknown_linux_gnu=/usr/bin/g++-13

# AOSP paths
export GONK_PATH=/home/aubrey/Work/android14-aosp
export GONK_PRODUCT_NAME=bluejay
export PLATFORM_VERSION=34
export TARGET_ARCH=arm64

# Optional: Custom object directory to keep builds organized
export GECKO_OBJDIR=objdir-bluejay-arm64

# Optional: Paths (usually auto-detected, but can override)
# export CLANG_PATH=$HOME/.mozbuild/clang/bin
export PYTHON_PATH=/usr/bin

echo "========================================"
echo "Gecko-B2G Environment for Pixel 6a"
echo "========================================"
echo ""
echo "Toolchain:"
echo "  Python              = $(python3 --version) ($(which python3))"
echo "  Rust                = $(rustc --version)"
echo "  GCC                 = $CC"
echo "  GXX                 = $CXX"
echo ""
echo "Configuration:"
echo "  GONK_PATH           = $GONK_PATH"
echo "  GONK_PRODUCT_NAME   = $GONK_PRODUCT_NAME"
echo "  PLATFORM_VERSION    = $PLATFORM_VERSION"
echo "  TARGET_ARCH         = $TARGET_ARCH"
echo "  GECKO_OBJDIR        = $GECKO_OBJDIR"
echo ""

# Verify AOSP build exists
if [ ! -d "$GONK_PATH/out/target/product/$GONK_PRODUCT_NAME" ]; then
    echo "⚠️  WARNING: AOSP build not found at:"
    echo "   $GONK_PATH/out/target/product/$GONK_PRODUCT_NAME"
    echo ""
    echo "   You need to build AOSP first:"
    echo "   cd $GONK_PATH && ./build-pixel6a.sh"
    echo ""
    return 1
fi

echo "✓ AOSP build found"
echo ""

# Check for Rust version
echo "Checking Rust requirements..."
RUST_VERSION=$(rustc --version | awk '{print $2}')
if [[ "$RUST_VERSION" == "1.79.0" ]]; then
    echo "  ✓ Rust $RUST_VERSION installed"

    # Check if stable toolchain symlink exists and points to 1.79.0
    if [ -e "$HOME/.rustup/toolchains/stable-x86_64-unknown-linux-gnu" ]; then
        STABLE_RUST_VERSION=$($HOME/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin/rustc --version 2>/dev/null | awk '{print $2}')
        if [[ "$STABLE_RUST_VERSION" == "1.79.0" ]]; then
            echo "  ✓ stable toolchain points to 1.79.0"
        else
            echo "  ⚠️  stable toolchain is $STABLE_RUST_VERSION (need 1.79.0)"
            echo "     Build system hardcodes stable toolchain path"
            echo "     Fix with: rustup toolchain uninstall stable && cd ~/.rustup/toolchains && ln -sf 1.79.0-x86_64-unknown-linux-gnu stable-x86_64-unknown-linux-gnu"
            MISSING_DEPS=1
        fi
    else
        echo "  ⚠️  stable toolchain symlink missing"
        echo "     Build system hardcodes stable toolchain path"
        echo "     Fix with: cd ~/.rustup/toolchains && ln -sf 1.79.0-x86_64-unknown-linux-gnu stable-x86_64-unknown-linux-gnu"
        MISSING_DEPS=1
    fi
else
    echo "  ⚠️  Rust $RUST_VERSION installed (need 1.79.0)"
    echo "     Rust 1.80+ has time crate incompatibility"
    echo "     Install with: rustup install 1.79.0 && rustup default 1.79.0"
    MISSING_DEPS=1
fi

# Check for Rust Android target
if rustup target list --installed | grep -q "aarch64-linux-android"; then
    echo "  ✓ Rust aarch64-linux-android target installed"
else
    echo "  ⚠️  Rust Android target missing"
    echo "     Install with: rustup target add aarch64-linux-android"
    MISSING_DEPS=1
fi

# Check for cbindgen
if command -v cbindgen &> /dev/null; then
    CBINDGEN_VERSION=$(cbindgen --version | awk '{print $2}')
    if [[ "$CBINDGEN_VERSION" == "0.26.0" ]]; then
        echo "  ✓ cbindgen $CBINDGEN_VERSION installed"
    else
        echo "  ⚠️  cbindgen $CBINDGEN_VERSION installed (need 0.26.0)"
        echo "     Install with: cargo install cbindgen --version 0.26.0 --force"
        MISSING_DEPS=1
    fi
else
    echo "  ⚠️  cbindgen missing"
    echo "     Install with: cargo install cbindgen --version 0.26.0"
    MISSING_DEPS=1
fi

echo ""

if [ -n "$MISSING_DEPS" ]; then
    echo "⚠️  Missing dependencies detected"
    echo ""
    echo "To install missing Rust dependencies, run:"
    echo "  rustup install 1.79.0 && rustup default 1.79.0"
    echo "  rustup target add aarch64-linux-android"
    echo "  cargo install cbindgen --version 0.26.0 --force"
    echo ""
    return 1
fi

echo "Next steps:"
echo "  1. Bootstrap gecko (first time only): ./mach bootstrap"
echo "  2. Build gecko-b2g: ./build-b2g.sh"
echo "  3. Package: ./build-b2g.sh package"
echo ""
