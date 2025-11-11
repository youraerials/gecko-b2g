#!/bin/bash
set -x -e -v

src="${1-.}"
dest="${2-.}"

# This is a broken symlink that prevents rsync from doing its job.
# Using --exclude still fails with a "symlink has no referent" error.
#mv ${src}/frameworks/native/include/private/binder ${src}/out/broken_binder_symlink

# Copy the contents of the files & directories in the first argument to the
# sysroot using the second argument as the destination folder. File
# creation/modification timestamps are preserved.
# Note: Some files may not exist in vanilla AOSP builds (especially B2G-specific libs)
function copy_to_sysroot() {
    mkdir -p "${dest}/b2g-sysroot/${2}/"
    # Use --ignore-missing-args to skip files that don't exist (like binder_b2g_* in vanilla AOSP)
    rsync --times -r --no-relative --copy-links --ignore-missing-args \
        --exclude=".git" --exclude=Android.bp --exclude=AndroidTest.xml \
        --files-from="${1}" "${src}" "${dest}/b2g-sysroot/${2}/" || {
        echo "Warning: Some files were not found, but continuing..."
        return 0
    }
}

# Prepare the device-specific paths in the AOSP build files
case "${TARGET_ARCH}" in
    arm)
        ARCH_NAME="arm"
        ARCH_ABI="androideabi"
        ;;
    arm64)
        ARCH_NAME="aarch64"
        ARCH_ABI="android"
        TARGET_TRIPLE=$ARCH_NAME-linux-$ARCH_ABI
        BINSUFFIX=64
        FOLDERSUFFIX="_cfi"
        ;;
    x86)
        ARCH_NAME="i686"
        ARCH_ABI="android"
        TARGET_TRIPLE=$ARCH_NAME-linux-$ARCH_ABI
        ;;
    x86_64)
        ARCH_NAME="x86"
        ARCH_ABI="android"
        BINSUFFIX=64
        ;;
    *)
        echo "Unsupported $TARGET_ARCH"
        exit 1
        ;;
esac

TARGET_TRIPLE=${TARGET_TRIPLE:-$TARGET_ARCH-linux-$ARCH_ABI}

if [ -z "$TARGET_ARCH_VARIANT" ] ||
   [ "$TARGET_ARCH_VARIANT" = "$TARGET_ARCH" ] ||
   [ "$TARGET_ARCH_VARIANT" = "generic" ]; then
TARGET_ARCH_VARIANT=""
else
TARGET_ARCH_VARIANT="_$TARGET_ARCH_VARIANT"
fi

if [ -z "$TARGET_CPU_VARIANT" ] ||
   [ "$TARGET_CPU_VARIANT" = "$TARGET_ARCH" ] ||
   [ "$TARGET_CPU_VARIANT" = "generic" ]; then
TARGET_CPU_VARIANT=""
else
TARGET_CPU_VARIANT="_$TARGET_CPU_VARIANT"
fi

# For vanilla AOSP builds, ARCH_FOLDER might be like arm64_armv8-2a_cortex-a55
# Auto-detect the actual ARCH_FOLDER from the build output
ARCH_FOLDER="${TARGET_ARCH}${TARGET_ARCH_VARIANT}${TARGET_CPU_VARIANT}"

# Try to detect actual arch folder from AOSP build output
# Look for libvold_binder as a probe since it's commonly built
if [ -d "${src}/out/soong/.intermediates/system/vold/libvold_binder" ]; then
    DETECTED_FOLDER=$(find "${src}/out/soong/.intermediates/system/vold/libvold_binder" \
        -maxdepth 1 -type d -name "android_${TARGET_ARCH}*_static" | head -1 | xargs basename 2>/dev/null)
    if [ -n "$DETECTED_FOLDER" ]; then
        # Extract just the arch+variant part (remove "android_" prefix and "_static" suffix)
        ARCH_FOLDER="${DETECTED_FOLDER#android_}"  # Remove "android_" prefix
        ARCH_FOLDER="${ARCH_FOLDER%_static}"       # Remove "_static" suffix
        echo "Auto-detected ARCH_FOLDER: $ARCH_FOLDER"
    fi
fi

libraries_list=$(mktemp)
includes_list=$(mktemp)

