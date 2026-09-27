/*

  ESP32-S3-WROOM-1 NimBLE Research Scanner

  =========================================



  Target:

    - ESP32-S3 Dev Module / ESP32-S3-WROOM-1 family

    - Arduino-ESP32 3.3.12

    - FQBN: esp32:esp32:esp32s3

    - Arduino core's DEFAULT NimBLE backend



  This is a rewrite of the earlier Bluedroid-specific scanner.

  It intentionally DOES NOT call:

    setExtendedScanCallback()

    setExtScanParams()

    startExtScan()

    stopExtScan()

    esp_ble_gap_*()



  Those Arduino BLE5 extended-scan APIs are Bluedroid-only in the 3.3.x

  Arduino wrapper. This version uses the common BLEScan API backed by NimBLE.



  What this scanner does:

    - continuous near-100% duty legacy BLE advertising discovery

    - active or passive scanning

    - duplicate reports retained for RSSI/timing research

    - ADV + Scan Response raw payload capture

    - public/random/identity address classification

    - RPA / NRPA / static-random classification

    - RSSI min / mean / max / standard deviation

    - advertising cadence min / mean / max

    - payload fingerprints and change counting

    - connectable/scannable/event type

    - local name extraction

    - manufacturer Company ID extraction

    - service UUID / service-data decoding

    - appearance / TX-power / advertising-interval decoding

    - Apple iBeacon decoder

    - Google Eddystone UID / URL / TLM / EID decoder

    - raw payload dump

    - ring buffer so Serial output stays outside the NimBLE callback

    - finite scan slices automatically restarted to flush devices that do not

      answer active Scan Requests and to prevent Arduino's result map from

      growing forever with rotating BLE addresses

    - interactive runtime controls over Serial

    - BLE HID MODE: advertise as a composite BLE keyboard + mouse with

      Just Works bonding (no PIN prompt) so pairing / driver-install /

      input-injection detection can be tested against the lab Win11

      target (Defender + Sysmon + Wazuh). Commands:

        b : enter HID mode (pauses scanner, starts HID advertising)

        B : exit HID mode (stops HID advertising, scanner stays paused)

        t : while HID-connected, send a benign test injection

            (Shift press/release + mouse jiggle)



  Hardware/API limitation:

    Arduino-ESP32 3.3.12's NimBLE BLEScan wrapper currently exposes legacy

    discovery, not its Bluedroid BLE5 extended-scan API. Therefore this sketch

    does not report extended-advertising SID, secondary PHY, periodic advertising,

    or exact RF advertising channel 37/38/39.



  Boot behavior:

    - scanner starts IDLE

    - no packet dump

    - no automatic summaries

    - user selects scan mode from Serial

    - HID mode is never entered automatically; user selects it via 'b'



  Serial Monitor: 921600 baud

*/



#include <Arduino.h>

#include <BLEDevice.h>

#include <BLEUtils.h>

#include <BLEScan.h>

#include <BLEAdvertisedDevice.h>

#include <BLEServer.h>

#include <BLEHIDDevice.h>
#include <BLESecurity.h>

#include <math.h>

#include <string.h>



#ifndef CONFIG_NIMBLE_ENABLED

#error "This sketch requires the Arduino-ESP32 NimBLE backend. Use ESP32 core 3.3.x with ESP32S3 Dev Module."

#endif



#if defined(ARDUINO_OZOBOT_DRVKIT)

#error "Wrong board selected. Choose Tools > Board > esp32 > ESP32S3 Dev Module."

#endif



// ============================================================================

// Configuration

// ============================================================================



static constexpr uint32_t SERIAL_BAUD = 921600;



// Arduino BLEScan accepts milliseconds and converts them to BLE units.

// Equal interval and window requests essentially continuous receiver duty.

static constexpr uint16_t SCAN_INTERVAL_MS = 50;

static constexpr uint16_t SCAN_WINDOW_MS   = 50;



// A finite slice is deliberate. In active mode Arduino's NimBLE wrapper can

// wait for a Scan Response before invoking the callback for scannable devices.

// Ending/restarting the slice flushes non-responders and clears its result map.

static constexpr uint32_t SCAN_SLICE_SECONDS = 30;



static constexpr uint32_t SUMMARY_INTERVAL_MS = 15000;



static constexpr size_t PACKET_QUEUE_LEN = 128;



// Legacy ADV + Scan Response is normally <= 62 bytes. Keep extra headroom.

static constexpr size_t MAX_CAPTURE_PAYLOAD = 96;



static constexpr size_t MAX_TRACKED = 256;



// ============================================================================

// Runtime controls

// ============================================================================



static bool g_activeScan      = true;

static bool g_keepDuplicates = true;

static bool g_verbosePackets  = false;

static bool g_printRaw        = false;

static bool g_decodeAD        = true;

static bool g_paused          = true;

static int8_t g_printRssiFloor = -127;

static bool g_autoSummary     = false;



// ============================================================================

// Structures

// ============================================================================



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



// ============================================================================

// Globals

// ============================================================================



static BLEScan* g_scan = nullptr;



static PacketSnapshot g_queue[PACKET_QUEUE_LEN];

static volatile size_t g_queueHead = 0;

static volatile size_t g_queueTail = 0;

static volatile uint32_t g_queueDrops = 0;

static portMUX_TYPE g_queueMux = portMUX_INITIALIZER_UNLOCKED;



static DeviceStats g_stats[MAX_TRACKED];



static volatile bool g_scanSliceEnded = false;



static uint64_t g_totalReports = 0;

static uint32_t g_statsDrops = 0;

static uint32_t g_scanSlices = 0;

static uint32_t g_scanStartFailures = 0;

static uint32_t g_lastSummaryMs = 0;



// ============================================================================

// BLE HID mode globals

// ============================================================================



static bool g_hidMode = false;      // 'b' entered HID mode

static bool g_hidBuilt = false;     // HID server has been constructed once

static bool g_hidConnected = false;



static BLEServer* g_hidServer = nullptr;

static BLEHIDDevice* g_hid = nullptr;

static BLECharacteristic* g_keyboardInput = nullptr;

static BLECharacteristic* g_mouseInput = nullptr;



// Composite HID report map: keyboard (report ID 1) + mouse (report ID 2).

// Standard Boot-Keyboard-compatible descriptors so Windows loads the

// built-in HID class driver without any vendor driver download.

