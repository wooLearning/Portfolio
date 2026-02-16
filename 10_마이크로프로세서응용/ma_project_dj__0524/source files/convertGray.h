#ifndef __CONVERT_GRAY_H__
#define __CONVERT_GRAY_H__

#include <stdint.h>

void convertGray(uint8_t* origin, uint16_t* toSave, int size);

void convertReverse(uint8_t* origin, uint8_t* toSave, int size);

int countRed(uint8_t* origin, int size);

#endif
