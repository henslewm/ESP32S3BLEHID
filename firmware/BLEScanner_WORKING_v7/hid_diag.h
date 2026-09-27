// Observation-only HID diagnostics: build identity, GATT handles and raw NimBLE
// GAP events (connect, encryption, every CCCD subscribe). Never sends HID input.
#pragma once

#include "config.h"

// Build identity printed by 'i' and at HID start. The authoritative artifact identity is
// elf_sha256: the SHA-256 of the exact ELF, embedded in the app image by elf2image
// (--elf-sha256-offset) and read back at runtime, so it reflects every build input
// (sources, flags, core, scripts). Evidence binds to it; compare with the recorded ELF hash.
// FIRMWARE_BUILD_ID is an optional free-text label (-DFIRMWARE_BUILD_ID="..."), not identity.
#ifndef FIRMWARE_BUILD_ID
#define FIRMWARE_BUILD_ID "unlabeled"
#endif

void printBuildIdentity();

// Call once after HID advertising has started (GATT handles are assigned by then).
// Logs report handles and registers a NimBLE GAP listener that prints every
// subscribe event, including handles the Arduino wrapper does not recognise.
void hidDiagBegin(uint16_t keyboardValueHandle, uint16_t mouseValueHandle);