static const uint8_t HID_REPORT_MAP[] = {

  // --- Keyboard, report ID 1, 8-byte boot report ---

  0x05, 0x01,       // Usage Page (Generic Desktop)

  0x09, 0x06,       // Usage (Keyboard)

  0xA1, 0x01,       // Collection (Application)

  0x85, 0x01,       //   Report ID (1)

  0x05, 0x07,       //   Usage Page (Key Codes)

  0x19, 0xE0,       //   Usage Minimum (224 - LeftControl)

  0x29, 0xE7,       //   Usage Maximum (231 - RightGUI)

  0x15, 0x00,       //   Logical Minimum (0)

  0x25, 0x01,       //   Logical Maximum (1)

  0x75, 0x01,       //   Report Size (1)

  0x95, 0x08,       //   Report Count (8)

  0x81, 0x02,       //   Input (Data, Var, Abs) - modifier byte

  0x95, 0x01,       //   Report Count (1)

  0x75, 0x08,       //   Report Size (8)

  0x81, 0x01,       //   Input (Const) - reserved byte

  0x95, 0x06,       //   Report Count (6)

  0x75, 0x08,       //   Report Size (8)

  0x26, 0xFF, 0x00,  //   Logical Maximum (255)

  0x05, 0x07,       //   Usage Page (Key Codes)

  0x19, 0x00,       //   Usage Minimum (0)

  0x29, 0x91,       //   Usage Maximum (145)

  0x81, 0x00,       //   Input (Data, Array) - key array

  0xC0,             // End Collection



  // --- Mouse, report ID 2, 4-byte report (buttons + X + Y + wheel) ---

  0x05, 0x01,       // Usage Page (Generic Desktop)

  0x09, 0x02,       // Usage (Mouse)

  0xA1, 0x01,       // Collection (Application)

  0x85, 0x02,       //   Report ID (2)

  0x09, 0x01,       //   Usage (Pointer)

  0xA1, 0x00,       //   Collection (Physical)

  0x05, 0x09,       //     Usage Page (Buttons)

  0x19, 0x01,       //     Usage Minimum (1)

  0x29, 0x03,       //     Usage Maximum (3)

  0x15, 0x00,       //     Logical Minimum (0)

  0x25, 0x01,       //     Logical Maximum (1)

  0x75, 0x01,       //     Report Size (1)

  0x95, 0x03,       //     Report Count (3)

  0x81, 0x02,       //     Input (Data, Var, Abs) - buttons

  0x95, 0x01,       //     Report Count (1)

  0x75, 0x05,       //     Report Size (5)

  0x81, 0x01,       //     Input (Const) - padding

  0x05, 0x01,       //     Usage Page (Generic Desktop)

  0x09, 0x30,       //     Usage (X)

  0x09, 0x31,       //     Usage (Y)

  0x15, 0x81,       //     Logical Minimum (-127)

  0x25, 0x7F,       //     Logical Maximum (127)

  0x75, 0x08,       //     Report Size (8)

  0x95, 0x02,       //     Report Count (2)

  0x81, 0x06,       //     Input (Data, Var, Rel) - X, Y

  0x09, 0x38,       //     Usage (Wheel)

  0x15, 0x81,       //     Logical Minimum (-127)

  0x25, 0x7F,       //     Logical Maximum (127)

  0x75, 0x08,       //     Report Size (8)

  0x95, 0x01,       //     Report Count (1)

  0x81, 0x06,       //     Input (Data, Var, Rel) - wheel

  0xC0,             //   End Collection (Physical)

  0xC0              // End Collection

};



// ============================================================================

// Address helpers

// ============================================================================



static bool sameAddress(const uint8_t* a, const uint8_t* b) {

  return memcmp(a, b, 6) == 0;

}



static void printAddress(const uint8_t* nativeAddr) {

  // NimBLE stores native bytes in reverse display order.

  Serial.printf("%02X:%02X:%02X:%02X:%02X:%02X",

                nativeAddr[5], nativeAddr[4], nativeAddr[3],

                nativeAddr[2], nativeAddr[1], nativeAddr[0]);

}



static const char* addrTypeName(uint8_t t) {

  switch (t) {

    case 0: return "public";

    case 1: return "random";

    case 2: return "public_identity";

    case 3: return "random_identity";

    default: return "unknown";

  }

}



static const char* randomAddrSubtype(const uint8_t* nativeAddr, uint8_t addrType) {

  if (addrType != 1 && addrType != 3) {

    return "n/a";

  }



  // Display-order MSB is nativeAddr[5] for NimBLE.

  switch ((nativeAddr[5] >> 6) & 0x03) {

    case 0x03: return "static_random";

    case 0x01: return "resolvable_private";

    case 0x00: return "non_resolvable_private";

    default:   return "reserved_random";

  }

}



// ============================================================================

// Generic helpers

// ============================================================================



static void printHex(const uint8_t* data, size_t len) {

  static const char hex[] = "0123456789ABCDEF";



  for (size_t i = 0; i < len; ++i) {

    Serial.write(hex[(data[i] >> 4) & 0x0F]);

    Serial.write(hex[data[i] & 0x0F]);

  }

}



static uint16_t le16(const uint8_t* p) {

  return (uint16_t)p[0] | ((uint16_t)p[1] << 8);

}



static uint32_t le32(const uint8_t* p) {

  return ((uint32_t)p[0]) |

         ((uint32_t)p[1] << 8) |

         ((uint32_t)p[2] << 16) |

         ((uint32_t)p[3] << 24);

}



static uint16_t be16(const uint8_t* p) {

  return ((uint16_t)p[0] << 8) | (uint16_t)p[1];

}



static uint32_t be32(const uint8_t* p) {

  return ((uint32_t)p[0] << 24) |

         ((uint32_t)p[1] << 16) |

         ((uint32_t)p[2] << 8) |

         (uint32_t)p[3];

}



static uint32_t fnv1a32(const uint8_t* data, size_t len) {

  uint32_t h = 2166136261UL;



  for (size_t i = 0; i < len; ++i) {

    h ^= data[i];

    h *= 16777619UL;

  }



  return h;

}



static void printEscapedText(const uint8_t* data, size_t len) {

  Serial.write('"');



  for (size_t i = 0; i < len; ++i) {

    const uint8_t c = data[i];



    if (c == '"' || c == '\\') {

      Serial.write('\\');

      Serial.write(c);

    } else if (c >= 32 && c <= 126) {

      Serial.write(c);

    } else {

      Serial.printf("\\x%02X", c);

    }

  }



  Serial.write('"');

}



static void printUUID128(const uint8_t* d) {

  // BLE advertising UUID values are transmitted least-significant octet first.

  for (int i = 15; i >= 0; --i) {

    Serial.printf("%02X", d[i]);



    if (i == 12 || i == 10 || i == 8 || i == 6) {

      Serial.write('-');

    }

  }

}



static const char* uuid16Name(uint16_t uuid) {

  switch (uuid) {

    case 0x1800: return "Generic Access";

    case 0x1801: return "Generic Attribute";

    case 0x1802: return "Immediate Alert";

    case 0x1803: return "Link Loss";

    case 0x1804: return "Tx Power";

    case 0x1805: return "Current Time";

    case 0x180A: return "Device Information";

    case 0x180D: return "Heart Rate";

    case 0x180F: return "Battery Service";

    case 0x1812: return "Human Interface Device";

    case 0x181A: return "Environmental Sensing";

    case 0x181C: return "User Data";

    case 0x181D: return "Weight Scale";

    case 0x1826: return "Fitness Machine";

    case 0x1827: return "Mesh Provisioning";

    case 0x1828: return "Mesh Proxy";

    case 0x1848: return "Media Control";

    case 0xFD6F: return "Exposure Notification";

    case 0xFEAA: return "Eddystone";

    default: return nullptr;

  }

}



