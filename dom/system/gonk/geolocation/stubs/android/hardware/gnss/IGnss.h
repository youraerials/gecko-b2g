/*
 * Stub header for AIDL GNSS HAL - not built in vanilla AOSP for Pixel
 * Pixel uses standard Android location framework, not direct HAL access
 */

#ifndef ANDROID_HARDWARE_GNSS_IGNSS_H
#define ANDROID_HARDWARE_GNSS_IGNSS_H

#include <binder/Status.h>
#include <utils/StrongPointer.h>
#include <string>
#include <vector>

// AIDL GNSS stubs for compilation - vanilla AOSP for Pixel doesn't build these
namespace android {
namespace hardware {
namespace gnss {

// Forward declarations
class IGnssCallback;
class IAGnss;
class IAGnssCallback;
class IAGnssRil;

namespace visibility_control {
  class IGnssVisibilityControl;
}

// AIDL GNSS main interface
class IGnss : public ::android::RefBase {
 public:
  // Enums for position mode
  enum class GnssPositionMode : int32_t {
    STANDALONE = 0,
    MS_BASED = 1,
    MS_ASSISTED = 2,
  };

  enum class GnssPositionRecurrence : int32_t {
    RECURRENCE_PERIODIC = 0,
    RECURRENCE_SINGLE = 1,
  };

  // Nested type for position mode options
  struct PositionModeOptions {
    int32_t mode;
    int32_t recurrence;
    int32_t minIntervalMs;
    int32_t preferredAccuracyMeters;
    int32_t preferredTimeMs;
    bool lowPowerMode;
  };

  virtual ~IGnss() = default;

  // Methods that code calls
  virtual ::android::binder::Status setCallback(
      const android::sp<IGnssCallback>& callback) = 0;
  virtual ::android::binder::Status close() = 0;
  virtual ::android::binder::Status start() = 0;
  virtual ::android::binder::Status stop() = 0;
  virtual ::android::binder::Status startSvStatus() = 0;
  virtual ::android::binder::Status stopSvStatus() = 0;
  virtual ::android::binder::Status startNmea() = 0;
  virtual ::android::binder::Status stopNmea() = 0;
  virtual ::android::binder::Status setPositionMode(const PositionModeOptions& options) = 0;
  virtual ::android::binder::Status getExtensionGnssVisibilityControl(
      android::sp<visibility_control::IGnssVisibilityControl>* control) = 0;
  virtual ::android::binder::Status getExtensionAGnss(
      android::sp<IAGnss>* agnss) = 0;
  virtual ::android::binder::Status getExtensionAGnssRil(
      android::sp<IAGnssRil>* agnssRil) = 0;
};

class IAGnss : public ::android::RefBase {
 public:
  // Nested type for APN IP protocol
  enum class ApnIpType : int32_t {
    IPV4 = 1,
    IPV6 = 2,
    IPV4V6 = 3,
  };

  virtual ~IAGnss() = default;
  // Methods that code calls
  virtual ::android::binder::Status setCallback(
      const android::sp<class IAGnssCallback>& callback) = 0;
};

class IAGnssRil : public ::android::RefBase {
 public:
  // Nested type for network attributes
  struct NetworkAttributes {
    int64_t networkHandle;
    bool isConnected;
    int32_t capabilities;
    std::string apn;
  };

  virtual ~IAGnssRil() = default;
};

namespace visibility_control {
    class IGnssVisibilityControl : public ::android::RefBase {
     public:
      virtual ~IGnssVisibilityControl() = default;
      // Methods that code calls
      virtual ::android::binder::Status setCallback(
          const android::sp<class IGnssVisibilityControlCallback>& callback) = 0;
      virtual ::android::binder::Status enableNfwLocationAccess(
          const std::vector<std::string>& proxyApps) = 0;
    };
}

}  // namespace gnss
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_GNSS_IGNSS_H
