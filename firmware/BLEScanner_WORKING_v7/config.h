// Build requirements, includes and compile-time constants shared by every module.
#pragma once

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

#include "scan_types.h"