static const char* companyName(uint16_t id) {

  // Small, conservative subset of Bluetooth SIG Company Identifiers.

  switch (id) {

    case 0x0002: return "Intel";

    case 0x0006: return "Microsoft";

    case 0x004C: return "Apple";

    case 0x0059: return "Nordic Semiconductor";

    case 0x00E0: return "Google";

    case 0x02E5: return "Espressif";

    default: return nullptr;

  }

}



static void printUUID16List(const uint8_t* d, size_t len) {

  bool first = true;



  for (size_t i = 0; i + 1 < len; i += 2) {

    const uint16_t uuid = le16(d + i);



    if (!first) Serial.print(", ");



    Serial.printf("0x%04X", uuid);



    if (const char* n = uuid16Name(uuid)) {

      Serial.print("(");

      Serial.print(n);

      Serial.print(")");

    }



    first = false;

  }

}



static void printUUID32List(const uint8_t* d, size_t len) {

  bool first = true;



  for (size_t i = 0; i + 3 < len; i += 4) {

    if (!first) Serial.print(", ");



    Serial.printf("0x%08lX", (unsigned long)le32(d + i));

    first = false;

  }

}



// ============================================================================

// Advertising event type

// ============================================================================



static const char* advTypeName(uint8_t t) {

  switch (t) {

    case BLE_HCI_ADV_RPT_EVTYPE_ADV_IND:     return "ADV_IND";

    case BLE_HCI_ADV_RPT_EVTYPE_DIR_IND:    return "ADV_DIRECT_IND";

    case BLE_HCI_ADV_RPT_EVTYPE_SCAN_IND:   return "ADV_SCAN_IND";

    case BLE_HCI_ADV_RPT_EVTYPE_NONCONN_IND:return "ADV_NONCONN_IND";

    case BLE_HCI_ADV_RPT_EVTYPE_SCAN_RSP:   return "SCAN_RSP";

    default: return "UNKNOWN";

  }

}



// ============================================================================

// Specialized payload decoders

// ============================================================================



static void decodeIBeacon(const uint8_t* manufacturerPayload, size_t len) {

  // Apple manufacturer payload after Company ID:

  // 02 15 | UUID(16) | major(2) | minor(2) | measured power(1)

  if (len < 23) return;

  if (manufacturerPayload[0] != 0x02 || manufacturerPayload[1] != 0x15) return;



  Serial.print("    iBeacon UUID=");



  const uint8_t* u = manufacturerPayload + 2;



  for (int i = 0; i < 16; ++i) {

    Serial.printf("%02X", u[i]);



    if (i == 3 || i == 5 || i == 7 || i == 9) {

      Serial.write('-');

    }

  }



  const uint16_t major = be16(manufacturerPayload + 18);

  const uint16_t minor = be16(manufacturerPayload + 20);

  const int8_t measuredPower = (int8_t)manufacturerPayload[22];



  Serial.printf(" major=%u minor=%u measuredPower=%d_dBm\n",

                (unsigned)major,

                (unsigned)minor,

                (int)measuredPower);

}



static const char* eddystoneUrlScheme(uint8_t code) {

  switch (code) {

    case 0x00: return "http://www.";

    case 0x01: return "https://www.";

    case 0x02: return "http://";

    case 0x03: return "https://";

    default: return nullptr;

  }

}



static const char* eddystoneUrlExpansion(uint8_t code) {

  switch (code) {

    case 0x00: return ".com/";

    case 0x01: return ".org/";

    case 0x02: return ".edu/";

    case 0x03: return ".net/";

    case 0x04: return ".info/";

    case 0x05: return ".biz/";

    case 0x06: return ".gov/";

    case 0x07: return ".com";

    case 0x08: return ".org";

    case 0x09: return ".edu";

    case 0x0A: return ".net";

    case 0x0B: return ".info";

    case 0x0C: return ".biz";

    case 0x0D: return ".gov";

    default: return nullptr;

  }

}



static void decodeEddystone(const uint8_t* data, size_t len) {

  if (len < 1) return;



  switch (data[0]) {

    case 0x00: { // UID

      if (len < 18) return;



      Serial.printf("    Eddystone-UID tx=%d namespace=", (int8_t)data[1]);

      printHex(data + 2, 10);

      Serial.print(" instance=");

      printHex(data + 12, 6);

      Serial.println();

      break;

    }



    case 0x10: { // URL

      if (len < 3) return;



      Serial.printf("    Eddystone-URL tx=%d url=", (int8_t)data[1]);



      const char* scheme = eddystoneUrlScheme(data[2]);



      if (scheme) {

        Serial.print(scheme);

      } else {

        Serial.printf("<scheme:%02X>", data[2]);

      }



      for (size_t i = 3; i < len; ++i) {

        const char* expansion = eddystoneUrlExpansion(data[i]);



        if (expansion) {

          Serial.print(expansion);

        } else if (data[i] >= 32 && data[i] <= 126) {

          Serial.write(data[i]);

        } else {

          Serial.printf("\\x%02X", data[i]);

        }

      }



      Serial.println();

      break;

    }



    case 0x20: { // TLM

      if (len < 14) return;



      const uint8_t version = data[1];

      const uint16_t battMv = be16(data + 2);

      const int16_t tempRaw = (int16_t)be16(data + 4);

      const float tempC = (float)tempRaw / 256.0f;

      const uint32_t advCount = be32(data + 6);

      const uint32_t deciSeconds = be32(data + 10);



      Serial.printf(

          "    Eddystone-TLM v=%u batt=%u_mV temp=%.2f_C advCount=%lu uptime=%.1f_s\n",

          (unsigned)version,

          (unsigned)battMv,

          tempC,

          (unsigned long)advCount,

          deciSeconds / 10.0f);

      break;

    }



    case 0x30: { // EID

      if (len < 10) return;



      Serial.printf("    Eddystone-EID tx=%d eid=", (int8_t)data[1]);

      printHex(data + 2, 8);

      Serial.println();

      break;

    }



    default:

      Serial.printf("    Eddystone frame=0x%02X raw=", data[0]);

      printHex(data, len);

      Serial.println();

      break;

  }

}



// ============================================================================

// AD-structure parsing / identity extraction

// ============================================================================



static void copyName(DeviceStats& s, const uint8_t* d, size_t len) {

  if (len == 0) return;



  size_t n = len;

  if (n > sizeof(s.name) - 1) {

    n = sizeof(s.name) - 1;

  }



  for (size_t i = 0; i < n; ++i) {

    const uint8_t c = d[i];

    s.name[i] = (c >= 32 && c <= 126) ? (char)c : '.';

  }



  s.name[n] = '\0';

  s.hasName = true;

}



