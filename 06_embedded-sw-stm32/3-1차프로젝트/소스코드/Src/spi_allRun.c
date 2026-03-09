/*
 * spi_allRun.c
 *
 *  Created on: Jan 17, 2025
 *      Author: user
 */
#include<main.h>

#include<spi_allRun.h>

static uint8_t spi_bits[NUM_LED*3*3];
static uint8_t reset_bits[RESET_PULSE]={0};
static uint8_t bar_buf[120];
static uint8_t pos;

void led_blink(){
	HAL_GPIO_TogglePin(LED_GPIO_Port, LED_Pin);
	HAL_Delay(1000);
}

void spi_max_init(){
	const uint8_t initData[] = {
			0x09, 0xff, 0x0a, 0x01, 0x0b, 0x07, 0x0c, 0x01, 0x0f, 0x00,0x0b,0X01//lower 2bit use
	};
	for (unsigned i=0; i<sizeof(initData); i+=2) {
		HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 0);
		HAL_SPI_Transmit(&hspi3, initData+i, 2, 10);
		HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 1);
	}
	/*
	uint8_t max_init_buf[12]={8,0,7,0,6,0,5,0,4,0,3,0};
	for(unsigned i=0;i<12;i+=2){
		HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 0);
		HAL_SPI_Transmit(&hspi3, max_init_buf+i, 2, 10);
		HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 1);
	}
	*/
}
void spi_max_run(){
	for (unsigned number = 0; number < 10; number++) {
		for (unsigned digit=0; digit<8; digit++) {
			uint8_t buf[2];
			buf[0]=(7-digit)+1;
			buf[1]=(number+digit)%10;
			HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 0);
			HAL_SPI_Transmit(&hspi3, buf, 2, 10);
			HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 1);
		}
		HAL_Delay(1000);
	}

}
void sh1106_init(void) {
	const uint8_t init_commands[] = {
		0xae, 0x00, 0x10, 0x40, 0x81, 0x80, 0xc0, 0xa8,
		0x3f, 0xd3, 0x00, 0xd5, 0x50, 0xd9, 0x22, 0xda,
		0x12, 0xdb, 0x35, 0xa4, 0xa6, 0xaf
	};


	//// CS <- 0
    HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 0);
	//// DC <- 0
    HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 0);

	HAL_SPI_Transmit(&hspi3, init_commands, sizeof(init_commands), 10);
	//// CS <- 1
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 1);
}

void sh1106_set_location(uint8_t page, uint8_t column) {
	//// DC <- 0
	HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 0);
	uint8_t buf[3] = {0xB0 + page, 0x00 + (column&(0b00001111)), 0x10 + (column>>4)};
	/* Set Page Address *///1011_0000
	/* Set Column Address Low 4 bits */
	/* Set Column Address High 4 bits */
	HAL_SPI_Transmit(&hspi3, buf , sizeof(buf), 10);
}


void sh1106_clear(void) {
	//// CS <- 0
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 0);
	uint8_t buf[132] = {0};
	for (uint8_t page = 0; page < 8; page++) {
		sh1106_set_location(page, 0);
		//// DC ?�� 1
		HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 1);
		HAL_SPI_Transmit(&hspi3, buf, sizeof(buf), 10);
	}
	//// CS <- 1
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 1);
}

void sh1106_testpattern(void){

	//// CS <- 0
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 0);

	for(uint8_t page=0;page<8;page++){
		sh1106_set_location(page,34);
		//// DC <- 1
		HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 1);
		uint8_t buf = 0x0f;
		for(uint8_t count=0;count<64;count++){
			HAL_SPI_Transmit(&hspi3, &buf, sizeof(buf), 10);
		}
	}
	//// CS <- 1
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 1);
}

void sh1106_border(void){

	//// CS <- 0
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 0);

	// Top Border
	sh1106_set_location(0,0);
	//// DC <- 1
	HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 1);

	uint8_t buf = 0x01;
	for(uint8_t column=0;column<132; column++){
		HAL_SPI_Transmit(&hspi3, &buf, sizeof(buf), 10);
	}

	// Bottom Border
	sh1106_set_location(7,0);
	//// DC <- 1
	HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 1);

	buf = 0x08;
	for(uint8_t column=0;column<132; column++){
		HAL_SPI_Transmit(&hspi3,&buf, sizeof(buf), 10);
	}

	for(uint8_t page=0; page <8; page++){
		//Left Border
		sh1106_set_location(page,2);
		//// DC <- 1
		HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 1);
		buf = 0xFF;
		HAL_SPI_Transmit(&hspi3,&buf, sizeof(buf), 10);

		//Right Border
		sh1106_set_location(page,129);
		//// DC <- 1
		HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 1);
		buf=0x0FF;
		HAL_SPI_Transmit(&hspi3,&buf, sizeof(buf), 10);
	}

	//// CS <- 1
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 1);
}


