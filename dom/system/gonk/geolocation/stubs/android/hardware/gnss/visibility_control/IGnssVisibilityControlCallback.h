/*
 * Stub header for AIDL GNSS HAL - not built in vanilla AOSP for Pixel
 * Pixel uses standard Android location framework, not direct HAL access
 */

#ifndef ANDROID_HARDWARE_GNSS_VISIBILITY_CONTROL_IGNSSVISIBILITYCONTROLCALLBACK_H
#define ANDROID_HARDWARE_GNSS_VISIBILITY_CONTROL_IGNSSVISIBILITYCONTROLCALLBACK_H

#include <string>
#include <utils/RefBase.h>

// AIDL GNSS visibility control callback interface stubs
namespace android {
namespace hardware {
namespace gnss {
namespace visibility_control {

class IGnssVisibilityControlCallback : public ::android::RefBase {
 public:
  // Nested type for NFW (Non-Framework) notifications
  struct NfwNotification {
    std::string proxyAppPackageName;
    int32_t protocolStack;
    std::string otherProtocolStackName;
    int32_t requestor;
    std::string requestorId;
    int32_t responseType;
    bool inEmergencyMode;
    bool isCachedLocation;
  };

  virtual ~IGnssVisibilityControlCallback() = default;
};

}  // namespace visibility_control
}  // namespace gnss
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_GNSS_VISIBILITY_CONTROL_IGNSSVISIBILITYCONTROLCALLBACK_H