static void extractIdentity(DeviceStats& s, const uint8_t* p, size_t len) {

  size_t i = 0;



  while (i < len) {

    const uint8_t fieldLen = p[i];



    if (fieldLen == 0) break;



    const size_t end = i + 1u + fieldLen;



    if (fieldLen < 1 || end > len) break;



    const uint8_t type = p[i + 1];

    const uint8_t* d = p + i + 2;

    const size_t dlen = fieldLen - 1;



    switch (type) {

      case 0x08:

        if (!s.hasName && dlen > 0) {

          copyName(s, d, dlen);

        }

        break;



      case 0x09:

        if (dlen > 0) {

          copyName(s, d, dlen);

        }

        break;



      case 0x0A:

        if (dlen >= 1) {

          s.txPower = (int8_t)d[0];

          s.hasTxPower = true;

        }

        break;



      case 0x19:

        if (dlen >= 2) {

          s.appearance = le16(d);

          s.hasAppearance = true;

        }

        break;



      case 0xFF:

        if (dlen >= 2) {

          s.companyId = le16(d);

          s.hasCompany = true;

        }

        break;



      default:

        break;

    }



    i = end;

  }

}



static void decodeFlags(uint8_t f) {

  Serial.printf("0x%02X[", f);



  bool first = true;



  auto add = [&](const char* s) {

    if (!first) Serial.print(",");

    Serial.print(s);

    first = false;

  };



  if (f & 0x01) add("limited_disc");

  if (f & 0x02) add("general_disc");

  if (f & 0x04) add("BR_EDR_not_supported");

  if (f & 0x08) add("simul_LE_BR_EDR_controller");

  if (f & 0x10) add("simul_LE_BR_EDR_host");



  Serial.print("]");

}



static void decodeAD(const uint8_t* p, size_t len) {

  size_t i = 0;



  while (i < len) {

    const uint8_t fieldLen = p[i];



    if (fieldLen == 0) {

      break;

    }



    const size_t end = i + 1u + fieldLen;



    if (fieldLen < 1 || end > len) {

      Serial.printf("  AD malformed offset=%u fieldLen=%u remaining=%u\n",

                    (unsigned)i,

                    (unsigned)fieldLen,

                    (unsigned)(len - i));

      break;

    }



    const uint8_t type = p[i + 1];

    const uint8_t* d = p + i + 2;

    const size_t dlen = fieldLen - 1;



    Serial.printf("  AD type=0x%02X len=%u ", type, (unsigned)dlen);



    switch (type) {

      case 0x01:

        Serial.print("Flags=");

        if (dlen >= 1) decodeFlags(d[0]);

        break;



      case 0x02:

        Serial.print("UUID16_incomplete=");

        printUUID16List(d, dlen);

        break;



      case 0x03:

        Serial.print("UUID16=");

        printUUID16List(d, dlen);

        break;



      case 0x04:

        Serial.print("UUID32_incomplete=");

        printUUID32List(d, dlen);

        break;



      case 0x05:

        Serial.print("UUID32=");

        printUUID32List(d, dlen);

        break;



      case 0x06:

      case 0x07: {

        Serial.print(type == 0x07 ? "UUID128=" : "UUID128_incomplete=");



        bool first = true;



        for (size_t x = 0; x + 15 < dlen; x += 16) {

          if (!first) Serial.print(", ");

          printUUID128(d + x);

          first = false;

        }

        break;

      }



      case 0x08:

        Serial.print("ShortName=");

        printEscapedText(d, dlen);

        break;



      case 0x09:

        Serial.print("Name=");

        printEscapedText(d, dlen);

        break;



      case 0x0A:

        if (dlen >= 1) {

          Serial.printf("AdvTxPower=%d_dBm", (int8_t)d[0]);

        }

        break;



      case 0x12:

        if (dlen >= 4) {

          Serial.printf("ConnIntervalRange min=0x%04X max=0x%04X",

                        le16(d),

                        le16(d + 2));

        }

        break;



      case 0x14:

        Serial.print("SolicitUUID16=");

        printUUID16List(d, dlen);

        break;



      case 0x15:

        Serial.print("SolicitUUID128=");



        for (size_t x = 0; x + 15 < dlen; x += 16) {

          if (x) Serial.print(", ");

          printUUID128(d + x);

        }

        break;



      case 0x16: {

        if (dlen >= 2) {

          const uint16_t uuid = le16(d);



          Serial.printf("ServiceData16 UUID=0x%04X", uuid);



          if (const char* n = uuid16Name(uuid)) {

            Serial.print("(");

            Serial.print(n);

            Serial.print(")");

          }



          Serial.print(" data=");

          printHex(d + 2, dlen - 2);

          Serial.println();



          if (uuid == 0xFEAA) {

            decodeEddystone(d + 2, dlen - 2);

          }



          i = end;

          continue;

        }

        break;

      }



      case 0x17:

        Serial.print("PublicTargetAddress=");

        printHex(d, dlen);

        break;



      case 0x18:

        Serial.print("RandomTargetAddress=");

        printHex(d, dlen);

        break;



      case 0x19:

        if (dlen >= 2) {

          Serial.printf("Appearance=0x%04X", le16(d));

        }

        break;



      case 0x1A:

        if (dlen >= 2) {

          const uint16_t n = le16(d);



          Serial.printf("AdvertisingInterval=%u_units %.3f_ms",

                        (unsigned)n,

                        n * 0.625f);

        }

        break;



      case 0x1B:

        Serial.print("LE_Device_Address=");

        printHex(d, dlen);

        break;



      case 0x1C:

        if (dlen >= 1) {

          Serial.printf("LE_Role=0x%02X", d[0]);

        }

        break;



      case 0x1F:

        Serial.print("SolicitUUID32=");

        printUUID32List(d, dlen);

        break;



      case 0x20:

        if (dlen >= 4) {

          Serial.printf("ServiceData32 UUID=0x%08lX data=",

                        (unsigned long)le32(d));

          printHex(d + 4, dlen - 4);

        }

        break;



      case 0x21:

        if (dlen >= 16) {

          Serial.print("ServiceData128 UUID=");

          printUUID128(d);

          Serial.print(" data=");

          printHex(d + 16, dlen - 16);

        }

        break;



      case 0x24:

        Serial.print("URI_encoded=");

        printHex(d, dlen);

        break;



      case 0x27:

        Serial.print("LE_Supported_Features=");

        printHex(d, dlen);

        break;



      case 0x30:

        Serial.print("BroadcastName=");

        printEscapedText(d, dlen);

        break;



      case 0x31:

        Serial.print("EncryptedAdvertisingData=");

        printHex(d, dlen);

        break;



      case 0xFF: {

        if (dlen >= 2) {

          const uint16_t companyId = le16(d);



          Serial.printf("Manufacturer CompanyID=0x%04X", companyId);



          if (const char* company = companyName(companyId)) {

            Serial.print("(");

            Serial.print(company);

            Serial.print(")");

          }



          Serial.print(" data=");

          printHex(d + 2, dlen - 2);

          Serial.println();



          if (companyId == 0x004C) {

            decodeIBeacon(d + 2, dlen - 2);

          }



          i = end;

          continue;

        }



        Serial.print("ManufacturerData=");

        printHex(d, dlen);

        break;

      }



      default:

        Serial.print("Raw=");

        printHex(d, dlen);

        break;

    }



    Serial.println();

    i = end;

  }

}



// ============================================================================

