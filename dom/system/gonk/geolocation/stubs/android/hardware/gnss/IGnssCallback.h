/*
 * Stub header for AIDL GNSS HAL - not built in vanilla AOSP for Pixel
 * Pixel uses standard Android location framework, not direct HAL access
 */

#ifndef ANDROID_HARDWARE_GNSS_IGNSSCALLBACK_H
#define ANDROID_HARDWARE_GNSS_IGNSSCALLBACK_H

#include <vector>
#include <string>
#include <utils/RefBase.h>

// AIDL GNSS callback interface stubs for compilation
namespace android {
namespace hardware {
namespace gnss {

class IGnssCallback : public ::android::RefBase {
 public:
  // Capability bit flags
  static constexpr int32_t CAPABILITY_SCHEDULING = 1 << 0;
  static constexpr int32_t CAPABILITY_MSB = 1 << 1;
  static constexpr int32_t CAPABILITY_MSA = 1 << 2;
  static constexpr int32_t CAPABILITY_SINGLE_SHOT = 1 << 3;
  static constexpr int32_t CAPABILITY_ON_DEMAND_TIME = 1 << 4;

  // Nested types used by callback methods
  enum class GnssStatusValue : int32_t {
    NONE = 0,
    SESSION_BEGIN = 1,
    SESSION_END = 2,
    ENGINE_ON = 3,
    ENGINE_OFF = 4,
  };

  struct GnssSvInfo {
    int32_t svid;
    int32_t constellation;
    float cN0DbHz;
    float elevationDegrees;
    float azimuthDegrees;
    float carrierFrequencyHz;
    int32_t svFlag;
  };

  struct GnssSystemInfo {
    int32_t yearOfHw;
    std::string name;
  };

  virtual ~IGnssCallback() = default;
};

}  // namespace gnss
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_GNSS_IGNSSCALLBACK_H
