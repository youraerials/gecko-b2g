/*
 * Stub header for AIDL GNSS HAL - not built in vanilla AOSP for Pixel
 * Pixel uses standard Android location framework, not direct HAL access
 */

#ifndef ANDROID_HARDWARE_GNSS_BNAGNSSCALLBACK_H
#define ANDROID_HARDWARE_GNSS_BNAGNSSCALLBACK_H

#include <android/hardware/gnss/IAGnssCallback.h>
#include <binder/Status.h>

// AIDL Assisted GNSS binder native callback stub
namespace android {
namespace hardware {
namespace gnss {

// BnAGnssCallback is the native (server-side) binder stub
class BnAGnssCallback : public IAGnssCallback {
 public:
  virtual ~BnAGnssCallback() = default;

  // Pure virtual method that implementations must override
  virtual ::android::binder::Status agnssStatusCb(AGnssType type,
                                                  AGnssStatusValue status) = 0;
};

}  // namespace gnss
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_GNSS_BNAGNSSCALLBACK_H
