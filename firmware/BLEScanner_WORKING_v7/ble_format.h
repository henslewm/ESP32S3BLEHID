// Address, hex, UUID, company and advertising-type formatting helpers (pure, no state).
#pragma once

#include "config.h"

bool sameAddress(const uint8_t* a, const uint8_t* b);
void printAddress(const uint8_t* nativeAddr);
const char* addrTypeName(uint8_t t);
const char* randomAddrSubtype(const uint8_t* nativeAddr, uint8_t addrType);
void printHex(const uint8_t* data, size_t len);
uint16_t le16(const uint8_t* p);
uint32_t le32(const uint8_t* p);
uint16_t be16(const uint8_t* p);
uint32_t be32(const uint8_t* p);
uint32_t fnv1a32(const uint8_t* data, size_t len);
void printEscapedText(const uint8_t* data, size_t len);
void printUUID128(const uint8_t* d);
const char* uuid16Name(uint16_t uuid);
const char* companyName(uint16_t id);
void printUUID16List(const uint8_t* d, size_t len);
void printUUID32List(const uint8_t* d, size_t len);
const char* advTypeName(uint8_t t);
