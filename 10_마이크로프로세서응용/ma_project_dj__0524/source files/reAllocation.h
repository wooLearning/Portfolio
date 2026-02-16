#ifndef __CONVERT_GRAY_H__
#define __CONVERT_GRAY_H__

#include <stdint.h>

void reAllocation(uint8_t* origin, uint8_t* targetR, uint8_t* targetG, uint8_t* targetB, int size);

void convertGrayRel(uint16_t* toSave, uint8_t* targetR, uint8_t* targetG, uint8_t* targetB, int size);

void convertReverseRel(uint8_t* toSave, uint8_t* origin, int size);

int countRedRel(uint8_t* origin, int size);

#endif
