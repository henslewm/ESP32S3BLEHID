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

#include "config.h"
#include "packet_queue.h"
#include "device_stats.h"
#include "scanner.h"
#include "commands.h"

// Module map: see firmware/BLEScanner_WORKING_v7/MODULES.md

// ============================================================================
// Arduino setup / loop
// ============================================================================

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(500);

  BLEDevice::init("S3-HID-KM-v7");

  memset(g_stats, 0, sizeof(g_stats));
  g_scan = BLEDevice::getScan();

  // Intentionally idle and quiet at boot.
  g_paused = true;
  g_verbosePackets = false;
  g_printRaw = false;
  g_autoSummary = false;
  g_lastSummaryMs = millis();

  Serial.println("READY HIDDIAG-v7. h=help");
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
