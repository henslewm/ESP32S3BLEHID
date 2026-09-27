// Observation-only HID diagnostics: build identity, GATT handles and raw NimBLE
// GAP events (connect, encryption, every CCCD subscribe). Never sends HID input.
#pragma once

#include "config.h"

// Build identity printed by 'i' and at HID start so serial captures bind to an artifact.
#define FIRMWARE_BUILD_ID "v7-split-diag4-pio"

void printBuildIdentity();

// Call once after HID advertising has started (GATT handles are assigned by then).
// Logs report handles and registers a NimBLE GAP listener that prints every
// subscribe event, including handles the Arduino wrapper does not recognise.
void hidDiagBegin(uint16_t keyboardValueHandle, uint16_t mouseValueHandle);