# Copy the system libraries to the sysroot
tee "${libraries_list}" << EOF
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/audiopolicy-aidl-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.common-V2-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.gnss@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.gnss@1.1.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.gnss@2.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.gnss-V2-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.gnss.visibility_control@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.graphics.composer@2.1.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.graphics.composer@2.2.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.graphics.composer@2.3.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.graphics.composer@2.4.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.graphics.composer3-V2-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.power@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.power-V3-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio@1.1.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio@1.2.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio@1.3.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio@1.4.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio@1.5.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio@1.6.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio.data-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio.voice-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio.messaging-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio.modem-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio.network-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio.sim-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.radio.config-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.sensors@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.sensors@2.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.sensors@2.1.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.sensors-V2-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.vibrator@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.vibrator-V2-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi@1.1.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi@1.2.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi@1.3.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi@1.4.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi@1.5.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi-V1-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi.hostapd@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi.hostapd@1.1.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi.hostapd-V1-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hardware.wifi.supplicant-V2-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.media.audio.common.types-V3-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.system.wifi.keystore@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.hidl.safe_union@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.frameworks.stats@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.frameworks.stats-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.frameworks.sensorservice@1.0.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/android.frameworks.sensorservice-V1-ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libsensor.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libsensorserviceaidl.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libsensorservicehidl.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/binder_b2g_stub.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/binder_b2g_connectivity_interface-V1-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/binder_b2g_system_interface-V1-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/binder_b2g_telephony_interface-V1-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/binder_b2g_remotesimunlock_interface-V1-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/dnsresolver_aidl_interface-V2-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libaudioclient.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libaudioclient_aidl_conversion.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libaudiofoundation.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libaudiopolicy.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libbase.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libbinder.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libbinder_ndk.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libcamera_client.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libc++.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libcutils.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libdrm.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libfmq.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libgui.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libhardware_legacy.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libhardware.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libhidlbase.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libhidlmemory.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libhidltransport.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libhwbinder.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libmedia_helper.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libmedia_omx.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libmedia.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libmediadrm.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libmtp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libstagefright_foundation.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libstagefright_omx.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libstagefright.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libSurfaceFlingerProp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libsuspend.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libsync.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libsysutils.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libui.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libutils.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libvold_binder_shared.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libinput.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libaudiopolicymanagerdefault.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libaudiopolicyservice.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libactivitymanager_aidl.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/netd_event_listener_interface-V1-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/netd_aidl_interface-V2-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/netd_aidl_interface-V10-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/oemnetd_aidl_interface-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/audiopolicy-aidl-cpp.so
out/target/product/${GONK_PRODUCT_NAME}/apex/com.android.tethering/lib${BINSUFFIX}/libnetworkstats.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libwificond_ipc_shared.so
out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libmedia_codeclist.so
EOF

# is not available in aosp 13.
# system/netd/libnetdbpf/include
# system/netd/libnetdutils/include
# out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/netd_event_listener_interface-V1-cpp.so
# out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/libnetdbpf.so

copy_to_sysroot "${libraries_list}" "libs"

