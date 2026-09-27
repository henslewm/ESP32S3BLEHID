// Advertising-data (AD structure) decoding: iBeacon, Eddystone, flags, identity extraction.
#pragma once

#include "config.h"

void extractIdentity(DeviceStats& s, const uint8_t* p, size_t len);
void decodeAD(const uint8_t* p, size_t len);
