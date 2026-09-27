// BLE scan control: runtime scan options, NimBLE callbacks, finite scan slices, presets.
#pragma once

#include "config.h"

// Runtime controls (owned here; commands.cpp toggles them).
extern bool g_activeScan;
extern bool g_keepDuplicates;
extern bool g_verbosePackets;
extern bool g_printRaw;
extern bool g_decodeAD;
extern bool g_paused;
extern int8_t g_printRssiFloor;
extern bool g_autoSummary;

extern BLEScan* g_scan;
extern volatile bool g_scanSliceEnded;
extern uint32_t g_scanSlices;
extern uint32_t g_scanStartFailures;

bool startScanSlice();
void stopScanner();
void resumeScanner();
void restartScanner();
void startPreset(bool active, bool verbose);
