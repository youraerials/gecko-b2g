/*
 * Stub header for AIDL GNSS HAL - not built in vanilla AOSP for Pixel
 * Pixel uses standard Android location framework, not direct HAL access
 */

#ifndef ANDROID_HARDWARE_GNSS_BNGNSSCALLBACK_H
#define ANDROID_HARDWARE_GNSS_BNGNSSCALLBACK_H

#include <android/hardware/gnss/IGnssCallback.h>
#include <binder/Status.h>
#include <utils/RefBase.h>

// AIDL GNSS binder native callback stub for compilation
namespace android {
namespace hardware {
namespace gnss {

// Forward declare GnssLocation
struct GnssLocation {
  double latitudeDegrees;
  double longitudeDegrees;
  double altitudeMeters;
  float speedMetersPerSec;
  float bearingDegrees;
  float horizontalAccuracyMeters;
  float verticalAccuracyMeters;
  float speedAccuracyMetersPerSecond;
  float bearingAccuracyDegrees;
  int64_t timestamp;
};

// BnGnssCallback is the native (server-side) binder stub
class BnGnssCallback : public IGnssCallback {
 public:
  virtual ~BnGnssCallback() = default;

  // Pure virtual methods that implementations must override
  virtual ::android::binder::Status gnssSetCapabilitiesCb(int32_t capabilities) = 0;
  virtual ::android::binder::Status gnssStatusCb(GnssStatusValue status) = 0;
  virtual ::android::binder::Status gnssSvStatusCb(
      const std::vector<GnssSvInfo>& svInfoList) = 0;
  virtual ::android::binder::Status gnssLocationCb(const GnssLocation& location) = 0;
  virtual ::android::binder::Status gnssNmeaCb(int64_t timestamp, const std::string& nmea) = 0;
  virtual ::android::binder::Status gnssAcquireWakelockCb() = 0;
  virtual ::android::binder::Status gnssReleaseWakelockCb() = 0;
  virtual ::android::binder::Status gnssSetSystemInfoCb(const GnssSystemInfo& info) = 0;
  virtual ::android::binder::Status gnssRequestTimeCb() = 0;
  virtual ::android::binder::Status gnssRequestLocationCb(bool independentFromGnss,
                                                          bool isUserEmergency) = 0;
};

}  // namespace gnss
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_GNSS_BNGNSSCALLBACK_H