void sh_bar(uint8_t num){
	//// CS <- 0
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 0);
	uint8_t i=0;
	for(i=0;i<num;i++){
		bar_buf[i] = 0xFF;
	}
	for(i=num;i<115;i++){
		bar_buf[i]=0x00;
	}
	if(num<115){
		for(uint8_t page=3;page<6;page++){
			sh1106_set_location(page,0);
			//// DC <- 1
			HAL_GPIO_WritePin(SH1106_DC_GPIO_Port, SH1106_DC_Pin, 1);
			HAL_SPI_Transmit(&hspi3, bar_buf,sizeof(bar_buf),10);
		}
	}
	//// CS <- 1
	HAL_GPIO_WritePin(SH1106_CS_GPIO_Port, SH1106_CS_Pin, 1);
}

void set_spi_bits(uint8_t * buf, uint8_t val) {
	uint32_t pulse=0;
	for (unsigned i=0; i<8; i++) {
		uint8_t bit=(val>>(7-i)) & 1;
		pulse = (pulse<<3) | (bit==0 ? 0b100 : 0b110);
	}
	buf[0] = (pulse>>16) & 0xff;
	buf[1] = (pulse>>8) & 0xff;
	buf[2] = (pulse>>0) & 0xff;
}
void ledRing_test(){
	uint8_t N = 1;
	uint8_t c= 1;
	for (unsigned i=0; i<NUM_LED; i++) {
		set_spi_bits(spi_bits + i*9+0, 0); // Green 0
		set_spi_bits(spi_bits + i*9+3, 0); // Blue  0
		set_spi_bits(spi_bits + i*9+6, 0); // Red  0
	}
	set_spi_bits(spi_bits + N*9 + c*3, 0x80);
	HAL_SPI_Transmit(&hspi2, spi_bits, sizeof(spi_bits), 10);
	HAL_SPI_Transmit(&hspi2, reset_bits, sizeof(reset_bits), 10);
}
void ledRing_run(){
	for (unsigned i=0; i<NUM_LED; i++) {
		set_spi_bits(spi_bits + i*9+0, 0); // Green ?�� 0
		set_spi_bits(spi_bits + i*9+3, 0); // Blue ?�� 0
		set_spi_bits(spi_bits + i*9+6, 0); // Red ?�� 0
	}
	for(unsigned i=1; i<24;i++){
		set_spi_bits(spi_bits + (i-1)*9 + 3*((i%3==0)? 2 : (i%3-1)), 0x00);
		set_spi_bits(spi_bits + i*9 + 3*(i%3), 0x80);
		// spi_bit[]
		HAL_SPI_Transmit(&hspi2, spi_bits, sizeof(spi_bits), 10);
		// Reset 50us
		HAL_SPI_Transmit(&hspi2, reset_bits, sizeof(reset_bits), 10);
		HAL_Delay(500);
	}

}

void spi_all_init(){
	spi_max_init();
	sh1106_init();
	sh1106_clear();
	//test pattern and border line
	//sh1106_testpattern();
	//sh1106_border();
	sh1106_clear();
	pos = TIM1->CNT;
}
void spi_all_run(){
  //led_blink();
  //spi_max();

  //sh_scroll();

  //encoder + addresable led
  //TIM1-> CNT value read
  if(pos != TIM1->CNT){
	  //TIM1->cnt update
	  pos = TIM1->CNT;
	for (unsigned i=0; i<NUM_LED; i++) {
		set_spi_bits(spi_bits + i*9+0, 0); // Green 0
		set_spi_bits(spi_bits + i*9+3, 0); // Blue  0
		set_spi_bits(spi_bits + i*9+6, 0); // Red  0
	}
	set_spi_bits(spi_bits + 9*pos + 3*(pos%3), 0x80);//variabel add for 3 can color change


	// spi_bit[]
	HAL_SPI_Transmit(&hspi2, spi_bits, sizeof(spi_bits), 10);
	HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 0);
	uint8_t pos_buf[4] = {2,pos/10,1,pos%10};
	HAL_SPI_Transmit(&hspi3, pos_buf, 2, 10);
	HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 1);

	HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 0);
	HAL_SPI_Transmit(&hspi3, pos_buf+2, 2, 10);
	HAL_GPIO_WritePin(MAX_CS_GPIO_Port, MAX_CS_Pin, 1);
	sh_bar(pos*5);
	// Reset 50us
	HAL_SPI_Transmit(&hspi2, reset_bits, sizeof(reset_bits), 10);
  }
  HAL_Delay(10);
}
