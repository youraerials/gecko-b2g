/*
 * Stub header for AIDL GNSS HAL - not built in vanilla AOSP for Pixel
 * Pixel uses standard Android location framework, not direct HAL access
 */

#ifndef ANDROID_HARDWARE_GNSS_IAGNSSCALLBACK_H
#define ANDROID_HARDWARE_GNSS_IAGNSSCALLBACK_H

#include <utils/RefBase.h>

// AIDL Assisted GNSS callback interface stubs
namespace android {
namespace hardware {
namespace gnss {

class IAGnssCallback : public ::android::RefBase {
 public:
  // Nested types for AGNSS callbacks
  enum class AGnssType : int32_t {
    SUPL = 1,
    C2K = 2,
    SUPL_EIMS = 3,
    SUPL_IMS = 4,
  };

  enum class AGnssStatusValue : int32_t {
    REQUEST_AGNSS_DATA_CONN = 1,
    RELEASE_AGNSS_DATA_CONN = 2,
    AGNSS_DATA_CONNECTED = 3,
    AGNSS_DATA_CONN_DONE = 4,
    AGNSS_DATA_CONN_FAILED = 5,
  };

  virtual ~IAGnssCallback() = default;
};

}  // namespace gnss
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_GNSS_IAGNSSCALLBACK_H
