#ifndef __ISSAME_H__
#define __ISSAME_H__

#include <stdint.h>
#include <stdbool.h>

bool isSame_uint8(uint8_t* a, uint8_t* b, int size);
bool isSame_uint16(uint16_t* a, uint16_t* b, int size);

#endif