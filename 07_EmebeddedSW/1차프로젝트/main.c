/*
 * AllTest.c
 *
 * Created: 2024-12-31 오후 2:52:31
 * Author : SangWook.Woo
 */ 

#define F_CPU 8000000 // 8Mhz

#include <avr/io.h>
#include <util/delay.h>
#include <avr/pgmspace.h>
#include <stdio.h>
#include "Arimo Regular_24.h"
#include <avr/interrupt.h>

#define LCD_EN_DDR   DDRA
#define LCD_EN_PORT  PORTA
#define LCD_EN_BIT   1

#define LCD_RS_DDR   DDRA
#define LCD_RS_PORT  PORTA
#define LCD_RS_BIT   0

#define LCD_DB_DDR   DDRD
#define LCD_DB_PORT  PORTD
#define LCD_DB_BIT   0 


#define MAX_CS_DDR  DDRB
#define MAX_CS_PORT PORTB
#define MAX_CS_BIT  3

#define SIM_CS_DDR DDRB
#define SIM_CS_PORT PORTB
#define SIM_CS_BIT  5

static void lcd_write_nibble(uint8_t rs, uint8_t data){
	//// RS Pin 에 rs 값을 출력 (0 또는 1)
	LCD_RS_PORT &=~(1<<LCD_RS_BIT);
	LCD_RS_PORT |= (rs<<LCD_RS_BIT);
	//// E Pin 에 1 출력
	LCD_EN_PORT |= (1<<LCD_EN_BIT);
	//// PortD3~0 에 data의 Bit3~0
	LCD_DB_PORT&=~(0X0F);
	LCD_DB_PORT|=(data&(0x0F));
	//// E Pin 에 0 출력
	LCD_EN_PORT&=~(1<<LCD_EN_BIT);
}

static void lcd_write_byte(uint8_t rs, uint8_t data) {
	//// 변수 data의 Bit 7~4를 lcd_write_nibble() 보냄
	lcd_write_nibble(rs,data>>4);
	//// 변수 data의 Bit 3~0를 lcd_write_nibble() 보냄
	lcd_write_nibble(rs,data);
}

static inline void lcd_wait(){
	_delay_us(60);
}

static void lcd_init(){
	//// RS, E Pin의 방향을 Output으로 설정
	LCD_EN_DDR |= (1<<LCD_EN_BIT);
	LCD_RS_DDR |= (1<<LCD_RS_BIT);
	
	//// DB3~DB0 Pin의 방향을 Output으로 설정
	LCD_DB_DDR |= 0X0F;
	_delay_ms(20);
	
	lcd_write_nibble(0,3); // Function Set ; 8-bit mode
	lcd_wait();
	lcd_write_nibble(0,2); // Function Set ; 4-bit mode
	lcd_wait();
	lcd_write_byte(0,0x28); // Function Set ; 4-bit, 2lines, 5X8 font 0010_1000
	lcd_wait();
	lcd_write_byte(0,0x0C);  // Display on
	lcd_wait();
	
}

static void lcd_puts(char * str) {
	uint8_t i;
	lcd_write_byte(0, 0x80); // move to 1st line
	lcd_wait();
	for (i=0; i<16; i++) {
		if (str[i] == '\0')
		return;
		lcd_write_byte(1, str[i]);
		lcd_wait();
	}
	lcd_write_byte(0, 0x80+0x40); // move to 2nd line
	lcd_wait();
	for (i=16; i<32; i++) {
		if (str[i] == '\0')
		return;
		lcd_write_byte(1, str[i]);
		lcd_wait();
	}
}


static void SpiUSITx(uint8_t data) {
	/// USIDR 레지스터에 `data`를 기록.
	USIDR = data;
	/// 다음을 8번 반복:
	for(unsigned i=0;i<8;i++){
		/// - USIWM0, USITC,1 write
		USICR |= (1<<USIWM0);
		USICR |= (1<<USITC);
		//USIWM0, USITC, USICLK 에 1 write
		USICR |= (1<<USIWM0);
		USICR |= (1<<USITC);
		USICR |= (1<<USICLK);
	}
	
}

void sh1106_init(void) {
	const uint8_t init_commands[] = {
		0xae, 0x00, 0x10, 0x40, 0x81, 0x80, 0xc0, 0xa8,
		0x3f, 0xd3, 0x00, 0xd5, 0x50, 0xd9, 0x22, 0xda,
		0x12, 0xdb, 0x35, 0xa4, 0xa6, 0xaf
	};

	//// CS, DC 핀의 DDR 설정.
	SIM_CS_DDR |= (0xF0);//1111_0000
	//// CS <- 1 (초기값)
    SIM_CS_PORT |= (1<<SIM_CS_BIT);//dc:4 cs:5 do:6 clk:7
	
	//// CS <- 0
	SIM_CS_PORT &= ~(1<<SIM_CS_BIT);
	//// DC <- 0
	SIM_CS_PORT &= ~(1<<(SIM_CS_BIT-1));
	
	for (uint8_t i = 0; i < sizeof(init_commands); i++) {
		SpiUSITx(init_commands[i]);
	}
	//// CS <- 1
	SIM_CS_PORT |= (1<<SIM_CS_BIT);
}