# Store the system includes in the sysroot
sed 's/$/\//' > "${includes_list}" << EOF
external/fmtlib/include
external/libdrm/include
frameworks/av/camera/include
frameworks/av/drm/libmediadrm/interface
frameworks/av/drm/libmediadrm/include
frameworks/av/include
frameworks/av/media/audioaidlconversion/include
frameworks/av/media/module/foundation/include
frameworks/av/media/libaudioclient/include
frameworks/av/media/libaudiofoundation/include
frameworks/av/media/libavextensions
frameworks/av/media/liberror/include
frameworks/av/media/libmedia/aidl
frameworks/av/media/libmedia/include
frameworks/av/media/libstagefright/include
frameworks/av/media/libmediahelper/include
frameworks/av/media/libmediametrics/include
frameworks/av/media/module/mpeg2ts/include
frameworks/av/media/mtp
frameworks/av/media/utils/include
frameworks/libs/net/common/native/bpf_syscall_wrappers/include
frameworks/libs/net/common/native/bpf_headers/include
frameworks/native/headers/media_plugin
frameworks/native/include
frameworks/native/include/media/openmax
frameworks/native/libs/binder/include
frameworks/native/libs/binder/include_activitymanager
frameworks/native/libs/binder/ndk/include_cpp
frameworks/native/libs/binder/ndk/include_ndk
frameworks/native/libs/binder/ndk/include_platform
frameworks/native/libs/gui
frameworks/native/libs/gui/include
frameworks/native/libs/math/include
frameworks/native/libs/nativebase/include
frameworks/native/libs/nativewindow/include
frameworks/native/libs/sensor/include
frameworks/native/libs/sensor/include/sensor
frameworks/native/libs/ui/include
frameworks/native/opengl/include
frameworks/native/services/surfaceflinger
frameworks/native/services/sensorservice/aidl
frameworks/native/services/sensorservice/aidl/include/sensorserviceaidl
gonk-misc/gonk-binder/binder_b2g_stub/include/
hardware/interfaces/common/support/include
hardware/interfaces/graphics/composer/2.1/utils/command-buffer/include
hardware/interfaces/graphics/composer/2.2/utils/command-buffer/include
hardware/interfaces/graphics/composer/2.3/utils/command-buffer/include
hardware/interfaces/graphics/composer/2.4/utils/command-buffer/include
hardware/interfaces/graphics/composer/aidl/include
hardware/libhardware/include
hardware/libhardware_legacy/include
system/bpf/libbpf_android/include
system/connectivity
system/core/libcutils/include
system/core/libprocessgroup/include
system/core/libsuspend/include
system/core/libsync/include
system/core/libsystem/include
system/core/libsysutils/include
system/core/libutils/include
system/libbase/include
system/libfmq/include
system/libfmq/base
system/libhidl/base/include
system/libhidl/transport/include
system/libhidl/transport/token/1.0/utils/include
system/libhwbinder/include
system/logging/liblog/include
system/media/audio/include
system/media/camera/include
packages/modules/Connectivity/service-t/native/libs/libnetworkstats/include
packages/modules/Connectivity/bpf_progs
EOF

# Store the generated AIDL headers in the sysroot
# Note: libcamera_client AIDL is in a hash subdirectory, so we handle it separately below
sed 's/$/\//' >> "${includes_list}" << EOF
out/soong/.intermediates/frameworks/av/media/libaudioclient/libaudioclient/android_${ARCH_FOLDER}_static${FOLDERSUFFIX}/gen/aidl
out/soong/.intermediates/frameworks/av/media/libmedia/libmedia_omx/android_${ARCH_FOLDER}_shared${FOLDERSUFFIX}/gen/aidl
out/soong/.intermediates/frameworks/av/media/libaudioclient/audiopolicy-types-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/av/media/libaudioclient/spatializer-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/av/media/libaudioclient/audioflinger-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/av/media/libaudioclient/audiopolicy-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/av/media/libaudioclient/audioclient-types-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/av/media/libaudioclient/effect-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/av/media/libshmem/shared-file-region-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/av/av-types-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/base/core/java/libincremental_aidl-cpp/android_${ARCH_FOLDER}_static/gen/aidl
out/soong/.intermediates/frameworks/libs/net/common/netd/netd_event_listener_interface-V1-cpp-source/gen/include
out/soong/.intermediates/frameworks/libs/net/common/netd/netd_aidl_interface-V10-cpp-source/gen/include
out/soong/.intermediates/frameworks/native/libs/binder/libactivitymanager_aidl/android_${ARCH_FOLDER}_static/gen/aidl
out/soong/.intermediates/frameworks/native/libs/gui/libgui/android_${ARCH_FOLDER}_shared/gen/aidl
out/soong/.intermediates/frameworks/native/libs/gui/libgui_window_info_static/android_${ARCH_FOLDER}_static_afdo-libgui_lto-thin/gen/aidl
out/soong/.intermediates/frameworks/native/libs/permission/framework-permission-aidl-cpp-source/gen/include
out/soong/.intermediates/frameworks/native/services/surfaceflinger/sysprop/libSurfaceFlingerProperties/android_${ARCH_FOLDER}_static/gen/sysprop/include
out/soong/.intermediates/gonk-misc/gonk-binder/binder_b2g_connectivity_interface-V1-cpp-source/gen/include
out/soong/.intermediates/gonk-misc/gonk-binder/binder_b2g_system_interface-V1-cpp-source/gen/include
out/soong/.intermediates/gonk-misc/gonk-binder/binder_b2g_telephony_interface-V1-cpp-source/gen/include
out/soong/.intermediates/gonk-misc/gonk-binder/binder_b2g_remotesimunlock_interface-V1-cpp-source/gen/include
out/soong/.intermediates/hardware/interfaces/common/aidl/android.hardware.common-V2-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/graphics/composer/aidl/android.hardware.graphics.composer3-V2-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/wifi/aidl/android.hardware.wifi-V1-cpp-source/gen/include
out/soong/.intermediates/hardware/interfaces/wifi/hostapd/aidl/android.hardware.wifi.hostapd-V1-cpp-source/gen/include
out/soong/.intermediates/hardware/interfaces/wifi/supplicant/aidl/android.hardware.wifi.supplicant-V2-cpp-source/gen/include
out/soong/.intermediates/packages/modules/DnsResolver/dnsresolver_aidl_interface-V2-cpp-source/gen/include
out/soong/.intermediates/system/hardware/interfaces/media/android.media.audio.common.types-V2-cpp-source/gen/include
out/soong/.intermediates/system/hardware/interfaces/media/android.media.audio.common.types-V3-cpp-source/gen/include
out/soong/.intermediates/system/netd/server/oemnetd_aidl_interface-cpp-source/gen/include
out/soong/.intermediates/system/vold/libvold_binder_shared/android_${ARCH_FOLDER}_shared/gen/aidl
out/soong/.intermediates/system/connectivity/wificond/libwificond_ipc/android_${ARCH_FOLDER}_static/gen/aidl
out/soong/.intermediates/hardware/interfaces/sensors/aidl/android.hardware.sensors-V2-ndk-source/gen/include
EOF

