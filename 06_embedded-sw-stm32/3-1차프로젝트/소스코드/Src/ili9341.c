
#include "main.h"
#include "ili9341.h"
#include "testimg.h"
#include "usb_device.h"
#include <stdio.h>


void ILI9341_Select() {
	// ILI9341_CS  0
	HAL_GPIO_WritePin(ILI9341_CS_GPIO_Port, ILI9341_CS_Pin, 0);
}
void ILI9341_Unselect() {
	// ILI9341_CS  1
	HAL_GPIO_WritePin(ILI9341_CS_GPIO_Port, ILI9341_CS_Pin, 1);
}
void ILI9341_Reset() {
	// ILI9341_RES  0
	HAL_GPIO_WritePin(ILI9341_RES_GPIO_Port, ILI9341_RES_Pin, 0);
	// 5ms delay
	HAL_Delay(5);
	// ILI9341_RES  1
	HAL_GPIO_WritePin(ILI9341_RES_GPIO_Port, ILI9341_RES_Pin, 1);
	// 5ms delay
	HAL_Delay(5);
}
void ILI9341_WriteCommand(uint8_t cmd) {
// ILI9341_DC  0
  HAL_GPIO_WritePin(ILI9341_DC_GPIO_Port, ILI9341_DC_Pin, 0);
 // use hspi1 1byte cmd
  HAL_SPI_Transmit(&hspi1, &cmd, sizeof(cmd),10);
}
void ILI9341_WriteData(uint8_t * buff, size_t buff_size) {
	// ILI9341_DC  1
	HAL_GPIO_WritePin(ILI9341_DC_GPIO_Port, ILI9341_DC_Pin, 1);
	// HAL SPI can 65535 byte max so cut the data

	while (buff_size > 0) {
		// if buff_size bigger than 65535 chunk_size=65535, else chunk_sizebuff_size
		uint16_t chunk_size;
		if(buff_size >= 65535){
			chunk_size = 65535;
		}else{
			chunk_size = buff_size;
		}
		// spi1으로 chunk_size의 buff[]를 보냄.
		HAL_SPI_Transmit(&hspi1, buff, chunk_size,100);
		buff += chunk_size;
		buff_size -= chunk_size;
	}
}

void ILI9341_Init() {
	uint8_t init_buf;
	ILI9341_Reset();
	ILI9341_Select();

	// COLMOD (MCU 16 bits per pixel)
	ILI9341_WriteCommand(0x3A);
	init_buf = 0x55;
	ILI9341_WriteData(&init_buf,sizeof(init_buf));//0101_0101

	// Memory Access Control (Any rotation, BGR=1)
	ILI9341_WriteCommand(0x36);
	init_buf = ILI9341_ROTATION;
	ILI9341_WriteData(&init_buf,sizeof(init_buf));
	ILI9341_WriteCommand(0xE0);
	{ uint8_t data[] = { 0x0F, 0x31, 0x2B, 0x0C, 0x0E, 0x08, 0x4E, 0xF1,
	0x37, 0x07, 0x10, 0x03, 0x0E, 0x09, 0x00 };
	ILI9341_WriteData(data, sizeof(data));
	}
	// NEGATIVE GAMMA CORRECTION
	ILI9341_WriteCommand(0xE1);
	{
	uint8_t data[] = { 0x00, 0x0E, 0x14, 0x03, 0x11, 0x07, 0x31, 0xC1,
	0x48, 0x08, 0x0F, 0x0C, 0x31, 0x36, 0x0F };
	ILI9341_WriteData(data, sizeof(data));
	}

	// Sleep Out
	ILI9341_WriteCommand(0x11);// 60 ms delay
	HAL_Delay(60);
	// Display ON
	ILI9341_WriteCommand(0x29);
	ILI9341_Unselect();
}
void ILI9341_DrawPixel(uint16_t x, uint16_t y, uint16_t color) {
	uint8_t data[2];
	if ((x >= ILI9341_WIDTH) || (y >= ILI9341_HEIGHT)) return;
	ILI9341_Select();
	ILI9341_SetAddressWindow(x, y, x, y);
	data[0] = color>>8; // color's upper 8 bits
	data[1] = color; // color's lower 8 bits
	ILI9341_WriteData(data, sizeof(data));
	ILI9341_Unselect();
}