// Ring buffer

// ============================================================================



static bool enqueuePacket(const PacketSnapshot& packet) {

  bool ok = false;



  portENTER_CRITICAL(&g_queueMux);



  const size_t next = (g_queueHead + 1) % PACKET_QUEUE_LEN;



  if (next != g_queueTail) {

    g_queue[g_queueHead] = packet;

    g_queueHead = next;

    ok = true;

  } else {

    ++g_queueDrops;

  }



  portEXIT_CRITICAL(&g_queueMux);



  return ok;

}



static bool dequeuePacket(PacketSnapshot& packet) {

  bool ok = false;



  portENTER_CRITICAL(&g_queueMux);



  if (g_queueTail != g_queueHead) {

    packet = g_queue[g_queueTail];

    g_queueTail = (g_queueTail + 1) % PACKET_QUEUE_LEN;

    ok = true;

  }



  portEXIT_CRITICAL(&g_queueMux);



  return ok;

}



// ============================================================================

// Statistics

// ============================================================================



static DeviceStats* findStats(const PacketSnapshot& p) {

  for (size_t i = 0; i < MAX_TRACKED; ++i) {

    if (!g_stats[i].used) continue;



    if (g_stats[i].addrType == p.addrType &&

        sameAddress(g_stats[i].addrNative, p.addrNative)) {

      return &g_stats[i];

    }

  }



  return nullptr;

}



static DeviceStats* findOrCreateStats(const PacketSnapshot& p) {

  if (DeviceStats* existing = findStats(p)) {

    return existing;

  }



  for (size_t i = 0; i < MAX_TRACKED; ++i) {

    if (g_stats[i].used) continue;



    DeviceStats& s = g_stats[i];

    memset(&s, 0, sizeof(s));



    s.used = true;

    memcpy(s.addrNative, p.addrNative, 6);

    s.addrType = p.addrType;



    s.firstSeenMs = p.receivedMs;

    s.lastSeenMs = p.receivedMs;

    s.lastArrivalMs = p.receivedMs;



    s.minRssi = p.rssi;

    s.maxRssi = p.rssi;

    s.minIntervalMs = UINT32_MAX;



    return &s;

  }



  ++g_statsDrops;

  return nullptr;

}



static void updateStats(DeviceStats& s, const PacketSnapshot& p) {

  ++s.reports;

  s.lastSeenMs = p.receivedMs;



  s.connectable = s.connectable || p.connectable;

  s.scannable = s.scannable || p.scannable;



  if (p.rssi != 127) {

    if (p.rssi < s.minRssi) s.minRssi = p.rssi;

    if (p.rssi > s.maxRssi) s.maxRssi = p.rssi;



    ++s.rssiSamples;



    const double delta = (double)p.rssi - s.meanRssi;

    s.meanRssi += delta / (double)s.rssiSamples;

    const double delta2 = (double)p.rssi - s.meanRssi;

    s.m2Rssi += delta * delta2;

  }



  if (s.reports > 1) {

    const uint32_t dt = p.receivedMs - s.lastArrivalMs;



    if (dt < s.minIntervalMs) s.minIntervalMs = dt;

    if (dt > s.maxIntervalMs) s.maxIntervalMs = dt;



    ++s.intervalSamples;



    const double delta = (double)dt - s.meanIntervalMs;

    s.meanIntervalMs += delta / (double)s.intervalSamples;

  }



  s.lastArrivalMs = p.receivedMs;



  switch (p.advType) {

    case BLE_HCI_ADV_RPT_EVTYPE_ADV_IND:

      ++s.advIndCount;

      break;



    case BLE_HCI_ADV_RPT_EVTYPE_DIR_IND:

      ++s.advDirectCount;

      break;



    case BLE_HCI_ADV_RPT_EVTYPE_SCAN_IND:

      ++s.advScanCount;

      break;



    case BLE_HCI_ADV_RPT_EVTYPE_NONCONN_IND:

      ++s.advNonConnCount;

      break;



    case BLE_HCI_ADV_RPT_EVTYPE_SCAN_RSP:

      ++s.scanRspCount;

      break;



    default:

      ++s.otherAdvCount;

      break;

  }



  const uint32_t fingerprint = fnv1a32(p.payload, p.payloadLen);



  if (s.reports > 1 &&

      s.lastFingerprint != 0 &&

      fingerprint != s.lastFingerprint) {

    ++s.payloadChanges;

  }



  s.lastFingerprint = fingerprint;



  extractIdentity(s, p.payload, p.payloadLen);

}



// ============================================================================

// Packet processing / display

// ============================================================================



