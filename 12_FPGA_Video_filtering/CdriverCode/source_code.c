#include <stdio.h>
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_io.h"
#include <xparameters.h>
#include <unistd.h>
#include <stdint.h> // uintptr_t 사용을 위해 필요 (UINTPTR을 쓰면 xil_types.h 덕분에 생략 가능)
#include "xiic.h"
#include "xil_printf.h"
#include "CamConfigData.h"  //SCCB 인터페이스 (I2C와 유사)을 통하여 CAM 모듈(OmniVision사, OV5640)의 레지스터에 넣어줄 레지스터 오프셋과 값

/* For UART Config start */
#ifdef STDOUT_IS_16550
 #include "xuartns550_l.h"
 #define UART_BAUD 9600
#endif


#define IIC_DEVICE_ID      0
#define OV5640_IIC_ADDR    0x78  // 8bit 기준: 0x78=Write, 0x79=Read → 드라이버에는 7bit로 전달: 0x3C(Write) 0x3E(Read)
#define AXI_IIC_ADDRESS    0xA0010000
#define AXI_GPIO_ADDRESS   0xA0000000
#define ADDR        0xA0020000
XIic Iic;

void enable_caches() {
#ifdef __PPC__
    Xil_ICacheEnableRegion(CACHEABLE_REGION_MASK);
    Xil_DCacheEnableRegion(CACHEABLE_REGION_MASK);
#elif __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheEnable();
#endif
#endif
}

void disable_caches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheDisable();
#endif
#endif
}

void init_uart() {
#ifdef STDOUT_IS_16550
    XUartNs550_SetBaud(STDOUT_BASEADDR, XPAR_XUARTNS550_CLOCK_HZ, UART_BAUD);
    XUartNs550_SetLineControlReg(STDOUT_BASEADDR, XUN_LCR_8_DATA_BITS);
#endif
}

void init_platform() {
    enable_caches();
    init_uart();
}

void cleanup_platform() {
    disable_caches();
}


// SCCB 방식의 레지스터 Write (16bit Address + 8bit Data)
int SCCB_WriteRegister(u16 reg, u8 data) {
    u8 buf[3];
    int Status;

    buf[0] = (reg >> 8) & 0xFF;  // High byte
    buf[1] = reg & 0xFF;         // Low byte
    buf[2] = data;

    Status = XIic_Send(AXI_IIC_ADDRESS, OV5640_IIC_ADDR >> 1, buf, 3, XIIC_STOP);//Xilinx API, 입력 인자들에 대한 정보는 사이트 참고바람
    if (Status != 3) {
        xil_printf("SCCB Write Error: reg=0x%04X, data=0x%02X, Status=%d\r\n", reg, data, Status);
        return XST_FAILURE;
    }

    while (XIic_IsIicBusy(AXI_IIC_ADDRESS));
    return XST_SUCCESS;
}

// OV5640 전체 초기화 시퀀스
int Initialize_OV5640() {
    int status;
    extern const iic_ov5640_t Config[];

    int num_regs = sizeof(Config) / sizeof(Config[0]);;//CamConfigData.h에 있는 데이터 갯수 파악
    for (int i = 0; i < num_regs; i++) {
        status = SCCB_WriteRegister(Config[i].RegOffset, Config[i].RegData);
        if (status != XST_SUCCESS) {
            xil_printf("Failed at index %d, Reg=0x%04X\r\n", i, Config[i].RegOffset);
            return status;
        }
    }

    xil_printf("OV5640 Initialization complete. %d registers written.\r\n", num_regs);
    return XST_SUCCESS;
}

