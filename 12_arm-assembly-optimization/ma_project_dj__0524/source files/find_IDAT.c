#include "find_IDAT.h"

uint8_t* find_IDAT(uint8_t* ptr) {
    for (;;) {
        if (*ptr == 'I' && *(ptr + 1) == 'D' && *(ptr + 2) == 'A' && *(ptr + 3) == 'T')
            return ptr;
        ptr++;
    }
}