void sh1106_set_location(uint8_t page, uint8_t column) {
	//// DC <- 0
	SIM_CS_PORT &= ~(1<<(SIM_CS_BIT-1));
	SpiUSITx(0xB0 + page);/* Set Page Address *///1011_0000
	SpiUSITx(0x00 + (column&(0b00001111)) );/* Set Column Address Low 4 bits */
	SpiUSITx(0x10 + (column>>4) );/* Set Column Address High 4 bits */
}


void sh1106_clear(void) {
	//// CS <- 0
	SIM_CS_PORT &= ~(1<<SIM_CS_BIT);
	for (uint8_t page = 0; page < 8; page++) {
		sh1106_set_location(page, 0);
		//// DC ← 1
		SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
		for (uint8_t count = 0; count < 132; count++) {
			SpiUSITx(0);
		}
	}
	//// CS <- 1
	SIM_CS_PORT |= (1<<SIM_CS_BIT);
}

void sh1106_testpattern(void){
	
	//// CS <- 0
	SIM_CS_PORT &= ~(1<<SIM_CS_BIT);
	
	for(uint8_t page=0;page<8;page++){
		sh1106_set_location(page,34);
		//// DC <- 1
		SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
		
		for(uint8_t count=0;count<64;count++){
			SpiUSITx(0xF0);
		}
	}
	//// CS <- 1
	SIM_CS_PORT |= (1<<SIM_CS_BIT);
}

void sh1106_border(void){
	
	//// CS <- 0
	SIM_CS_PORT &= ~(1<<SIM_CS_BIT);
	
	// Top Border
	sh1106_set_location(0,0);
	//// DC <- 1
	SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
	
	for(uint8_t column=0;column<132; column++){
		SpiUSITx(0x01);
	}
	
	// Bottom Border
	sh1106_set_location(7,0);
	//// DC <- 1
	SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
	
	for(uint8_t column=0;column<132; column++){
		SpiUSITx(0x80);
	}
	
	for(uint8_t page=0; page <8; page++){
		//Left Border
		sh1106_set_location(page,2);
		//// DC <- 1
		SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
		SpiUSITx(0xFF);
		
		//Right Border
		sh1106_set_location(page,129);
		//// DC <- 1
		SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
		SpiUSITx(0xFF);
	}
	
	//// CS <- 1
	SIM_CS_PORT |= (1<<SIM_CS_BIT);
}

void sh1106_text_font24(const char * font_addr, uint8_t font_width, uint8_t page, uint8_t column) {
	unsigned l_fill_width = font_width < 16 ? (16 - font_width) >> 1 : 0;
	unsigned r_fill_width = (font_width + l_fill_width) < 16 ? 16 - (font_width + l_fill_width) : 0;

	//// CS ← 0
	SIM_CS_PORT &= ~(1<<SIM_CS_BIT);
	for (unsigned y = 0; y < 24 / 8; y++) {
		sh1106_set_location(page + y, column);

		//// DC ← 1
		SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
		for (unsigned x = 0; x < l_fill_width; x++) {
			SpiUSITx(0); // Font 왼쪽의 공백을 0으로 채움.
		}

		for (unsigned x = 0; x < font_width; x++) {
			SpiUSITx(pgm_read_byte(font_addr++)); // Font 데이터를 Program Memory에서 가져와서 SPI로 전송.
		}

		for (unsigned x = 0; x < r_fill_width; x++) {
			SpiUSITx(0); // Font 오른쪽의 공백을 0으로 채움.
		}
	}
	//// CS ← 1
	SIM_CS_PORT |= (1<<SIM_CS_BIT);
}