# out/soong/.intermediates/frameworks/base/media/audio_common-aidl-cpp-source/gen/include
# out/soong/.intermediates/system/netd/server/netd_event_listener_interface-V1-cpp-source/gen/include
# oemnetd_aidl_interface-cpp/        oemnetd_aidl_interface-cpp-source/

# Store the generated HIDL headers in the sysroot
sed 's/$/\//' >> "${includes_list}" << EOF
out/soong/.intermediates/hardware/interfaces/common/fmq/aidl/android.hardware.common.fmq-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/configstore/1.0/android.hardware.configstore@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/configstore/1.1/android.hardware.configstore@1.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/drm/1.0/android.hardware.drm@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/drm/1.1/android.hardware.drm@1.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/gnss/1.0/android.hardware.gnss@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/gnss/1.1/android.hardware.gnss@1.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/gnss/2.0/android.hardware.gnss@2.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/gnss/aidl/android.hardware.gnss-V2-cpp-source/gen/include
out/soong/.intermediates/hardware/interfaces/gnss/measurement_corrections/1.0/android.hardware.gnss.measurement_corrections@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/gnss/visibility_control/1.0/android.hardware.gnss.visibility_control@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/bufferqueue/1.0/android.hardware.graphics.bufferqueue@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/bufferqueue/2.0/android.hardware.graphics.bufferqueue@2.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/common/aidl/android.hardware.graphics.common-V4-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/graphics/common/aidl/android.hardware.graphics.common-V5-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/graphics/common/1.0/android.hardware.graphics.common@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/common/1.1/android.hardware.graphics.common@1.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/common/1.2/android.hardware.graphics.common@1.2_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/composer/2.1/android.hardware.graphics.composer@2.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/composer/2.2/android.hardware.graphics.composer@2.2_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/composer/2.3/android.hardware.graphics.composer@2.3_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/composer/2.4/android.hardware.graphics.composer@2.4_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/graphics/mapper/4.0/android.hardware.graphics.mapper@4.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/media/1.0/android.hardware.media@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/media/omx/1.0/android.hardware.media.omx@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/power/aidl/android.hardware.power-V3-cpp-source/gen/include
out/soong/.intermediates/frameworks/hardware/interfaces/stats/aidl/android.frameworks.stats-V1-ndk-source/gen/include/
out/soong/.intermediates/hardware/interfaces/radio/1.0/android.hardware.radio@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/radio/1.1/android.hardware.radio@1.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/radio/1.2/android.hardware.radio@1.2_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/radio/1.3/android.hardware.radio@1.3_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/radio/1.4/android.hardware.radio@1.4_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/radio/1.5/android.hardware.radio@1.5_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/radio/1.6/android.hardware.radio@1.6_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio.data-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio.voice-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio.modem-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio.messaging-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio.network-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio.sim-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/radio/aidl/android.hardware.radio.config-V1-ndk-source/gen/include
out/soong/.intermediates/hardware/interfaces/sensors/1.0/android.hardware.sensors@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/sensors/2.0/android.hardware.sensors@2.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/sensors/2.1/android.hardware.sensors@2.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/vibrator/1.0/android.hardware.vibrator@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/vibrator/aidl/android.hardware.vibrator-V2-cpp-source/gen/include
out/soong/.intermediates/hardware/interfaces/wifi/1.0/android.hardware.wifi@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/1.1/android.hardware.wifi@1.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/1.2/android.hardware.wifi@1.2_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/1.3/android.hardware.wifi@1.3_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/1.4/android.hardware.wifi@1.4_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/1.5/android.hardware.wifi@1.5_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/hostapd/1.0/android.hardware.wifi.hostapd@1.0_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/hostapd/1.1/android.hardware.wifi.hostapd@1.1_genc++_headers/gen
out/soong/.intermediates/hardware/interfaces/wifi/supplicant/1.0/android.hardware.wifi.supplicant@1.0_genc++_headers/gen
out/soong/.intermediates/system/hardware/interfaces/wifi/keystore/1.0/android.system.wifi.keystore@1.0_genc++_headers/gen
out/soong/.intermediates/system/libhidl/transport/base/1.0/android.hidl.base@1.0_genc++_headers/gen
out/soong/.intermediates/system/libhidl/transport/manager/1.0/android.hidl.manager@1.0_genc++_headers/gen
out/soong/.intermediates/system/libhidl/transport/memory/1.0/android.hidl.memory@1.0_genc++_headers/gen
out/soong/.intermediates/system/libhidl/transport/safe_union/1.0/android.hidl.safe_union@1.0_genc++_headers/gen
out/soong/.intermediates/frameworks/hardware/interfaces/sensorservice/1.0/android.frameworks.sensorservice@1.0_genc++_headers/gen
out/soong/.intermediates/frameworks/hardware/interfaces/sensorservice/aidl/android.frameworks.sensorservice-V1-ndk-source/gen/include
EOF