static void processPacket(const PacketSnapshot& p) {

  ++g_totalReports;



  DeviceStats* s = findOrCreateStats(p);

  if (!s) return;



  updateStats(*s, p);



  if (!g_verbosePackets) return;

  if (p.rssi != 127 && p.rssi < g_printRssiFloor) return;



  Serial.println();

  Serial.println("----- BLE / NimBLE REPORT -----");



  Serial.printf("t_ms=%lu report=%llu addr=",

                (unsigned long)p.receivedMs,

                (unsigned long long)g_totalReports);



  printAddress(p.addrNative);



  Serial.printf(" addr_type=%u(%s) subtype=%s",

                (unsigned)p.addrType,

                addrTypeName(p.addrType),

                randomAddrSubtype(p.addrNative, p.addrType));



  if (p.rssi == 127) {

    Serial.print(" rssi=NA");

  } else {

    Serial.printf(" rssi=%d_dBm", (int)p.rssi);

  }



  Serial.printf(" adv_type=%u(%s) connectable=%s scannable=%s legacy=%s",

                (unsigned)p.advType,

                advTypeName(p.advType),

                p.connectable ? "yes" : "no",

                p.scannable ? "yes" : "no",

                p.legacy ? "yes" : "no");



  Serial.printf(" payload_len=%u fingerprint=0x%08lX",

                (unsigned)p.payloadLen,

                (unsigned long)fnv1a32(p.payload, p.payloadLen));



  if (p.payloadTruncated) {

    Serial.print(" local_capture_truncated=yes");

  }



  if (s->hasName) {

    Serial.print(" name="");

    Serial.print(s->name);

    Serial.print(""");

  }



  if (s->hasCompany) {

    Serial.printf(" company_id=0x%04X", s->companyId);



    if (const char* company = companyName(s->companyId)) {

      Serial.print("(");

      Serial.print(company);

      Serial.print(")");

    }

  }



  if (s->hasTxPower) {

    Serial.printf(" adv_tx=%d_dBm", (int)s->txPower);

  }



  if (s->hasAppearance) {

    Serial.printf(" appearance=0x%04X", s->appearance);

  }



  Serial.println();



  if (g_printRaw) {

    Serial.print("raw=");

    printHex(p.payload, p.payloadLen);

    Serial.println();

  }



  if (g_decodeAD && p.payloadLen > 0) {

    decodeAD(p.payload, p.payloadLen);

  }

}



// ============================================================================

// BLE callbacks

// ============================================================================



class ResearchAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {

 public:

  void onResult(BLEAdvertisedDevice advertisedDevice) override {

    PacketSnapshot p = {};



    BLEAddress address = advertisedDevice.getAddress();

    memcpy(p.addrNative, address.getNative(), 6);



    p.addrType = advertisedDevice.getAddressType();

    p.rssi = advertisedDevice.getRSSI();

    p.advType = advertisedDevice.getAdvType();



    p.connectable = advertisedDevice.isConnectable();

    p.scannable = advertisedDevice.isScannable();

    p.legacy = advertisedDevice.isLegacyAdvertisement();



    p.receivedMs = millis();



    const uint8_t* raw = advertisedDevice.getPayload();

    const size_t rawLen = advertisedDevice.getPayloadLength();



    size_t copyLen = rawLen;

    if (copyLen > MAX_CAPTURE_PAYLOAD) {

      copyLen = MAX_CAPTURE_PAYLOAD;

      p.payloadTruncated = true;

    }



    if (raw != nullptr && copyLen > 0) {

      memcpy(p.payload, raw, copyLen);

    }



    p.payloadLen = (uint16_t)copyLen;



    // Do not print/parse here. This callback runs in the BLE host context.

    enqueuePacket(p);

  }

};



static ResearchAdvertisedDeviceCallbacks g_callbacks;



static void scanComplete(BLEScanResults results) {

  // Keep the completion callback tiny; restart happens from loop().

  (void)results;

  g_scanSliceEnded = true;

}



// ============================================================================

// HID server callbacks (connection events logged for detection correlation)

// ============================================================================



class HidServerCallbacks : public BLEServerCallbacks {

 public:

  void onConnect(BLEServer* server) override {

    (void)server;

    g_hidConnected = true;

    Serial.println();

    Serial.println("[HID] Central CONNECTED. Pairing/bonding in progress.");

    Serial.println("[HID] Watch the Win11 target now: Defender history,");

    Serial.println("[HID] Sysmon events, and the Bluetooth devices list.");

  }



  void onDisconnect(BLEServer* server) override {

    (void)server;

    g_hidConnected = false;

    Serial.println("[HID] Central disconnected.");

    // Re-advertise so a new pairing attempt can be made without a reboot.

    if (g_hidMode && server->getAdvertising() != nullptr) {

      server->getAdvertising()->start();

      Serial.println("[HID] Re-advertising.");

    }

  }

};



static HidServerCallbacks g_hidServerCallbacks;



// ============================================================================

// HID mode control

// ============================================================================



static void startHidMode() {

  if (g_hidMode) {

    Serial.println("HID mode already active.");

    return;

  }



  // Scanner and HID roles cannot share the radio; pause scanning first.

  stopScanner();



  // Just Works pairing: bonding ON, MITM OFF, secure-connection OFF,

  // IO capability NoInputNoOutput. No PIN / user numeric comparison

  // is generated by this peripheral. (Windows may still show its own

  // consent for keyboard-class devices; that is host-side behavior.)

  BLESecurity::setAuthenticationMode(true, false, false);

  BLESecurity::setCapability(ESP_IO_CAP_NONE);



  if (!g_hidBuilt) {

    g_hidServer = BLEDevice::createServer();

    g_hidServer->setCallbacks(&g_hidServerCallbacks);



    g_hid = new BLEHIDDevice(g_hidServer);



    // Generic-looking identity: no vendor-specific driver required.

    // Device name is set by BLEDevice::init(); BLEHIDDevice has no deviceName() API.

    g_hid->manufacturer("Generic HID");



    // PnP: generic USB-IF vendor, arbitrary product, so Windows loads the

    // in-box HID class driver. Change these if you want a different identity.

    g_hid->pnp(0x02, 0x045E, 0x02E0, 0x0100);



    g_hid->hidInfo(0x00, 0x01);



    // Report map = composite keyboard + mouse with report IDs 1 and 2.

    g_hid->reportMap(const_cast<uint8_t*>(HID_REPORT_MAP), sizeof(HID_REPORT_MAP));



    // Boot-protocol support lets the device appear even more generic.

    g_keyboardInput = g_hid->inputReport(1);  // keyboard report ID

    g_mouseInput = g_hid->inputReport(2);     // mouse report ID



    g_hid->startServices();



    g_hidBuilt = true;

  }



  BLEAdvertising* adv = g_hidServer->getAdvertising();



  adv->addServiceUUID(g_hid->hidService()->getUUID());

  adv->setAppearance(0x03C1);  // HID Keyboard appearance

  adv->setScanResponse(true);

  adv->setMinPreferred(0x06);  // helps Windows enumerate parameters

  adv->setMaxPreferred(0x12);



  adv->start();



  g_hidMode = true;



  Serial.println();

  Serial.println("[HID] Mode STARTED. Advertising as BLE keyboard + mouse.");

  Serial.println("[HID] Pairing: Just Works (no PIN). Bonding enabled.");

  Serial.println("[HID] The scanner is paused. Use 1-4 to resume scanning,");

  Serial.println("[HID] or B to stop HID mode.");

  Serial.println("[HID] After the target pairs and connects, press t to");

  Serial.println("[HID] send a benign test injection (Shift + mouse jiggle).");

}



static void stopHidMode() {

  if (!g_hidMode) {

    Serial.println("HID mode not active.");

    return;

  }



  if (g_hidServer != nullptr && g_hidServer->getAdvertising() != nullptr) {

    g_hidServer->getAdvertising()->stop();

  }



  g_hidMode = false;

  g_hidConnected = false;



  Serial.println();

  Serial.println("[HID] Mode STOPPED. HID advertising halted.");

  Serial.println("[HID] The scanner remains paused; use 1-4 to scan again.");

}



// Send a benign test injection once paired: a single Shift press/release and

// a small mouse jiggle. Nothing is typed and no clicks are sent. The point is

// to generate HID input events on the target for detection testing.

static void sendHidTestInjection() {

  if (!g_hidMode || !g_hidConnected || g_keyboardInput == nullptr) {

    Serial.println("[HID] Not connected. Test injection skipped.");

    return;

  }



  // Keyboard report: [report ID][modifiers][reserved][keys 0..5]

  uint8_t keyReport[8] = { 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };



  keyReport[1] = 0x02;  // LeftShift

  g_keyboardInput->setValue(keyReport, sizeof(keyReport));

  g_keyboardInput->notify();

  delay(40);



  keyReport[1] = 0x00;  // release

  g_keyboardInput->setValue(keyReport, sizeof(keyReport));

  g_keyboardInput->notify();



  // Mouse report: [report ID][buttons][dx][dy][wheel]

  const int8_t jiggles[4][2] = {

    { 10,   0 },

    {  0,  10 },

    { -10,   0 },

    {   0, -10 },

  };



  for (const auto& j : jiggles) {

    uint8_t mouseReport[5] = {

      0x02,          // report ID 2

      0x00,          // no buttons

      (uint8_t)j[0], // dx

      (uint8_t)j[1], // dy

      0x00           // wheel

    };



    g_mouseInput->setValue(mouseReport, sizeof(mouseReport));

    g_mouseInput->notify();

    delay(40);

  }



  Serial.println("[HID] Test injection sent (Shift press/release + mouse jiggle).");

  Serial.println("[HID] Check Defender/Sysmon on the target now.");

}



// ============================================================================

// Scanner control

// ============================================================================



static bool startScanSlice() {

  if (g_paused) return false;



  // IMPORTANT:

  // wantDuplicates=true keeps repeat reports.

  // shouldParse=false makes Arduino replace each ADV payload and append only its

  // matching Scan Response instead of repeatedly appending duplicate payloads.

  g_scan->setAdvertisedDeviceCallbacks(&g_callbacks, g_keepDuplicates, false);



  g_scan->setActiveScan(g_activeScan);

  g_scan->setInterval(SCAN_INTERVAL_MS);

  g_scan->setWindow(SCAN_WINDOW_MS);



  // Explicit NimBLE duplicate-filter control.

  g_scan->setDuplicateFilter(!g_keepDuplicates);



  g_scanSliceEnded = false;



  const bool ok = g_scan->start(SCAN_SLICE_SECONDS, scanComplete, false);



  if (ok) {

    ++g_scanSlices;

  } else {

    ++g_scanStartFailures;

  }



  return ok;

}



static void stopScanner() {

  g_paused = true;



  if (g_scan->isScanning()) {

    g_scan->stop();

  }



  // stop() may invoke scanComplete(), so discard that restart request.

  g_scanSliceEnded = false;

}



static void resumeScanner() {

  if (g_scan->isScanning()) return;



  // Leaving HID mode first keeps one radio role active at a time.

  if (g_hidMode) {

    stopHidMode();

  }



  g_paused = false;

  g_scan->clearResults();



  startScanSlice();

}



static void restartScanner() {

  const bool wasPaused = g_paused;



  if (g_scan->isScanning()) {

    g_scan->stop();

  }



  g_scanSliceEnded = false;



  g_scan->clearResults();



  if (!wasPaused) {

    g_paused = false;

    startScanSlice();

  }

}



// ============================================================================

// Summary

// ============================================================================



static void printSummary() {

  const uint32_t now = millis();

  size_t tracked = 0;



  Serial.println();

  Serial.println("================ NIMBLE RESEARCH SUMMARY ================");



  Serial.printf("stack=%s scanning=%s active=%s duplicates=%s slices=%lu hid_mode=%s\n",

                BLEDevice::getBLEStackString().c_str(),

                g_scan->isScanning() ? "yes" : "no",

                g_activeScan ? "yes" : "no",

                g_keepDuplicates ? "kept" : "filtered",

                (unsigned long)g_scanSlices,

                g_hidMode ? (g_hidConnected ? "connected" : "advertising") : "off");



  Serial.printf(

      "reports=%llu queue_drops=%lu stats_drops=%lu scan_start_failures=%lu\n",

      (unsigned long long)g_totalReports,

      (unsigned long)g_queueDrops,

      (unsigned long)g_statsDrops,

      (unsigned long)g_scanStartFailures);



  Serial.printf("heap_free=%u heap_min=%u psram_total=%u psram_free=%u\n",

                (unsigned)ESP.getFreeHeap(),

                (unsigned)ESP.getMinFreeHeap(),

                (unsigned)ESP.getPsramSize(),

                (unsigned)ESP.getFreePsram());



  for (size_t i = 0; i < MAX_TRACKED; ++i) {

    const DeviceStats& s = g_stats[i];



    if (!s.used) continue;



    ++tracked;



    double rssiSd = 0.0;



    if (s.rssiSamples > 1) {

      rssiSd = sqrt(s.m2Rssi / (double)(s.rssiSamples - 1));

    }



    Serial.print("addr=");

    printAddress(s.addrNative);



    Serial.printf(

        " type=%s/%s reports=%llu changes=%lu conn=%s scan=%s",

        addrTypeName(s.addrType),

        randomAddrSubtype(s.addrNative, s.addrType),

        (unsigned long long)s.reports,

        (unsigned long)s.payloadChanges,

        s.connectable ? "yes" : "no",

        s.scannable ? "yes" : "no");



    Serial.printf(" rssi[min/mean/max/sd]=%d/%.1f/%d/%.1f",

                  (int)s.minRssi,

                  s.meanRssi,

                  (int)s.maxRssi,

                  rssiSd);



    if (s.intervalSamples > 0) {

      Serial.printf(" cadence[min/mean/max]=%lu/%.1f/%lu_ms",

                    (unsigned long)s.minIntervalMs,

                    s.meanIntervalMs,

                    (unsigned long)s.maxIntervalMs);

    }



    Serial.printf(

        " evt[adv=%lu dir=%lu scan=%lu nonconn=%lu rsp=%lu other=%lu]",

        (unsigned long)s.advIndCount,

        (unsigned long)s.advDirectCount,

        (unsigned long)s.advScanCount,

        (unsigned long)s.advNonConnCount,

        (unsigned long)s.scanRspCount,

        (unsigned long)s.otherAdvCount);



    if (s.hasCompany) {

      Serial.printf(" company=0x%04X", s.companyId);



      if (const char* company = companyName(s.companyId)) {

        Serial.print("(");

        Serial.print(company);

        Serial.print(")");

      }

    }



    if (s.hasName) {

      Serial.print(" name="");

      Serial.print(s.name);

      Serial.print(""");

    }



    if (s.hasTxPower) {

      Serial.printf(" tx=%d_dBm", (int)s.txPower);

    }



    Serial.printf(" age=%lu_ms fp=%08lX\n",

                  (unsigned long)(now - s.lastSeenMs),

                  (unsigned long)s.lastFingerprint);

  }



  Serial.printf(

      "tracked=%u/%u rssi_print_floor=%d verbose=%s raw=%s decode=%s\n",

      (unsigned)tracked,

      (unsigned)MAX_TRACKED,

      (int)g_printRssiFloor,

      g_verbosePackets ? "on" : "off",

      g_printRaw ? "on" : "off",

      g_decodeAD ? "on" : "off");



  Serial.println("=========================================================");

}