static void max7219_init(void) {
	const uint8_t initData[] = {
		0x09, 0xff, 0x0a, 0x01, 0x0b, 0x07, 0x0c, 0x01, 0x0f, 0x00
	};
	/// SCK, DO, CS의 DDR을 설정.
	MAX_CS_DDR |= (0xC8);//1100_1000 write mode
	/// CS는 1로 초기화.
	MAX_CS_PORT |= (1<<MAX_CS_BIT);
	
	for (unsigned i = 0; i < sizeof(initData); i += 2) {
		/// CS를 0으로 설정 (활성화).
		MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
		/// SPI로 `initData[i]`와 `initData[i+1]` 전송.
		SpiUSITx(initData[i]);
		SpiUSITx(initData[i+1]);
		/// CS를 1로 설정.
		MAX_CS_PORT |= (1<<MAX_CS_BIT);
	}
}
void max_print_init(){// hour and second test
	//원하는 자리수만 decode
	/// CS를 0으로 설정.
	MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	SpiUSITx(0x09);
	SpiUSITx(0b11011110);//H S(M은 안됨)
	/// CS를 1로 설정.
	MAX_CS_PORT |= (1<<MAX_CS_BIT);
	
	/// CS를 0으로 설정.
	MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	SpiUSITx(6);
	SpiUSITx(0b10110111);//H
	/// CS를 1로 설정.
	MAX_CS_PORT |= (1<<MAX_CS_BIT);
	
	/// CS를 0으로 설정.
	MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	SpiUSITx(1);
	SpiUSITx(0b11011011);
	/// CS를 1로 설정.
	MAX_CS_PORT |= (1<<MAX_CS_BIT);
}
static void max_print(uint8_t hour, uint8_t minute, uint8_t second){
	
	 /// CS를 0으로 설정.
	 MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	 SpiUSITx(8);
	 SpiUSITx(hour/10);
	 /// CS를 1로 설정.
	 MAX_CS_PORT |= (1<<MAX_CS_BIT);
	 
	 /// CS를 0으로 설정.
	 MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	 SpiUSITx(7);
	 SpiUSITx(hour%10);
	 /// CS를 1로 설정.
	 MAX_CS_PORT |= (1<<MAX_CS_BIT);
	 
	 /// CS를 0으로 설정.
	 MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	 SpiUSITx(5);
	 SpiUSITx(minute/10);
	 /// CS를 1로 설정.
	 MAX_CS_PORT |= (1<<MAX_CS_BIT);
	 
	 /// CS를 0으로 설정.
	 MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	 SpiUSITx(4);
	 SpiUSITx(minute%10);
	 /// CS를 1로 설정.
	 MAX_CS_PORT |= (1<<MAX_CS_BIT);
	 
	 /// CS를 0으로 설정.
	 MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	 SpiUSITx(3);
	 SpiUSITx(second/10);
	 /// CS를 1로 설정.
	 MAX_CS_PORT |= (1<<MAX_CS_BIT);
	 
	 /// CS를 0으로 설정.
	 MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
	 SpiUSITx(2);
	 SpiUSITx(second%10);
	 /// CS를 1로 설정.
	 MAX_CS_PORT |= (1<<MAX_CS_BIT);
	 
}
static void sh_print(uint8_t hour, uint8_t minute, uint8_t second){
	//test font
	uint8_t k = 16;
	sh1106_text_font24(char_addr[hour/10],char_width[hour/10],4,10);
	sh1106_text_font24(char_addr[hour%10],char_width[hour%10],4,10+k*1);
	//// CS <- 0
	SIM_CS_PORT &= ~(1<<SIM_CS_BIT);
	for(uint8_t i =4;i<7;i++){
		sh1106_set_location(i,45);//40 , 26
		//// DC <- 1
		SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
		SpiUSITx(0xFF);
	}
	//// CS <- 1
	SIM_CS_PORT |= (1<<SIM_CS_BIT);
	sh1106_text_font24(char_addr[minute/10],char_width[minute/10],4,10+k*3-10);
	sh1106_text_font24(char_addr[minute%10],char_width[minute%10],4,10+k*4-10);
	//// CS <- 0
	SIM_CS_PORT &= ~(1<<SIM_CS_BIT);
	for(uint8_t i =4;i<7;i++){
		sh1106_set_location(i,84);
		//// DC <- 1
		SIM_CS_PORT |= (1<<(SIM_CS_BIT-1));
		SpiUSITx(0xFF);
	}
	//// CS <- 1
	SIM_CS_PORT |= (1<<SIM_CS_BIT);
	sh1106_text_font24(char_addr[second/10],char_width[second/10],4,10+k*5);
	sh1106_text_font24(char_addr[second%10],char_width[second%10],4, 10+k*6);
}
char message[] = "00 : 00 : 00";

static void display(uint8_t hour, uint8_t minute, uint8_t second){
	max_print(hour,minute,second);
	sh_print(hour,minute,second);
	sprintf(message,"%02d : %02d : %02d",hour,minute,second);
	lcd_puts(message);//delay == 240ms
}


int main(void)
{
	
	uint8_t hour=0,minute=0,second=0;
	uint32_t timer=0;
	PINB &= 0;//read mode
	PORTB |= (1<<PORTB1);
	PORTB |= (1<<PORTB2);//pullup necessary
	_delay_ms(10);
	sh1106_init();
	max7219_init();
	max_print_init();
	lcd_init();
	lcd_write_byte(0, 0x01); // display clear
	sh1106_clear();
	sh1106_border();
	display(hour,minute,second);
	uint8_t reset = 0;//when 1 all reset
	uint8_t start = 0;//0 stop 1 start
	
	
	while (1) {
		
		if(((PINB>>1) & 1)==0){
			start=1;
		}
		if(((PINB>>2) & 1)==0){
			reset = 1;
			start=0;
		}
		if(start == 1){
			if(timer == 350000){
				second++;
				timer=0;
				display(hour,minute,second);
				timer = timer + 96000;
			}
			if(second == 60){
				second = 0;
				minute++;
			}
			if(minute == 60){
				minute=0;
				hour++;
			}
			if(hour>=100){
				start = 0;
			}
			timer++;
		}
		
		if(reset==1){
			hour = 0;
			timer = 0;
			minute = 0;
			second = 0;
			display(hour,minute,second);
			timer = timer + 96000;
			reset = 0;
		}
	
	}
}