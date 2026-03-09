// #include <stdint.h>
// #include <stdlib.h>

// #include "find_IDAT.h"
// #include "convertGray.h"
// #include "isSame.h"

// extern	void _sys_exit(int return_code);
// extern  int countRedAsm(uint8_t* origin, int size);
// extern  void convertGrayAsm(uint8_t* origin, uint16_t* toSave, int size);
// extern  void convertReverseAsm(uint8_t* origin, uint8_t* toSave, int size);

// int main(void) {
//     const int PIXEL_COUNT = 9600;

//     uint8_t* pixel_start = find_IDAT( (uint8_t*)0x40000000 ) + 4;
    
//     int* count = (int*)0x30010000;
    
//     uint16_t* grayTarget = (uint16_t*)0x30020000;   // ~0x30024B00
//     uint16_t* grayTarget2 = (uint16_t*)0x30030000;   // ~0x30024B00
    
//     uint8_t* reverseTarget = (uint8_t*)0x30040000;
//     uint8_t* reverseTarget2 = (uint8_t*)0x30050000;

//     uint8_t* isSameReturn = (uint8_t*)(count + 2);

//     convertGray(pixel_start, grayTarget, PIXEL_COUNT);
//     convertGrayAsm(pixel_start, grayTarget2, PIXEL_COUNT);
//     *isSameReturn = isSame_uint16(grayTarget, grayTarget2, PIXEL_COUNT);
    
//     convertReverse(pixel_start, reverseTarget, PIXEL_COUNT);
//     convertReverseAsm(pixel_start, reverseTarget2, PIXEL_COUNT);
//     *(isSameReturn + 4) = isSame_uint8(reverseTarget, reverseTarget2, PIXEL_COUNT*3);
    
//     *count = countRed(pixel_start, PIXEL_COUNT);
//     *(count + 1) = countRedAsm(pixel_start, PIXEL_COUNT);

//     _sys_exit(0);
// }
