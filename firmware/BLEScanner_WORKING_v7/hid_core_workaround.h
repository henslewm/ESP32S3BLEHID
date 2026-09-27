// Workaround for Arduino-ESP32 3.3.12 (NimBLE) dropping duplicate-UUID characteristics.
//
// BLEService::addCharacteristic (BLEService.cpp:260-274) looks the new
// characteristic up by UUID and, under NimBLE, keeps only the existing one.
// Every HID input report shares UUID 0x2A4D, so BLEHIDDevice::inputReport()
// for a second report ID returns an object that never enters the GATT table
// (its handle stays 0xFFFF and the host cannot subscribe to it).
#pragma once

#include "config.h"

// Creates an input report characteristic identical to BLEHIDDevice::inputReport()
// (UUID 0x2A4D, READ|NOTIFY, Report Reference 0x2908 = {reportId, 0x01}) and
// registers it with the HID service even when another 0x2A4D already exists.
// Must be called before BLEHIDDevice::startServices().
BLECharacteristic* hidAddInputReport(BLEHIDDevice* hid, uint8_t reportId);
