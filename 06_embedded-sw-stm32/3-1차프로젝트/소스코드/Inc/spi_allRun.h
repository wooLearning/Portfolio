/*
 * spi_allRun.h
 *
 *  Created on: Jan 17, 2025
 *      Author: user
 */

#ifndef INC_SPI_ALLRUN_H_
#define INC_SPI_ALLRUN_H_

#define NUM_LED 24
#define RESET_PULSE 16 // 50us / 0.4us / 8

#endif /* INC_SPI_ALLRUN_H_ */

/*
 * spi_allRun.c
 *
 *  Created on: Jan 17, 2025
 *      Author: user
 */


extern SPI_HandleTypeDef hspi2;
extern SPI_HandleTypeDef hspi3;

extern TIM_HandleTypeDef htim1;


void led_blink();

void spi_max_init();
void spi_max_run();
void sh1106_init(void);
void sh1106_set_location(uint8_t page, uint8_t column);


void sh1106_clear(void);
void sh1106_testpattern(void);

void sh1106_border(void);

void sh_bar(uint8_t num);

void set_spi_bits(uint8_t * buf, uint8_t val);
void ledRing_test();
void ledRing_run();

void spi_all_init();
void spi_all_run();

