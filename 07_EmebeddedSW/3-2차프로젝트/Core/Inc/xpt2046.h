/*
 * xpt2046.h
 *
 *  Created on: Jan 22, 2025
 *      Author: user
 */

#ifndef INC_XPT2046_H_
#define INC_XPT2046_H_

#include "main.h"
#include <stdbool.h>

/*** Redefine if necessary ***/


// Warning! Use SPI bus with < 2.5 Mbit speed, better ~650 Kbit to be save.
extern SPI_HandleTypeDef hspi3;


#define XPT2046_IRQ_Pin       	T_PEN_Pin
#define XPT2046_IRQ_GPIO_Port 	T_PEN_GPIO_Port
#define XPT2046_CS_Pin        	T_CS_Pin
#define XPT2046_CS_GPIO_Port  	T_CS_GPIO_Port

#define TOUCH_ORIENTATION_PORTRAIT 			(0U)
#define TOUCH_ORIENTATION_LANDSCAPE 		(1U)
#define TOUCH_ORIENTATION_PORTRAIT_MIRROR 	(2U)
#define TOUCH_ORIENTATION_LANDSCAPE_MIRROR 	(3U)

#define ORIENTATION	(TOUCH_ORIENTATION_PORTRAIT_MIRROR)

// change depending on screen orientation
#if (ORIENTATION == 0)
#define XPT2046_SCALE_X 240
#define XPT2046_SCALE_Y 320
#elif (ORIENTATION == 1)
#define XPT2046_SCALE_X 320
#define XPT2046_SCALE_Y 240
#elif (ORIENTATION == 2)
#define XPT2046_SCALE_X 240
#define XPT2046_SCALE_Y 320
#elif (ORIENTATION == 3)
#define XPT2046_SCALE_X 320
#define XPT2046_SCALE_Y 240
#endif

// to calibrate uncomment UART_Printf line in ili9341_touch.c
#define XPT2046_MIN_RAW_X 3400
#define XPT2046_MAX_RAW_X 29000
#define XPT2046_MIN_RAW_Y 3300
#define XPT2046_MAX_RAW_Y 30000

// call before initializing any SPI devices
extern void xpt_get(uint16_t* x, uint16_t* y);

#endif /* INC_XPT2046_H_ */
