#include <stdint.h>
#include <stdlib.h>

#include "find_IDAT.h"
#include "convertGray.h"
#include "reAllocation.h"
#include "isSame.h"

extern	void _sys_exit(int return_code);
extern	void convertReverseRelAsm(uint8_t* origin, uint8_t* toSave, int size);
extern  int countRedRelAsm(uint8_t* origin, int size);
extern	void convertGrayRelAsm(uint16_t* toSave, uint8_t* targetR, uint8_t* targetG, uint8_t* targetB, int size);

int main(void) {
    const int PIXEL_COUNT = 9600;
    
    uint8_t* pixel_start = find_IDAT( (uint8_t*)0x40000000 ) + 4;

    uint8_t* r = (uint8_t*)0x30000000;
    uint8_t* g = r + PIXEL_COUNT;   // 0x30002580
    uint8_t* b = g + PIXEL_COUNT;   // 0x30004B00
    
    int* count = (int*)0x30010000;

    uint16_t* grayTarget = (uint16_t*)0x30020000;   // ~0x30024B00
    uint16_t* grayTarget2 = (uint16_t*)0x30030000;   // ~0x30024B00

    uint8_t* rRev = (uint8_t*)0x30040000;
    uint8_t* gRev = rRev + PIXEL_COUNT; // 0x30042580
    uint8_t* bRev = gRev + PIXEL_COUNT; // 0x30044B00

    uint8_t* rRev2 = (uint8_t*)0x30050000;
    uint8_t* gRev2 = rRev2 + PIXEL_COUNT; // 0x30052580
    uint8_t* bRev2 = gRev2 + PIXEL_COUNT; // 0x30054B00
    
    uint8_t* isSameReturn = (uint8_t*)(count + 2);

    // reallocate data
    reAllocation(pixel_start, r, g, b, PIXEL_COUNT);
    
    convertGrayRel(grayTarget, r, g, b, PIXEL_COUNT);
    convertGrayRelAsm(grayTarget2, r, g, b, PIXEL_COUNT);
    *isSameReturn = isSame_uint16(grayTarget, grayTarget2, PIXEL_COUNT);
    
    convertReverseRel(r, rRev, PIXEL_COUNT*3);
    convertReverseRelAsm(r, rRev2, PIXEL_COUNT*3);
    *(isSameReturn+4) = isSame_uint8(rRev, rRev2, PIXEL_COUNT*3);
    
    *count = countRedRel(r, PIXEL_COUNT);
    *(count + 1) = countRedRelAsm(r, PIXEL_COUNT);
    
    
    _sys_exit(0);
}


    