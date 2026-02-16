#ifndef __ILI9341_H__
#define __ILI9341_H__

#include "fonts.h"

#define ILI9341_MADCTL_MY  0x80
#define ILI9341_MADCTL_MX  0x40
#define ILI9341_MADCTL_MV  0x20
#define ILI9341_MADCTL_ML  0x10
#define ILI9341_MADCTL_RGB 0x00
#define ILI9341_MADCTL_BGR 0x08
#define ILI9341_MADCTL_MH  0x04

// default orientation
/*
#define ILI9341_WIDTH  240
#define ILI9341_HEIGHT 320
#define ILI9341_ROTATION (ILI9341_MADCTL_MX | ILI9341_MADCTL_BGR)
*/

// rotate right
#define ILI9341_WIDTH  320
#define ILI9341_HEIGHT 240
#define ILI9341_ROTATION (ILI9341_MADCTL_MX | ILI9341_MADCTL_MY | ILI9341_MADCTL_MV | ILI9341_MADCTL_BGR)

// rotate left
/*
#define ILI9341_WIDTH  320
#define ILI9341_HEIGHT 240
#define ILI9341_ROTATION (ILI9341_MADCTL_MV | ILI9341_MADCTL_BGR)
*/

// upside down
/*
#define ILI9341_WIDTH  240
#define ILI9341_HEIGHT 320
#define ILI9341_ROTATION (ILI9341_MADCTL_MY | ILI9341_MADCTL_BGR)
*/

/****************************/

// Color definitions
#define ILI9341_COLOR565(r, g, b) (((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3))

#define	ILI9341_BLACK   0x0000
#define	ILI9341_BLUE    0x001F
#define	ILI9341_RED     0xF800
#define	ILI9341_GREEN   0x07E0
#define ILI9341_CYAN    0x07FF
#define ILI9341_MAGENTA 0xF81F
#define ILI9341_YELLOW  0xFFE0
#define ILI9341_WHITE   0xFFFF

extern SPI_HandleTypeDef hspi1;

void ILI9341_Select(void);
void ILI9341_Unselect(void);
void ILI9341_Reset(void);
void ILI9341_WriteCommand(uint8_t);
void ILI9341_WriteData(uint8_t* buff, size_t);
void ILI9341_SetAddressWindow(uint16_t, uint16_t, uint16_t, uint16_t);
void ILI9341_Init(void);
void ILI9341_DrawPixel(uint16_t, uint16_t, uint16_t);
void ILI9341_WriteChar(uint16_t, uint16_t, char, FontDef, uint16_t, uint16_t);
void ILI9341_WriteString(uint16_t, uint16_t, char *, FontDef, uint16_t, uint16_t);
void ILI9341_FillRectangle(uint16_t, uint16_t, uint16_t, uint16_t, uint16_t);
void ILI9341_FillScreen(uint16_t);
void ILI9341_DrawImage(uint16_t, uint16_t, uint16_t, uint16_t, uint16_t *);
void ILI9341_InvertColors(unsigned);
void ILI9341_Test(void);
void draw_line_gradation(unsigned , uint8_t *);
void end_of_frame_gradation(void);

#endif // __ILI9341_H__