// ============================================================================

// Commands

// ============================================================================



static void clearResearchStats() {

  memset(g_stats, 0, sizeof(g_stats));



  g_totalReports = 0;

  g_statsDrops = 0;



  portENTER_CRITICAL(&g_queueMux);

  g_queueHead = 0;

  g_queueTail = 0;

  g_queueDrops = 0;

  portEXIT_CRITICAL(&g_queueMux);





  Serial.println("Research statistics and packet queue cleared.");

}



static void printHelp() {

  Serial.println();

  Serial.println("ESP32-S3 NimBLE Scanner");

  Serial.println("-----------------------");

  Serial.println("1 : start ACTIVE scan, quiet");

  Serial.println("2 : start PASSIVE scan, quiet");

  Serial.println("3 : start ACTIVE scan, verbose decoded packets");

  Serial.println("4 : start PASSIVE scan, verbose decoded packets");

  Serial.println("p : pause/resume");

  Serial.println("s : print summary now");

  Serial.println("i : print board / BLE stack information");

  Serial.println("m : toggle automatic 15 s summaries");

  Serial.println("v : toggle per-packet output");

  Serial.println("r : toggle raw hex");

  Serial.println("d : toggle AD decoding");

  Serial.println("u : toggle duplicate reports and restart");

  Serial.println("k : recycle scan/results");

  Serial.println("x : clear research statistics");

  Serial.println("+/- : adjust printed RSSI floor by 5 dB");

  Serial.println("b : BLE HID MODE - advertise as keyboard+mouse (Just Works pairing)");

  Serial.println("B : stop BLE HID mode");

  Serial.println("t : HID test injection (Shift + mouse jiggle, when connected)");

  Serial.println("h or ? : show this menu");

  Serial.println();

}



