// ISR/callback-safe ring buffer of captured advertising packets (scanner -> loop).
#pragma once

#include "config.h"

extern volatile uint32_t g_queueDrops;  // owned here; read-only elsewhere

void clearPacketQueue();
bool enqueuePacket(const PacketSnapshot& packet);
bool dequeuePacket(PacketSnapshot& packet);
