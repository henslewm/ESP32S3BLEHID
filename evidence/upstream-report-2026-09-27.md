# Upstream report: espressif/arduino-esp32#12951 (ESP-012)

Filed 2026-09-27 at https://github.com/espressif/arduino-esp32/issues/12951 (read back: open, 4,965-character body). Before filing, upstream master was checked and still had the identical code; four duplicate searches found nothing. The debug capture came from the minimal sketch below, flashed on this board at CORE_DEBUG_LEVEL=4; the board was then reflashed with main (elf_sha256 52e09739…). Posted text follows, verbatim.

---

### Board

ESP32-S3 Dev Module (ESP32-S3 QFN56 rev v0.2, 16 MB flash, 8 MB octal PSRAM)

### Device Description

Generic ESP32-S3 devkit (N16R8 module), USB CDC on boot.

### Hardware Configuration

Nothing attached.

### Version

v3.3.12. The same code is on latest master (`libraries/BLE/src/BLEService.cpp`, `addCharacteristic()`, lines 252-282).

### Type

Bug

### IDE Name

PlatformIO (pioarduino platform 55.03.312-1 = Arduino-ESP32 3.3.12); also seen with arduino-cli, FQBN esp32:esp32:esp32s3

### Operating System

Windows 11

### Flash frequency

80 MHz

### PSRAM enabled

yes

### Upload speed

921600

### Description

With the built-in NimBLE backend (`CONFIG_NIMBLE_ENABLED`), `BLEService::addCharacteristic()` does not register a second characteristic that has the same UUID as an existing one. It looks the new characteristic up by UUID. If one already exists, it only clears the existing object's `m_removed` flag and never inserts the new object into `m_characteristicMap`:

```cpp
// libraries/BLE/src/BLEService.cpp (3.3.12 and master)
BLECharacteristic *pExisting = m_characteristicMap.getByUUID(pCharacteristic->getUUID());
if (pExisting != nullptr) {
  log_w("<< Adding a new characteristic with the same UUID as a previous one");
}
#if defined(CONFIG_NIMBLE_ENABLED)
  if (pExisting != nullptr) {
    pExisting->m_removed = 0;
  } else
#endif
  {
    m_characteristicMap.setByUUID(pCharacteristic, pCharacteristic->getUUID());
  }
```

`BLEService::start()` builds the NimBLE GATT table from that map, so the second characteristic never exists on air. Its handle stays 0xFFFF, and no error is returned; the only trace is the `log_w` at debug level.

This breaks every HID device with more than one input report. All HID Report characteristics share UUID 0x2A4D and are told apart by their 0x2908 Report Reference descriptor. `BLEHIDDevice::inputReport(2)` returns a valid-looking `BLECharacteristic*` that is silently absent from GATT, so a composite keyboard + mouse exposes only the first report. In our case a Windows 11 host subscribed to the keyboard report and never to the mouse report. The same applies to any second `outputReport()` / `featureReport()`.

**Expected:** both 0x2A4D characteristics are registered. Per the source, the Bluedroid path of this same function inserts unconditionally. h2zero/NimBLE-Arduino's `NimBLEService::addCharacteristic` compares by object identity, not UUID, and appends.

**Actual:** `inputReport(1)` gets a handle; `inputReport(2)` stays at 65535 (capture below).

**Suggested fix direction:** under NimBLE, treat a characteristic as "already added" only if the same object pointer is already in the map. `m_uuidMap` is keyed by `BLECharacteristic*`, so duplicates are representable. Restore `m_removed = 0` only for that exact object, and otherwise insert the new object. The UUID collision can stay a warning, as it is under Bluedroid.

### Sketch

```cpp
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEHIDDevice.h>

BLEHIDDevice* hid;
BLECharacteristic* report1;
BLECharacteristic* report2;

void setup() {
  Serial.begin(115200);
  delay(3000);
  BLEDevice::init("DupUuidTest");
  BLEServer* server = BLEDevice::createServer();
  hid = new BLEHIDDevice(server);
  report1 = hid->inputReport(1);   // 0x2A4D, Report Reference {1, input}
  report2 = hid->inputReport(2);   // 0x2A4D, Report Reference {2, input}
  hid->startServices();
  BLEDevice::getAdvertising()->addServiceUUID(hid->hidService()->getUUID());
  BLEDevice::getAdvertising()->start();
  Serial.printf("inputReport(1) handle=%u\n", report1->getHandle());
  Serial.printf("inputReport(2) handle=%u\n", report2->getHandle());
}

void loop() {}
```

### Debug Message

Captured from the sketch above on 3.3.12 (`-DCORE_DEBUG_LEVEL=4`, ESP32-S3):

```plain
[D][BLEService.cpp:258] addCharacteristic(): Adding characteristic: uuid=00002a4d-0000-1000-8000-00805f9b34fb to service: UUID: 00001812-0000-1000-8000-00805f9b34fb, handle: 0xffff
[D][BLEService.cpp:258] addCharacteristic(): Adding characteristic: uuid=00002a4d-0000-1000-8000-00805f9b34fb to service: UUID: 00001812-0000-1000-8000-00805f9b34fb, handle: 0xffff
[W][BLEService.cpp:263] addCharacteristic(): << Adding a new characteristic with the same UUID as a previous one
inputReport(1) handle=27
inputReport(2) handle=65535
```

### Other Steps to Reproduce

Workaround (not a fix): create the second 0x2A4D characteristic and its 0x2908 descriptor manually, then insert it into the service's private `m_characteristicMap` before `startServices()` through the explicit-instantiation member-access idiom. This restores the second report, and Windows then subscribes to both reports. It depends on private core internals, so it is not a real solution.

### I have checked existing issues, online documentation and the Troubleshooting Guide

- [x] I confirm I have checked existing issues, online documentation and Troubleshooting guide.
