###### FPGA Configuration Settings
set_property CONFIG_VOLTAGE 1.8 [current_design] ;
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design] ;
# set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design] ;

###### 100MHz Oscilator Clock Pins, External PL Clock
 set_property -dict { PACKAGE_PIN D7 IOSTANDARD LVCMOS18 } [get_ports PL_CLK_100MHZ*] ;
 set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -hierarchical -filter {NAME =~ "*PL_CLK_100MHZ"}] ;
 create_clock -period 10 -name PL_CLK_OSC [get_ports PL_CLK_100MHZ*];
set_property -dict { PACKAGE_PIN F8 IOSTANDARD LVCMOS18 } [get_ports RstButton*] ; #PUSH_BTN[4]

###### Segment (FND) Pins
# set_property -dict { PACKAGE_PIN M2 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[7]] ;
# set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[6]] ;
# set_property -dict { PACKAGE_PIN M5 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[5]] ;
# set_property -dict { PACKAGE_PIN M4 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[4]] ;
# set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[3]] ;
# set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[2]] ;
# set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[1]] ;
# set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_OUT*[0]] ;
# set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_COMOUT*[3]] ;
# set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_COMOUT*[2]] ;
# set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_COMOUT*[1]] ;
# set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS12 } [get_ports SEGMENT_COMOUT*[0]] ;

###### Text LCD (Character LCD) Control pins
#set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS12 } [get_ports LCD_RS*] ;
#set_property -dict { PACKAGE_PIN M5 IOSTANDARD LVCMOS12 } [get_ports LCD_RW*] ;
#set_property -dict { PACKAGE_PIN M4 IOSTANDARD LVCMOS12 } [get_ports LCD_EN*] ;
###### Text LCD (Character LCD) Data Pins
#set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[7]] ;
#set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[6]] ;
#set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[5]] ;
#set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[4]] ;
#set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[3]] ;
#set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[2]] ;
#set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[1]] ;
#set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS12 } [get_ports LCD_DATA*[0]] ;

###### TFT LCD Control Pins
set_property -dict { PACKAGE_PIN G1 IOSTANDARD LVCMOS12 } [get_ports TFT_DCLK*] ;
set_property -dict { PACKAGE_PIN E4 IOSTANDARD LVCMOS12 } [get_ports TFT_HSYNC*] ;
set_property -dict { PACKAGE_PIN F1 IOSTANDARD LVCMOS12 } [get_ports TFT_VSYNC*] ;
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS12 } [get_ports TFT_DE*] ;
set_property -dict { PACKAGE_PIN E1 IOSTANDARD LVCMOS12 } [get_ports TFT_BACKLIGHT*] ;
###### TFT LCD RGB Data Pins
set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS12 } [get_ports TFT_R_DATA*[4]] ;
set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS12 } [get_ports TFT_R_DATA*[3]] ;
set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS12 } [get_ports TFT_R_DATA*[2]] ;
set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS12 } [get_ports TFT_R_DATA*[1]] ;
set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS12 } [get_ports TFT_R_DATA*[0]] ;
set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS12 } [get_ports TFT_G_DATA*[5]] ;
set_property -dict { PACKAGE_PIN M5 IOSTANDARD LVCMOS12 } [get_ports TFT_G_DATA*[4]] ;
set_property -dict { PACKAGE_PIN M4 IOSTANDARD LVCMOS12 } [get_ports TFT_G_DATA*[3]] ;
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS12 } [get_ports TFT_G_DATA*[2]] ;
set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS12 } [get_ports TFT_G_DATA*[1]] ;
set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS12 } [get_ports TFT_G_DATA*[0]] ;
set_property -dict { PACKAGE_PIN N2 IOSTANDARD LVCMOS12 } [get_ports TFT_B_DATA*[4]] ;
set_property -dict { PACKAGE_PIN P1 IOSTANDARD LVCMOS12 } [get_ports TFT_B_DATA*[3]] ;
set_property -dict { PACKAGE_PIN N5 IOSTANDARD LVCMOS12 } [get_ports TFT_B_DATA*[2]] ;
set_property -dict { PACKAGE_PIN N4 IOSTANDARD LVCMOS12 } [get_ports TFT_B_DATA*[1]] ;
set_property -dict { PACKAGE_PIN M2 IOSTANDARD LVCMOS12 } [get_ports TFT_B_DATA*[0]] ;

