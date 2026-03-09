/*
 * Test1.c
 *
 * Created: 2025-01-10 오후 3:03:15
 * Author : user
 */ 

#define F_CPU 16000000
#define BAUD 38400
#define TIMER_DIVISOR 8
#define TIMER_TICKS ((F_CPU/TIMER_DIVISOR)/BAUD)

#define RX_PIN PIND
#define RX_DDR DDRD
#define RX_NUM 0


#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include "Arimo Regular_24.h"
#include <util/delay.h>
#include <util/setbaud.h>

#define MAX_CS_DDR  DDRB
#define MAX_CS_PORT PORTB
#define MAX_CS_BIT  0

#define SIM_CS_DDR DDRB
#define SIM_CS_PORT PORTB
#define SIM_CS_BIT  2 //DC : pb1 for sh

#define PSPORT PORTD
#define PSPIN PIND
#define PS_BIT 3	// PD3 PD2

#define LCD_EN_DDR    DDRD
#define LCD_EN_PORT   PORTD
#define LCD_EN_BIT    4

#define LCD_RS_DDR    DDRB
#define LCD_RS_PORT   PORTB
#define LCD_RS_BIT    1

#define LCD_DB_DDR    DDRB
#define LCD_DB_PORT   PORTB
#define LCD_DB_BIT    4


#define ROTARY_A_PIN PINA
#define ROTARY_A_PIN_BIT 1
#define ROTARY_B_PIN PIND
#define ROTARY_B_PIN_BIT 6

#define LED_PORT PORTD
#define LED_DDR DDRD
#define LED_NUM 5

static volatile uint16_t scanCode = 0;//for keyboard scan

static volatile uint8_t counter = 0;//rotary counter led luminosity
static uint8_t a0;//for rotary bouncing
uint8_t prev_counter = 0;//rotary

uint8_t num=0;//keyboard

static volatile uint8_t s_rxByte=0;

static void uart_init(void) {
	// Set baud rate
	UBRRH = UBRR_VALUE>>8;
	UBRRL = UBRR_VALUE;
	// Enable receiver and transmitter
	UCSRB = (1<<TXEN);
	//// UCSRC를 Async, 8 data, 1 stop, no parity로 설정.
	UCSRC = (1<<UCSZ1)|(1<< UCSZ0);
}


static void uart_tx(uint8_t ch) {
	//// UCSRA의 UDRE bit가 1이 될 때까지 기다림.
	while(((UCSRA>>UDRE) & 1) != 1){}
	UDR = ch;
}
static void uart_tx_str(char * str) {
	while (*str) {
		uart_tx(*str++);
	}
}

