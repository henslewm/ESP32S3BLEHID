// BLE HID peripheral: GATT/HID construction, connection+subscription tracking, mouse-only test.
#pragma once

#include "config.h"

// HID state (owned here; read-only elsewhere).
extern bool g_hidMode;
extern bool g_hidConnected;
extern volatile bool g_keyboardSubscribed;
extern volatile bool g_mouseSubscribed;

void startHidMode();
void stopHidMode();
void sendHidTestInjection();