###### OV5640 CIS Camera Pins
set_property -dict { PACKAGE_PIN G5 IOSTANDARD LVCMOS18 } [get_ports CAMERA_PCLK*] ;
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -hierarchical -filter {NAME =~ "*CAMERA_PCLK"}] ;
set_property -dict { PACKAGE_PIN A7 IOSTANDARD LVCMOS18 } [get_ports *tri_o*[1]] ;#CAMERA_PWDN
set_property -dict { PACKAGE_PIN A6 IOSTANDARD LVCMOS18 } [get_ports *tri_o*[0]] ;#CAMERA_RESETn
set_property -dict { PACKAGE_PIN E6 IOSTANDARD LVCMOS18 } [get_ports *scl*] ;#CAMERA_SCCB_SCL
set_property -dict { PACKAGE_PIN G6 IOSTANDARD LVCMOS18 } [get_ports *sda*] ;#CAMERA_SCCB_SDA
set_property -dict { PACKAGE_PIN F7 IOSTANDARD LVCMOS18 } [get_ports CAMERA_HSYNC*] ;
set_property -dict { PACKAGE_PIN G7 IOSTANDARD LVCMOS18 } [get_ports CAMERA_VSYNC*] ;
set_property -dict { PACKAGE_PIN F6 IOSTANDARD LVCMOS18 } [get_ports CAMERA_MCLK*] ;
set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[0]] ;
set_property -dict { PACKAGE_PIN D6 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[1]] ;
set_property -dict { PACKAGE_PIN D5 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[2]] ;
set_property -dict { PACKAGE_PIN C7 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[3]] ;
set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[4]] ;
set_property -dict { PACKAGE_PIN C5 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[5]] ;
set_property -dict { PACKAGE_PIN E8 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[6]] ;
set_property -dict { PACKAGE_PIN D8 IOSTANDARD LVCMOS18 } [get_ports CAMERA_DATA*[7]] ;


###### LED, Push Button, Slide Switch
#set_property -dict { PACKAGE_PIN D8 IOSTANDARD LVCMOS18 } [get_ports LED*[0]] ;
#set_property -dict { PACKAGE_PIN E8 IOSTANDARD LVCMOS18 } [get_ports LED*[1]] ;
#set_property -dict { PACKAGE_PIN C5 IOSTANDARD LVCMOS18 } [get_ports LED*[2]] ;
#set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS18 } [get_ports LED*[3]] ;
#set_property -dict { PACKAGE_PIN A6 IOSTANDARD LVCMOS18 } [get_ports SLIDE_SWITCH*[3]] ;
#set_property -dict { PACKAGE_PIN A7 IOSTANDARD LVCMOS18 } [get_ports SLIDE_SWITCH*[2]] ;
#set_property -dict { PACKAGE_PIN G6 IOSTANDARD LVCMOS18 } [get_ports SLIDE_SWITCH*[1]] ;
# set_property -dict { PACKAGE_PIN E6 IOSTANDARD LVCMOS18 } [get_ports SLIDE_SWITCH*[0]] ;
#set_property -dict { PACKAGE_PIN F8 IOSTANDARD LVCMOS18 } [get_ports PUSH_BTN*[4]] ;
#set_property -dict { PACKAGE_PIN F7 IOSTANDARD LVCMOS18 } [get_ports PUSH_BTN*[3]] ;
#set_property -dict { PACKAGE_PIN G7 IOSTANDARD LVCMOS18 } [get_ports PUSH_BTN*[2]] ;
#set_property -dict { PACKAGE_PIN F6 IOSTANDARD LVCMOS18 } [get_ports PUSH_BTN*[1]] ;
#set_property -dict { PACKAGE_PIN G5 IOSTANDARD LVCMOS18 } [get_ports PUSH_BTN*[0]] ;