ISR(PCINT2_vect) {
	//// PCINT11 핀이 0 이면 (즉 Start Bit 발생) PD0
	if( ( (RX_PIN>>RX_NUM)&1 ) == 0){
		//// PCINT11가 더 이상 발생 안 하도록 비활성화.
		//// GIMSK에서 PCINT2를 비활성화.
		GIMSK &= ~(1<<PCIE2);
		//// PCMSK2에서 PCINT11를 비활성화.
		PCMSK2 &= ~(1<<PCINT11);
		
		//// TCNT1 -> 0 (카운터 초기화)
		TCNT1 = 0;
		//// Half-cycle 후 인터럽트가 발생하도록 OCR1A 설정.
		OCR1A = (TIMER_TICKS /2 -1);
		//// Timer 1을 시작 (TCCR1B CS -> Divisor)
		TCCR1B |= (1<<CS11);
	}
}
ISR(TIMER1_COMPA_vect) {
	static uint8_t rxByte=0;
	static uint8_t rxBitCount=0;
	++rxBitCount;
	
	if(rxBitCount == 1){//// rxBitCount가 1이면 (Start Bit)
		//// OCR1A 값을 full cycle로 변경
		OCR1A = TIMER_TICKS-1;
		}else if((rxBitCount>=2) && (rxBitCount<=9)){//// rxBitCount가 2와 9 사이면 (Data Bits)
		//// PD0 핀을 읽어 Shift 한 후 rxByte에 추가.
		if(((RX_PIN>>RX_NUM)&1) == 1){
			rxByte |= (1<<(rxBitCount-2));
		}
		
		}else if(rxBitCount==10){//// rxBitCount가 10이면 (Stop Bit)
		//// Timer 1을 중지 (TCCR1B CS -> 0).
		TCCR1B &= ~(1<<CS11);
		//// rxByte 값을 s_rxByte에 저장 (main 함수에서 사용).
		s_rxByte = rxByte;
		//// rxByte와 rxBitCount을 초기화.
		rxByte = 0;
		rxBitCount = 0;
		//// PCINT11을 다시 활성화 (다음 byte 준비).
		//// GIMSK에서 PCINT2를 활성화.
		GIMSK |= (1<<PCIE2);
		//// PCMSK2에서 PCINT11를 활성화.
		PCMSK2 |= (1<<PCINT11);
	}
	
}
void rx_sw_init(){
	// Timer 1 설정
	//// TCCR1A 와 TCCR1B 설정 (하지만 카운트를 시작하지는 않음).
	TCCR1B |= (1 << WGM12);//CTC FOR timer 1
	//// TIMER1_COMPA 인터럽트를 활성화 (Receiver에서 사용).
	TIMSK |= (1 << OCIE1A);
	//// OCR1A 는 아직 설정 안 함 (PCINT2_vect에서 함).
	// PCINT 설정
	//// GIMSK에서 PCINT2를 활성화.
	GIMSK |= (1<<PCIE2);
	//// PCMSK2에서 PCINT11를 활성화.
	PCMSK2 |= (1<<PCINT11);
}
ISR(PCINT1_vect) {
	uint8_t a = ((ROTARY_A_PIN >> ROTARY_A_PIN_BIT)&1); /// A 핀의 값을 읽음.
	uint8_t b = ((ROTARY_B_PIN >> ROTARY_B_PIN_BIT)&1); /// B 핀의 값을 읽음.
	
	if(a != a0){
		
		if(a!=b){/// A와 B 값이 다르면 counter 증가;
			counter++;
		}else{/// 그렇지 않으면 counter 감소;
			counter--;
		}
		
		if(counter > 250){/// counter가 199보다 크면 0으로 초기화
			counter=0;
		}else if(counter<0){/// counter가 0보다 작으면 199로 초기화
			counter=250;
		}
		a0= a;
	}
	
}

ISR (INT0_vect) {//ps keyboard related interrupt
	static uint16_t receivedBits = 0, bitCount = 0;

	//// Data 핀을 읽어 1이면, receivedBits의 해당 bit를 1로 설정.
	if((PSPIN>>PS_BIT) & 1){
		receivedBits |= (1<<bitCount);
	}
	//// bitCount를 증가하고, 
	bitCount++;
	if(bitCount==11){//11이면
		scanCode = receivedBits;
		receivedBits=0;
		bitCount=0;
	}
	////     receivedBits를 scanCode에 저장.
	////     receivedBits와 bitCount를 0으로 초기화.
	//// }
}
static void lcd_write_nibble(uint8_t rs, uint8_t data){
	LCD_RS_PORT &=~(1<<LCD_RS_BIT);
	LCD_RS_PORT |= (rs<<LCD_RS_BIT);
	LCD_EN_PORT |= (1<<LCD_EN_BIT);
	LCD_DB_PORT&=~(0XF0);
	data&=~(0x0F);
	LCD_DB_PORT|=data;
	LCD_EN_PORT&=~(1<<LCD_EN_BIT);
}

static void lcd_write_byte(uint8_t rs, uint8_t data){
	lcd_write_nibble(rs,data);//상위 비트
	lcd_write_nibble(rs,data<<4);//하위 비트
	
}