void ILI9341_SetAddressWindow(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1) {
	// Column Address Set (command and data transmit)
	uint8_t buf[4];
	buf[0] = x0>>8;//upper
	buf[1] = x0;//lower
	buf[2] = x1>>8;
    buf[3] = x1;
    ILI9341_WriteCommand(0x2A);
	ILI9341_WriteData(buf,sizeof(buf));
	// Row Address Set (command and data transmit)
	buf[0] = y0>>8;
	buf[1] = y0;
	buf[2] = y1>>8;
	buf[3] = y1;
	ILI9341_WriteCommand(0x2B);
	ILI9341_WriteData(buf,sizeof(buf));
	// Memory Write (transmit only comand)
	ILI9341_WriteCommand(0x2C);
}

void ILI9341_FillRectangle(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color) {
	static uint8_t buf[ILI9341_WIDTH*2];
	if ((x >= ILI9341_WIDTH) || (y >= ILI9341_HEIGHT)) return;
	if ((x+w-1) >= ILI9341_WIDTH) w = ILI9341_WIDTH-x;
	if ((y+h-1) >= ILI9341_HEIGHT) h = ILI9341_HEIGHT-y;
	ILI9341_Select();
	ILI9341_SetAddressWindow(x, y, x+w-1, y+h-1);
	// buf[]<= color
	for(unsigned i =0; i<ILI9341_WIDTH*2; i = i + 2){
		buf[i] = color>>8;
		buf[i+1] = color;
	}
	// using ILI9341_WriteData() to transmit buf
	ILI9341_WriteData(buf,sizeof(buf));
	ILI9341_Unselect();
}
void ILI9341_FillScreen(uint16_t color) {
	ILI9341_FillRectangle(0, 0, ILI9341_WIDTH, ILI9341_HEIGHT, color);
}
void ILI9341_DrawImage(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t * image) {
	if ((x >= ILI9341_WIDTH) || (y >= ILI9341_HEIGHT)) return;
	if ((x+w-1) >= ILI9341_WIDTH) return;
	if ((y+h-1) >= ILI9341_HEIGHT) return;
	ILI9341_Select();
	ILI9341_SetAddressWindow(x, y, x+w-1, y+h-1);
	// image data transmit for one time
	uint8_t* image_buf = (uint8_t *)image;//endian check need
	/*
	uint16_t num = 0;
	while(*image_buf != 0){
		image_buf++;
		num++;
	}
	image_buf = (uint8_t *)image;
	*/
	ILI9341_WriteData(image_buf,w*h*2);//size w*h
	ILI9341_Unselect();
}
void ILI9341_InvertColors(unsigned invert) {
	ILI9341_Select();
	// for invert value
	uint8_t temp = (invert==1) ? 0x21 : 0x20;// on,off
	ILI9341_WriteCommand(temp);
	ILI9341_Unselect();
}

void ILI9341_WriteChar(uint16_t x, uint16_t y, char ch, FontDef font, uint16_t color, uint16_t bgcolor) {
    uint32_t i, b, j;

    ILI9341_SetAddressWindow(x, y, x+font.width-1, y+font.height-1);

    for(i = 0; i < font.height; i++) {
        b = font.data[(ch - 32) * font.height + i];
        for(j = 0; j < font.width; j++) {
            if((b << j) & 0x8000)  {
                uint8_t data[] = { color >> 8, color & 0xFF };
                ILI9341_WriteData(data, sizeof(data));
            } else {
                uint8_t data[] = { bgcolor >> 8, bgcolor & 0xFF };
                ILI9341_WriteData(data, sizeof(data));
            }
        }
    }
}

void ILI9341_WriteString(uint16_t x, uint16_t y, char* str, FontDef font, uint16_t color, uint16_t bgcolor) {
    ILI9341_Select();

    while(*str) {
        if(x + font.width >= ILI9341_WIDTH) {
            x = 0;
            y += font.height;
            if(y + font.height >= ILI9341_HEIGHT) {
                break;
            }

            if(*str == ' ') {
                // skip spaces in the beginning of the new line
                str++;
                continue;
            }
        }

        ILI9341_WriteChar(x, y, *str, font, color, bgcolor);
        x += font.width;
        str++;
    }

    ILI9341_Unselect();
}

