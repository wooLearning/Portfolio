#include "convertGray.h"

void convertGray(uint8_t* origin, uint16_t* toSave, int size) {
    uint8_t r, g, b;

    for (int i = 0; i < size; i++) {
        r = *(origin++);
        g = *(origin++);
        b = *(origin++);
        (origin++); // Skip alpha channel

        *toSave = 3 * (uint16_t)r + 6 * (uint16_t)g + (uint16_t)b;
        toSave++;
    }
}

void convertReverse(uint8_t* origin, uint8_t* toSave, int size) {
    for (int i = 0; i < size; i++) {
        // *(toSave++) = 0;
        *(toSave++) = 255 - *(origin++);
        *(toSave++) = 255 - *(origin++);
        *(toSave++) = 255 - *(origin++);
        (origin++);
    }
}

int countRed(uint8_t* origin, int size) {
    int cnt = 0;
    for (int i = 0; i < size; i++) {
        cnt += (*origin) >= 128 ? 1 : 0;
        origin += 4;
    }
    return cnt;
}
