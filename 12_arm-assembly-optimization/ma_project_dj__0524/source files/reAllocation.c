#include "reAllocation.h"
#include <stdint.h>

void reAllocation(uint8_t* origin, uint8_t* targetR, uint8_t* targetG, uint8_t* targetB, int size) {
    for (int i = 0; i < size; i++) {
        *targetR++ = *(origin++);
        *targetG++ = *(origin++);
        *targetB++ = *(origin++);
        (origin++); // Skip alpha channel
    }
}

void convertGrayRel(uint16_t* toSave, uint8_t* targetR, uint8_t* targetG, uint8_t* targetB, int size) {
    uint8_t r, g, b;
    for (int i = 0; i < size; i++) {
        // get color
        r = *(targetR++);
        g = *(targetG++);
        b = *(targetB++);
        // writeback
        *toSave++ = 3 * (uint16_t)r + 6 * (uint16_t)g + (uint16_t)b;
    }
}

void convertReverseRel(uint8_t* origin, uint8_t* toSave, int size) {
    for (int i = 0; i < size; i++) {
        *(toSave++) = 255 - *(origin++);
    }
}

int countRedRel(uint8_t* origin, int size) {
    int cnt = 0;
    for (int i = 0; i < size; i++) {
        cnt += *(origin++) > 127 ? 1 : 0;
    }
    return cnt;
}
