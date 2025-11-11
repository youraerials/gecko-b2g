/*
 * Stub header for AIDL GNSS HAL - not built in vanilla AOSP for Pixel
 * Pixel uses standard Android location framework, not direct HAL access
 */

#ifndef ANDROID_HARDWARE_GNSS_VISIBILITY_CONTROL_BNGNSSVISIBILITYCONTROLCALLBACK_H
#define ANDROID_HARDWARE_GNSS_VISIBILITY_CONTROL_BNGNSSVISIBILITYCONTROLCALLBACK_H

#include <android/hardware/gnss/visibility_control/IGnssVisibilityControlCallback.h>
#include <binder/Status.h>

// AIDL GNSS visibility control binder native callback stub
namespace android {
namespace hardware {
namespace gnss {
namespace visibility_control {

// BnGnssVisibilityControlCallback is the native (server-side) binder stub
class BnGnssVisibilityControlCallback : public IGnssVisibilityControlCallback {
 public:
  virtual ~BnGnssVisibilityControlCallback() = default;

  // Pure virtual methods that implementations must override
  virtual ::android::binder::Status nfwNotifyCb(const NfwNotification& notification) = 0;
  virtual ::android::binder::Status isInEmergencySession(bool* _aidl_return) = 0;
};

}  // namespace visibility_control
}  // namespace gnss
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_GNSS_VISIBILITY_CONTROL_BNGNSSVISIBILITYCONTROLCALLBACK_H