void ILI9341_Test(void) {
  // Clear Screen
  ILI9341_FillScreen(ILI9341_BLACK);

  // Draw Borders
  ILI9341_FillRectangle(0, 0, ILI9341_WIDTH, 1, ILI9341_RED);
  ILI9341_FillRectangle(0, ILI9341_HEIGHT-1, ILI9341_WIDTH, 1, ILI9341_RED);

  for (unsigned y = 0; y<ILI9341_HEIGHT; y++) {
    ILI9341_DrawPixel(0, y, ILI9341_RED);
    ILI9341_DrawPixel(ILI9341_WIDTH-1, y, ILI9341_RED);
  }
  HAL_Delay(1000);

  // Draw fonts
  ILI9341_FillScreen(ILI9341_BLACK);
  ILI9341_WriteString(0, 0, "Font_7x10, Red, Test String 0123456789", Font_7x10, ILI9341_RED, ILI9341_BLACK);
  ILI9341_WriteString(0, 3*10, "Font_11x18, Green, Test String 0123456789", Font_11x18, ILI9341_GREEN, ILI9341_BLACK);
  ILI9341_WriteString(0, 3*10+3*18, "Font_16x26, Blue, Test String 0123456789", Font_16x26, ILI9341_BLUE, ILI9341_BLACK);
  HAL_Delay(1000);

  // Invert Colors
  ILI9341_InvertColors(1);
  HAL_Delay(1000);

  // Normal Colors
  ILI9341_InvertColors(0);
  HAL_Delay(1000);

  // Draw Bitmap
  ILI9341_DrawImage((ILI9341_WIDTH - 240) / 2, (ILI9341_HEIGHT - 240) / 2, 240, 240, (uint16_t *)test_img_240x240);
  HAL_Delay(1000);
}

unsigned start_intensity=0; // 첫 line의 밝기
unsigned intensity_change=1; // Frame 마다 start_intensity를 +1 또는 -1
void draw_line_gradation(unsigned line_num, uint8_t * line_buf) {
	// line_num이 처음 또는 마지막 줄이면 White border로 채우고 return.
	if(line_num == 0 || (line_num == (240-1))){//32 is last line num
		for(unsigned i = 0; i <ILI9341_WIDTH*2;i++){
			line_buf[i] = 0xff;
		}
		return;
	}
	// 칠해야 할 색상이 R, G, B 중 어떤 색인지 계산.
	// 칠해야 할 색의 밝기를 8-bit 기준으로 계산.
	// line_num에 start_intensity를 더하고 modulo (%) 연산자 사용.
	uint8_t r=0,g=0,b=0;
	uint8_t bright = (((line_num%32)<<3) + start_intensity)%256;
	//(line_um+stat_intensity)%32*8
	switch(line_num/32%3){
		case 0: r=bright;break;
		case 1: g=bright;;break;
		case 2: b=bright;break;
		default: r=bright;
	}
	// 칠해야 할 RGB 값을 5:6:5 16-bit로 변환.
	uint16_t rgb_temp = ILI9341_COLOR565(r,g,b);
	// 16-bit pixel 값을 line_buf에 채움.
	for(unsigned i = 0; i <ILI9341_WIDTH*2;i+=2){
		line_buf[i] = rgb_temp>>8;
		line_buf[i+1] = rgb_temp;
	}
	// line_buf의 첫 pixel과 마지막 pixel은 White border로 채움.
	line_buf[0] = 0xff;
	line_buf[1] = 0xff;
	line_buf[ILI9341_WIDTH*2-2] = 0xff;
	line_buf[ILI9341_WIDTH*2-1] = 0xff;
}
void end_of_frame_gradation(void) {
	/*
	// start_intensity를 +1 증가 또는 -1 감소 시킴.
	if(intensity_change) start_intensity++;
	else start_intensity--;
	// start_intensity가 MAX 이면 다음부터는 감소.
	// start_intensity가 0 이면 다음부터는 증가.
	if(start_intensity==248){//what is max value i don't know
		intensity_change = 1;
	}else if(start_intensity==0){
		intensity_change=0;
	}
*/
	start_intensity += intensity_change*8;
	if(start_intensity >=248) intensity_change = -1;
	else if(start_intensity <=0) intensity_change = 1;
}

/*
void while_temp(){
	while (1)
	  {
		ILI9341_Select();
		draw_line(line_num, line_buf);//line_buf <= value
			if (line_num==0) {
			// ILI9341_SetAddressWindow setting full screen
				ILI9341_SetAddressWindow(0,0,320-1,240-1);
			}
			HAL_GPIO_WritePin(ILI9341_DC_GPIO_Port, ILI9341_DC_Pin, 1);
			//HAL_SPI_Transmit(&hspi1, line_buf, ILI9341_WIDTH*2, 20);
			HAL_SPI_Transmit_DMA(&hspi1, line_buf, ILI9341_WIDTH*2);
			ILI9341_Unselect();

			if (++line_num == ILI9341_HEIGHT) {
				line_num=0;
				end_of_frame();
			}

}
*/