copy_to_sysroot "${includes_list}" "include"

if [ "$ENABLE_ESIM" = "true" ]; then
    # Put AIDL headers and libraries of ESIM into sysroot
    rsync --times --no-relative --copy-links \
        "${src}/out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/vendor.qti.hardware.radio.lpa-V1-ndk.so" \
        "${dest}/b2g-sysroot/libs/"
    rsync --times --no-relative --copy-links -r \
        "${src}/out/soong/.intermediates/vendor/qcom/proprietary/commonsys-intf/telephony/interfaces/aidl/lpa/vendor.qti.hardware.radio.lpa-V1-ndk-source/gen/include/" \
        "${dest}/b2g-sysroot/include/"
else
    echo "ESIM is not enabled"
fi

if [ "$ENABLE_RSU" = "true" ]; then
    rsync --times --no-relative --copy-links \
        "${src}/out/target/product/${GONK_PRODUCT_NAME}/system/lib${BINSUFFIX}/vendor.qti.hardware.radio.uim-V1-ndk.so" \
        "${dest}/b2g-sysroot/libs/"
    rsync --times --no-relative --copy-links -r \
        "${src}/out/soong/.intermediates/vendor/qcom/proprietary/commonsys-intf/telephony/interfaces/aidl/uim/vendor.qti.hardware.radio.uim-V1-ndk-source/gen/include/" \
        "${dest}/b2g-sysroot/include/"
else
    echo "RSU is not enabled"
fi

lib_c="${src}/out/target/product/${GONK_PRODUCT_NAME}/system/apex/com.android.runtime.release/lib${BINSUFFIX}/bionic/libc.so"
if test -f ${lib_c}; then
    rsync --times --no-relative --copy-links \
        "${lib_c}" \
        "${dest}/b2g-sysroot/libs/"