static void startPreset(bool active, bool verbose) {

  // Leaving HID mode first keeps one radio role active at a time.

  if (g_hidMode) {

    stopHidMode();

  }



  g_activeScan = active;

  g_verbosePackets = verbose;

  g_printRaw = false;

  g_decodeAD = true;



  if (g_scan->isScanning()) {

    g_scan->stop();

  }



  g_scanSliceEnded = false;

  g_scan->clearResults();



  g_paused = false;



  Serial.printf("Starting %s scan (%s output)...\n",

                g_activeScan ? "ACTIVE" : "PASSIVE",

                g_verbosePackets ? "verbose" : "quiet");



  if (!startScanSlice()) {

    Serial.println("ERROR: scan failed to start.");

  }

}



static void printSystemInfo() {

  Serial.println();

  Serial.println("SYSTEM INFO");

  Serial.printf("BLE stack: %s\n", BLEDevice::getBLEStackString().c_str());

  Serial.printf("CPU: %u MHz\n", (unsigned)getCpuFrequencyMhz());

  Serial.printf("Flash: %u bytes\n", (unsigned)ESP.getFlashChipSize());

  Serial.printf("Free heap: %u bytes\n", (unsigned)ESP.getFreeHeap());

  Serial.printf("PSRAM: %u bytes\n", (unsigned)ESP.getPsramSize());

#if defined(CONFIG_BT_NIMBLE_50_FEATURE_SUPPORT)

  Serial.println("NimBLE BLE5 feature support: yes");

#else

  Serial.println("NimBLE BLE5 feature support: not exposed by this build");

#endif

#if defined(CONFIG_BT_NIMBLE_EXT_SCAN)

  Serial.println("Low-level NimBLE EXT_SCAN: enabled");

#else

  Serial.println("Low-level NimBLE EXT_SCAN: not enabled");

#endif

  Serial.printf("HID mode: %s\n", g_hidMode ? "active" : "off");

  Serial.println();

}



static void handleCommand(char c) {

  switch (c) {

    case 'h':

    case 'H':

    case '?':

      printHelp();

      break;



    case '1':

      startPreset(true, false);

      break;



    case '2':

      startPreset(false, false);

      break;



    case '3':

      startPreset(true, true);

      break;



    case '4':

      startPreset(false, true);

      break;



    case 's':

    case 'S':

      printSummary();

      break;



    case 'i':

    case 'I':

      printSystemInfo();

      break;



    case 'm':

    case 'M':

      g_autoSummary = !g_autoSummary;

      Serial.printf("automatic summaries=%s\n", g_autoSummary ? "on" : "off");

      break;



    case 'v':

    case 'V':

      g_verbosePackets = !g_verbosePackets;

      Serial.printf("verbose=%s\n", g_verbosePackets ? "on" : "off");

      break;



    case 'r':

    case 'R':

      g_printRaw = !g_printRaw;

      Serial.printf("raw=%s\n", g_printRaw ? "on" : "off");

      break;



    case 'd':

    case 'D':

      g_decodeAD = !g_decodeAD;

      Serial.printf("decode=%s\n", g_decodeAD ? "on" : "off");

      break;



    case 'a':

    case 'A':

      g_activeScan = !g_activeScan;

      Serial.printf("activeScan=%s; restarting scanner...\n",

                    g_activeScan ? "on" : "off");

      restartScanner();

      break;



    case 'u':

    case 'U':

      g_keepDuplicates = !g_keepDuplicates;

      Serial.printf("duplicates=%s; restarting scanner...\n",

                    g_keepDuplicates ? "kept" : "filtered");

      restartScanner();

      break;



    case 'k':

    case 'K':

      Serial.println("Recycling scan/results...");

      restartScanner();

      break;



    case 'b':

      startHidMode();

      break;



    case 'B':

      stopHidMode();

      break;



    case 't':

    case 'T':

      sendHidTestInjection();

      break;



    case 'p':

    case 'P':

      if (g_paused || !g_scan->isScanning()) {

        Serial.println("Resuming scanner...");

        resumeScanner();

      } else {

        Serial.println("Pausing scanner...");

        stopScanner();

      }

      break;



    case 'x':

    case 'X':

      clearResearchStats();

      break;



    case '+':

      if (g_printRssiFloor < -5) {

        g_printRssiFloor += 5;

      }

      Serial.printf("print RSSI floor=%d dBm\n", (int)g_printRssiFloor);

      break;



    case '-':

      if (g_printRssiFloor > -127) {

        g_printRssiFloor -= 5;

        if (g_printRssiFloor < -127) g_printRssiFloor = -127;

      }

      Serial.printf("print RSSI floor=%d dBm\n", (int)g_printRssiFloor);

      break;



    case '\r':

    case '\n':

    case ' ':

    case '\t':

      break;



    default:

      Serial.printf("Unknown command '%c'. Press h for help.\n", c);

      break;

  }

}



// ============================================================================

// Arduino setup / loop

// ============================================================================



void setup() {

  Serial.begin(SERIAL_BAUD);

  delay(500);



  BLEDevice::init("S3-NimBLE-Research");



  memset(g_stats, 0, sizeof(g_stats));

  g_scan = BLEDevice::getScan();



  // Intentionally idle and quiet at boot.

  g_paused = true;

  g_verbosePackets = false;

  g_printRaw = false;

  g_autoSummary = false;

  g_lastSummaryMs = millis();



  Serial.println("READY. h=help");

}



void loop() {

  PacketSnapshot packet;



  // Keep parsing and serial formatting outside the NimBLE host callback.

  while (dequeuePacket(packet)) {

    processPacket(packet);

    delay(0);

  }



  while (Serial.available() > 0) {

    handleCommand((char)Serial.read());

  }



  // Immediately restart each finite scan slice.

  if (g_scanSliceEnded) {

    g_scanSliceEnded = false;



    if (!g_paused) {

      // start(..., false) clears Arduino's accumulated BLEScanResults first.

      if (!startScanSlice()) {

        Serial.println("WARNING: scan slice restart failed; retrying shortly.");

        delay(250);

      }

    }

  }



  const uint32_t now = millis();



  if (g_autoSummary &&

      g_scan->isScanning() &&

      (uint32_t)(now - g_lastSummaryMs) >= SUMMARY_INTERVAL_MS) {

    g_lastSummaryMs = now;

    printSummary();

  }



  delay(1);

}