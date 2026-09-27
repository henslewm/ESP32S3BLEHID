// Per-device research statistics, packet display and the summary report.
#pragma once

#include "config.h"

extern DeviceStats g_stats[MAX_TRACKED];  // owned here
extern uint64_t g_totalReports;
extern uint32_t g_statsDrops;
extern uint32_t g_lastSummaryMs;

void processPacket(const PacketSnapshot& p);
void printSummary();
void clearResearchStats();