elif test -f "${src}/out/target/product/${GONK_PRODUCT_NAME}/apex/com.android.runtime/lib${BINSUFFIX}/bionic/libc.so"; then
    rsync --times --no-relative --copy-links \
        "${src}/out/target/product/${GONK_PRODUCT_NAME}/apex/com.android.runtime/lib${BINSUFFIX}/bionic/libc.so" \
        "${dest}/b2g-sysroot/libs/"
else
    rsync --times --no-relative --copy-links \
        "${src}/out/target/product/${GONK_PRODUCT_NAME}/obj/SHARED_LIBRARIES/libc_intermediates/libc.so" \
        "${dest}/b2g-sysroot/libs/"
fi

rsync ${src}/system/netd/include/mainline/XtBpfProgLocations.h  ${dest}/b2g-sysroot/include/

# libvold_binder.a is in a subdirectory with a hash - find it dynamically
VOLD_BINDER_PATH=$(find ${src}/out/soong/.intermediates/system/vold/libvold_binder/android_${ARCH_FOLDER}_static \
    -name "libvold_binder.a" 2>/dev/null | head -1)
if [ -n "$VOLD_BINDER_PATH" ]; then
    rsync --times --no-relative --copy-links ${VOLD_BINDER_PATH} ${dest}/b2g-sysroot/libs/
else
    echo "Warning: libvold_binder.a not found, continuing..."
fi

# libcamera_client AIDL headers are in _static_cfi variant with hash subdirectory - find them dynamically
# Note: Exclude */obj/* paths as they contain compiled .o files, not the .h headers we need
CAMERA_CLIENT_AIDL_DIR=$(find ${src}/out/soong/.intermediates/frameworks/av/camera/libcamera_client/android_${ARCH_FOLDER}_static_cfi \
    -type d -name "aidl" -not -path "*/obj/*" 2>/dev/null | head -1)
if [ -n "$CAMERA_CLIENT_AIDL_DIR" ]; then
    rsync --times -r --no-relative --copy-links ${CAMERA_CLIENT_AIDL_DIR}/ ${dest}/b2g-sysroot/include/
else
    echo "Warning: libcamera_client AIDL headers not found, continuing..."
fi

# libgui_aidl_static headers are in gen/aidl_library with hash subdirectory - find them dynamically
# Note: Exclude */obj/* paths as they might contain wrong paths
LIBGUI_AIDL_DIR=$(find ${src}/out/soong/.intermediates/frameworks/native/libs/gui/libgui_aidl_static/android_${ARCH_FOLDER}_static \
    -type d -name "aidl_library" -not -path "*/obj/*" 2>/dev/null | head -1)
if [ -n "$LIBGUI_AIDL_DIR" ]; then
    rsync --times -r --no-relative --copy-links ${LIBGUI_AIDL_DIR}/ ${dest}/b2g-sysroot/include/
else
    echo "Warning: libgui_aidl_static AIDL headers not found, continuing..."
fi

# Network NDK AIDL headers for netd_event_listener_interface (required by dom/system/gonk/network)
# NDK backend puts headers in aidl/ subdirectory, but build expects them at root
NETD_NDK_AIDL_DIR="${src}/out/soong/.intermediates/packages/modules/Connectivity/staticlibs/netd/netd_event_listener_interface-V1-ndk-source/gen/include/aidl"
if [ -d "$NETD_NDK_AIDL_DIR" ]; then
    rsync --times -r --no-relative --copy-links ${NETD_NDK_AIDL_DIR}/ ${dest}/b2g-sysroot/include/
    echo "Copied netd NDK AIDL headers"
else
    echo "Warning: netd_event_listener_interface NDK AIDL headers not found, continuing..."
fi

# Vold static binder AIDL headers are in _static variant with hash subdirectory - find them dynamically
# Note: Exclude */obj/* paths as they contain compiled .o files, not the .h headers we need
# Vold uses regular CPP backend (not NDK), so headers are directly under gen/aidl/
VOLD_BINDER_AIDL_DIR=$(find ${src}/out/soong/.intermediates/system/vold/libvold_binder/android_${ARCH_FOLDER}_static \
    -type d -name "aidl" -not -path "*/obj/*" 2>/dev/null | head -1)
if [ -n "$VOLD_BINDER_AIDL_DIR" ]; then
    rsync --times -r --no-relative --copy-links ${VOLD_BINDER_AIDL_DIR}/ ${dest}/b2g-sysroot/include/
    echo "Copied vold_binder static AIDL headers"