###### Motor
#set_property -dict { PACKAGE_PIN J5 IOSTANDARD LVCMOS12 } [get_ports MOTOR*[3]] ;
#set_property -dict { PACKAGE_PIN H5 IOSTANDARD LVCMOS12 } [get_ports MOTOR*[2]] ;
#set_property -dict { PACKAGE_PIN G1 IOSTANDARD LVCMOS12 } [get_ports MOTOR*[1]] ;
#set_property -dict { PACKAGE_PIN F1 IOSTANDARD LVCMOS12 } [get_ports MOTOR*[0]] ;

###### Ultra Sonic
#set_property -dict { PACKAGE_PIN E4 IOSTANDARD LVCMOS12 } [get_ports ECHO*] ;
#set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS12 } [get_ports TRIG*] ;

###### SPI Bus (ADC0: Photo Register(CdS_GL5549), ADC1: Thermometor(LM35DM), ADC2~ADC7: ADC(BH2715FV))
#set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS18 } [get_ports *sck*] ;#SCK
#set_property -dict { PACKAGE_PIN D6 IOSTANDARD LVCMOS18 } [get_ports *io0*] ;#MISO
#set_property -dict { PACKAGE_PIN D5 IOSTANDARD LVCMOS18 } [get_ports *io1*] ;#MOSI
#set_property -dict { PACKAGE_PIN C7 IOSTANDARD LVCMOS18 } [get_ports *ss*] ;#CS or SS

###### PS UART1 (UART0 is not Connected)
#set_property -dict { PACKAGE_PIN MIO1 IOSTANDARD LVCMOS18 } [get_ports UART1_RX] ;
#set_property -dict { PACKAGE_PIN MIO0 IOSTANDARD LVCMOS18 } [get_ports UART1_TX] ;

###### PS SPI
#set_property -dict { PACKAGE_PIN MIO41 IOSTANDARD LVCMOS18 } [get_ports SPI0_CS]  ;
#set_property -dict { PACKAGE_PIN MIO38 IOSTANDARD LVCMOS18 } [get_ports SPI0_SCLK] ;
#set_property -dict { PACKAGE_PIN MIO42 IOSTANDARD LVCMOS18 } [get_ports SPI0_MISO] ;
#set_property -dict { PACKAGE_PIN MIO43 IOSTANDARD LVCMOS18 } [get_ports SPI0_MOSI] ;
#set_property -dict { PACKAGE_PIN MIO9 IOSTANDARD LVCMOS18 } [get_ports SPI1_CS] ;
#set_property -dict { PACKAGE_PIN MIO6 IOSTANDARD LVCMOS18 } [get_ports SPI1_SCLK] ;
#set_property -dict { PACKAGE_PIN MIO10 IOSTANDARD LVCMOS18 } [get_ports SPI1_MISO] ;
#set_property -dict { PACKAGE_PIN MIO11 IOSTANDARD LVCMOS18 } [get_ports SPI1_MOSI] ;

###### PS I2C 1/2 (It is tied to I2C bus )
#set_property -dict { PACKAGE_PIN MIO4 IOSTANDARD LVCMOS18 } [get_ports SCL] ; #I2C 1/2 SCL
#set_property -dict { PACKAGE_PIN MIO5 IOSTANDARD LVCMOS18 } [get_ports SDA] ; #I2C 1/2 SDA 

###### PS GPIO
#set_property -dict { PACKAGE_PIN MIO36 IOSTANDARD LVCMOS18 } [get_ports GPIO0] ;
#set_property -dict { PACKAGE_PIN MIO37 IOSTANDARD LVCMOS18 } [get_ports GPIO1] ;
#set_property -dict { PACKAGE_PIN MIO39 IOSTANDARD LVCMOS18 } [get_ports GPIO2] ;
#set_property -dict { PACKAGE_PIN MIO40 IOSTANDARD LVCMOS18 } [get_ports GPIO3] ;
#set_property -dict { PACKAGE_PIN MIO44 IOSTANDARD LVCMOS18 } [get_ports GPIO4] ;
#set_property -dict { PACKAGE_PIN MIO45 IOSTANDARD LVCMOS18 } [get_ports GPIO5] ;