static inline void lcd_wait(){
	_delay_us(60);
}

static void lcd_init(){
	LCD_EN_DDR |= (1<<LCD_EN_BIT);
	LCD_RS_DDR |= (1<<LCD_RS_BIT);
	
	LCD_DB_DDR |= 0XF0;
	
	_delay_ms(20);
	
	lcd_write_nibble(0,3);
	lcd_wait();
	lcd_write_nibble(0,2);
	lcd_wait();
	lcd_write_byte(0,0x28);
	lcd_wait();
	lcd_write_byte(0,0x0C);
	lcd_wait();
}

static uint8_t ps2_scan_to_ascii(uint16_t code) {//keyscan -> ascii
	uint8_t s, c;
	static uint8_t sBreak=0, sModifier=0, sShift=0;
	static const char keymap_unshifted[] PROGMEM =
	"             \011`      q1   zsaw2  cxde43   vftr5  nbhgy6   mju78  ,kio09"
	"  ./l;p-   \' [=    \015] \\        \010  1 47   0.2568\033  +3-*9      ";
	static const char keymap_shifted[] PROGMEM =
	"             \011~      Q!   ZSAW@  CXDE$#   VFTR%  NBHGY^   MJU&*  <KIO)("
	"  >?L:P_   \" {+    \015} |        \010  1 47   0.2568\033  +3-*9       ";

	s = (code>>1) & 0xff;		// Remove start, parity, stop bits

	if (s==0xaa)
	return 0;				// Ignore BAT completion code
	if (s==0xf0) {
		sBreak=1;
		return 0;
	}
	if (s==0xe0) {
		sModifier=1;
		return 0;
	}
	if (sBreak) {						// if key released
		if ((s==0x12) || (s==0x59)) {	// Left or Right Shift Key
			sShift=0;
		}
		sBreak=0; sModifier=0;
		return 0;
	}
	if ((s==0x12) || (s==0x59))			// Left or Right Shift Key
	sShift=1;
	if (sModifier)						// If modifier ON, return 0
	return 0;
	if (sShift==0)
	c=pgm_read_byte(keymap_unshifted+s);
	else
	c=pgm_read_byte(keymap_shifted+s);
	if ((c==32) && (s!=0x29))			// Ignore unless real space key
	return 0;
	return c;
}



