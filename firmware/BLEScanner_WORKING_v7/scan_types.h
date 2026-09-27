// Plain data records passed between scanner, queue and statistics modules.
#pragma once

#include "config.h"

struct PacketSnapshot {
  // BLEAddress native order under NimBLE is reversed relative to display order.
  uint8_t addrNative[6];
  uint8_t addrType;

  int16_t rssi;
  uint8_t advType;

  bool connectable;
  bool scannable;
  bool legacy;

  uint32_t receivedMs;

  uint16_t payloadLen;
  bool payloadTruncated;
  uint8_t payload[MAX_CAPTURE_PAYLOAD];
};

struct DeviceStats {
  bool used;

  uint8_t addrNative[6];
  uint8_t addrType;

  uint64_t reports;
  uint32_t firstSeenMs;
  uint32_t lastSeenMs;

  int16_t minRssi;
  int16_t maxRssi;
  double meanRssi;
  double m2Rssi;
  uint64_t rssiSamples;

  uint32_t lastArrivalMs;
  uint32_t intervalSamples;
  uint32_t minIntervalMs;
  uint32_t maxIntervalMs;
  double meanIntervalMs;

  uint32_t lastFingerprint;
  uint32_t payloadChanges;

  bool connectable;
  bool scannable;

  uint32_t advIndCount;
  uint32_t advDirectCount;
  uint32_t advScanCount;
  uint32_t advNonConnCount;
  uint32_t scanRspCount;
  uint32_t otherAdvCount;

  bool hasCompany;
  uint16_t companyId;

  bool hasName;
  char name[48];

  bool hasTxPower;
  int8_t txPower;

  bool hasAppearance;
  uint16_t appearance;
};
