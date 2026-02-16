#include <stdint.h>
#include <stdbool.h>
#include "isSame.h"

bool isSame_uint8(uint8_t* a, uint8_t* b, int size) {
    for(int i=0; i<size; i++) {
        if(*a != *b) {
            return false;
        }
    }
    return true;
}
bool isSame_uint16(uint16_t* a, uint16_t* b, int size) {
    for(int i=0; i<size; i++) {
        if(*a != *b) {
            return false;
        }
    }
    return true;
}