void user_interface(){
    int i = 0;
    int mode;
    int arr[9]; // 음수 입력을 위해 int 사용
    int start = 0;
    
    // 주소 변수 타입을 64비트 호환 타입으로 변경
    UINTPTR addr; 
    while(1){
        i = 0;
        addr = ADDR; // 0xA0000000
        start = 0;
        printf("choose mode : 0, 1, 2, 3\n");
        scanf("%d", &mode);
        printf("your mode : %d\n", mode);

        Xil_Out32(addr, mode);
        

        if(mode == 0){//sharp
            printf("%3d %3d %3d\n",  0, -1,  0);
            printf("%3d %3d %3d\n", -1,  5, -1);
            printf("%3d %3d %3d\n",  0, -1,  0);
        } else if(mode == 1){//more sharp
            printf("%3d %3d %3d\n", -1, -1, -1);
            printf("%3d %3d %3d\n", -1,  9, -1);
            printf("%3d %3d %3d\n", -1, -1, -1);
        } else if(mode == 2){//bypass
            printf("%3d %3d %3d\n",  0, 0, 0);
            printf("%3d %3d %3d\n",  0, 1, 0);
            printf("%3d %3d %3d\n",  0, 0, 0);
        } else if(mode == 3){
            printf("input your filter 9 (integers allowed)\n");
            
            while(i < 9){
                scanf("%d", &arr[i]);
                i++;
            }

            for(i = 0; i < 9; i++){
                if(i > 0 && i % 3 == 0) printf("\n");
                printf("%3d ", arr[i]);
            }
            printf("\n-----------\n");

            // 필터 값 전송
            for(i = 0; i < 2; i++){
                addr += 4;
                *(volatile unsigned int*)(addr) = 
                    ((unsigned int)(arr[i*4]   & 0xFF))       | 
                    ((unsigned int)(arr[i*4+1] & 0xFF) << 8)  | 
                    ((unsigned int)(arr[i*4+2] & 0xFF) << 16) | 
                    ((unsigned int)(arr[i*4+3] & 0xFF) << 24);
            }
            addr += 4;
            *(volatile unsigned int*)(addr) = (unsigned int)(arr[8] & 0xFF);

        }
    }
}

int main() {
    

    init_platform();
     *(volatile unsigned int*)(AXI_GPIO_ADDRESS) = 0x2; // GPIO에 값을 쓰기 ; PWDN 1, Resetn : 0
    usleep(1000);//1ms 정도 쉬어준 후, RESET_N핀에 high(1)을 넣어 리셋을 풀어줌. OV5640 데이터시트, figure 2-3 power up timing with internal DVDD 그림 참조바람, 
    *(volatile unsigned int*)(AXI_GPIO_ADDRESS) = 0x1; // GPIO에 값을 쓰기 ; PWDN 0, Resetn : 1
    usleep(20000);//리셋을 풀고 20ms 정도 쉬어준 후 데이터를 쓸 수 있음.

    XIic_Config *IicConfig;//AXI IIC (Vivado Xilinx IP) 개체 호출
    int Status;

    IicConfig = XIic_LookupConfig(IIC_DEVICE_ID);//AXI IIC 내부 레지스터 정보 즉, Vivado 프로젝트에서 설정한 정보들 불러오기 (ex AXI IIC의 Base address, GPIO 의 Width, I2C 동작속도 및 기타 모드 설정값..)
    if (IicConfig == NULL) {
        xil_printf("IIC configuration not found!\r\n");
        return XST_FAILURE;
    }

    Status = XIic_CfgInitialize(&Iic, IicConfig, IicConfig->BaseAddress);//XIiC_LookupConfig함수를 통해 받은 AXI IIC의 데이터를 담긴 포인터로 불러오기
    if (Status != XST_SUCCESS) {
        xil_printf("IIC initialization failed!\r\n");
        return XST_FAILURE;
    }

    
    XIic_Start(&Iic);// Bus master mode 설정
    XIic_SetAddress(&Iic, XII_ADDR_TO_SEND_TYPE, OV5640_IIC_ADDR >> 1);

    // 초기화 시작
    Status = Initialize_OV5640();
    if (Status != XST_SUCCESS) {
        xil_printf("OV5640 configuration failed.\r\n");
        return XST_FAILURE;
    }
    SCCB_WriteRegister(0x3820, 0x40);
    SCCB_WriteRegister(0x4300, 0x62);
    XIic_Stop(&Iic);
    xil_printf("DONE\r\n");
    
    user_interface();
    cleanup_platform();
    return 0;
}