/*************************/
//MAX and SPI related function
/****************************/
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
static void max7219_init(void) {
	const uint8_t initData[] = {
		0x09, 0xff, 0x0a, 0x01, 0x0b, 0x07, 0x0c, 0x01, 0x0f, 0x00
	};
	/// SCK, DO, CS의 DDR을 설정.
	MAX_CS_DDR |= (0xC1);//1100_0001 write mode
	/// CS는 1로 초기화.
	MAX_CS_PORT |= (1<<MAX_CS_BIT);//cs:0
	
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

/***************************/
//SH1106 related function
/*****************************/

void sh1106_init(void) {
	const uint8_t init_commands[] = {
		0xae, 0x00, 0x10, 0x40, 0x81, 0x80, 0xc0, 0xa8,
		0x3f, 0xd3, 0x00, 0xd5, 0x50, 0xd9, 0x22, 0xda,
		0x12, 0xdb, 0x35, 0xa4, 0xa6, 0xaf
	};

	//// CS, DC 핀의 DDR 설정.
	SIM_CS_DDR |= (0xC6);//1100_0110 12 6 
	//// CS <- 1 (초기값)
	SIM_CS_PORT |= (1<<SIM_CS_BIT);//dc:1 cs:2
	
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


void keyboard_init(void){
	//// Clock과 Data핀의 pull-up 저항을 활성화.
	PSPORT |= (1<<PS_BIT);
	PSPORT |= (1<<(PS_BIT-1));
	//keyboard interrupt init
	MCUCR = (0<<ISC00) | (1<<ISC01);
	GIMSK = (1<<INT0);
}
void keyboard_func(){
	uint8_t temp;
	if (scanCode) {	
		temp = ps2_scan_to_ascii(scanCode);
		if(temp != 0){
			//// scanCode의 값 및 각 정보를 MAX7219에 표시.
			MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
			SpiUSITx(0X01);
			SpiUSITx(scanCode&(0x001));
			MAX_CS_PORT |= (1<<MAX_CS_BIT);
			
			MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
			SpiUSITx(0X02);
			SpiUSITx((scanCode>>1) & (0x00F));
			MAX_CS_PORT |= (1<<MAX_CS_BIT);
			
			MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
			SpiUSITx(0X03);
			SpiUSITx((scanCode>>5)&(0x00F));
			MAX_CS_PORT |= (1<<MAX_CS_BIT);
			
			MAX_CS_PORT &= ~(1<<MAX_CS_BIT);//parity bit
			SpiUSITx(0X04);
			SpiUSITx((scanCode>>9)&(0x001));
			MAX_CS_PORT |= (1<<MAX_CS_BIT);
			
			MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
			SpiUSITx(0X05);
			SpiUSITx(scanCode>>10);
			MAX_CS_PORT |= (1<<MAX_CS_BIT);
			MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
			SpiUSITx(0X07);
			SpiUSITx(temp & (0x0F));
			MAX_CS_PORT |= (1<<MAX_CS_BIT);
			
			MAX_CS_PORT &= ~(1<<MAX_CS_BIT);
			SpiUSITx(0X08);
			SpiUSITx(temp>>4);
			MAX_CS_PORT |= (1<<MAX_CS_BIT);
			uart_tx(temp);
		}
		scanCode = 0;
		
	}
}

void led_pwm_init(void){
	LED_DDR |= (1<<LED_NUM);
	LED_PORT |= (1<<LED_NUM);
	OCR0B = 0;
	TCCR0A |= (1<<WGM01) | (1<<WGM00);//fast pwm
	TCCR0A |= (1<<COM0B1) | (1<<COM0B0);//non-inverting mode 1 0
	TCCR0B |= (1<<CS01) | (1<<CS00);
}


void rotary_init(){
	prev_counter = 0;
	DDRA &= ~(1<<PINA1);
	DDRD &= ~(1<<PIND6);
	/// PCMSK1 레지스터에서 PCINT9 활성화
	PCMSK1 |= (1<<PCINT9);
	/// GIMSK 레지스터에서 PCIE1 활성화
	GIMSK |= (1<<PCIE1);
}
void rotary_func(){
	if(counter != prev_counter){
		prev_counter = counter;
		OCR0B = 250-counter;
		sh1106_text_font24(char_addr[counter/100],char_width[counter/100],4,34);
		sh1106_text_font24(char_addr[counter/10%10],char_width[counter/10%10],4,34+16*1);
		sh1106_text_font24(char_addr[counter%10],char_width[counter%10],4,34+16*2);
	}
}

int main(void) {
	
	keyboard_init();//interrupt
	uart_init();//tx init
	rx_sw_init();//rx init
	rotary_init();
	sei();
	led_pwm_init();//pwm init
	//display things initial
	max7219_init();
	sh1106_init();

	USICR &= ~(1<<USIWM0);
	lcd_init();
	lcd_write_byte(0, 0x01);
	lcd_wait();
	
	sh1106_clear();
	sh1106_border();
	
	USICR &= ~(1<<USIWM0);
	while (1) {
		rotary_func();
		keyboard_func();// keyboard display
		if(s_rxByte){
			USICR &= ~(1<<USIWM0);//USCK mode off
			lcd_write_byte(1, s_rxByte);
			lcd_wait();
		    s_rxByte = 0;
			num++;
			if(num==16){
				lcd_write_byte(0,0x80+0x40);
				lcd_wait();
			}
			if(num==32){
				lcd_write_byte(0, 0x01); // display clear
				lcd_wait();
				num=0;
			}
		}
	}
}