else
    echo "Warning: libvold_binder static AIDL headers not found, continuing..."
fi

# libguiflags headers are in gen/include with hash subdirectory - find them dynamically
LIBGUIFLAGS_DIR=$(find ${src}/out/soong/.intermediates/frameworks/native/libs/gui/libguiflags/android_${ARCH_FOLDER}_static \
    -type d -name "include" 2>/dev/null | head -1)
if [ -n "$LIBGUIFLAGS_DIR" ]; then
    rsync --times -r --no-relative --copy-links ${LIBGUIFLAGS_DIR}/ ${dest}/b2g-sysroot/include/
else
    echo "Warning: libguiflags headers not found, continuing..."
fi

# Create stub WiFi HAL header - WiFi HAL not built in vanilla AOSP for Pixel
# Pixel uses standard Android WiFi framework
mkdir -p ${dest}/b2g-sysroot/include/android/hardware/wifi
cat > ${dest}/b2g-sysroot/include/android/hardware/wifi/IWifi.h << 'WIFI_EOF'
/*
 * Stub header for IWifi - WiFi HAL not built in vanilla AOSP for Pixel
 * The Pixel device uses standard Android WiFi framework, not HAL directly
 */

#ifndef ANDROID_HARDWARE_WIFI_IWIFI_H
#define ANDROID_HARDWARE_WIFI_IWIFI_H

// Minimal stub to satisfy compilation

#endif  // ANDROID_HARDWARE_WIFI_IWIFI_H
WIFI_EOF

# Create stub GNSS HAL header - GNSS HAL not built in vanilla AOSP for Pixel
# Pixel uses standard Android location framework
mkdir -p ${dest}/b2g-sysroot/include/android/hardware/gnss
cat > ${dest}/b2g-sysroot/include/android/hardware/gnss/IGnss.h << 'GNSS_EOF'
/*
 * Stub header for IGnss - GNSS HAL not built in vanilla AOSP for Pixel
 * The Pixel device uses standard Android location framework, not HAL directly
 */

#ifndef ANDROID_HARDWARE_GNSS_IGNSS_H
#define ANDROID_HARDWARE_GNSS_IGNSS_H

// Minimal stub to satisfy compilation

#endif  // ANDROID_HARDWARE_GNSS_IGNSS_H
GNSS_EOF

# Create stub AVExtensions.h - vendor extension not present in vanilla AOSP
# This is a Qualcomm-specific extension for hardware codecs, not needed for vanilla builds
mkdir -p ${dest}/b2g-sysroot/include/stagefright
cat > ${dest}/b2g-sysroot/include/stagefright/AVExtensions.h << 'AVEXT_EOF'
/*
 * Stub header for AVExtensions - vendor extension not present in vanilla AOSP
 * This file is typically provided by Qualcomm's hardware codec extensions
 * but is not used in gecko-b2g for vanilla AOSP builds.
 */

#ifndef STAGEFRIGHT_AVEXTENSIONS_H_
#define STAGEFRIGHT_AVEXTENSIONS_H_

namespace android {

// Stub class - not actually used in gecko-b2g
class AVExtensions {
public:
    static AVExtensions* get() { return nullptr; }
};

}  // namespace android

#endif  // STAGEFRIGHT_AVEXTENSIONS_H_
AVEXT_EOF

#copy libdrm header
rsync ${src}/external/libdrm/include/drm/drm.h ${dest}/b2g-sysroot/include/
rsync ${src}/external/libdrm/include/drm/drm_mode.h ${dest}/b2g-sysroot/include/
rsync ${src}/external/libdrm/xf86drm.h ${dest}/b2g-sysroot/include/
rsync ${src}/external/libdrm/xf86drmMode.h ${dest}/b2g-sysroot/include/

#update for Surface.h in qssi14
sed -i 's/..\/..\/QtiExtension\/QtiSurfaceExtension.h/QtiExtension\/QtiSurfaceExtension.h/g' ${dest}/b2g-sysroot/include/gui/Surface.h

echo "/* All the logging code is now in the NDK sysroot/usr/include/android/log.h */" > ${dest}/b2g-sysroot/include/log/log_id.h

# Restore the broken symlink
#mv ${src}/out/broken_binder_symlink ${src}/frameworks/native/include/private/binder
