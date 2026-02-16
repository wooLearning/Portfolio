/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2024 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
//#define BUTMAX 4
#define MAXFLOOR 3
#define DECREASE 2
#define SPEEDINIT 20
#define STEP 135
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
TIM_HandleTypeDef htim2;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
uint16_t led_pin_up[] = {LEDUP1_Pin,LEDUP2_Pin,0};
uint16_t led_pin_down[] = {0,LEDDN2_Pin,LEDDN3_Pin};
uint16_t led_pin_f[] = {LEDF1_Pin,LEDF2_Pin,LEDF3_Pin};
GPIO_TypeDef *led_port_up[] = {LEDUP1_GPIO_Port,LEDUP2_GPIO_Port,0};
GPIO_TypeDef *led_port_down[] = {0,LEDDN2_GPIO_Port,LEDDN3_GPIO_Port};
GPIO_TypeDef *led_port_f[] = {LEDF1_GPIO_Port,LEDF2_GPIO_Port,LEDF3_GPIO_Port};

uint16_t seg_pin[] = {SEGA_Pin,SEGB_Pin,SEGC_Pin,SEGD_Pin,SEGE_Pin,SEGG_Pin};
GPIO_TypeDef *seg_port[] = {SEGA_GPIO_Port,SEGB_GPIO_Port,SEGC_GPIO_Port,SEGD_GPIO_Port,SEGE_GPIO_Port,SEGG_GPIO_Port};
const int num[3][6] = {
  {0, 1, 1, 0, 0, 0},  // 1
  {1, 1, 0, 1, 1, 1},  // 2
  {1, 1, 1, 1, 0, 1},  // 3
};


int upButton[MAXFLOOR] = {0};//up down button state outside
int downButton[MAXFLOOR]={0};
int fButton[MAXFLOOR] = {0};//floor button state inside
int direction = 0;//0: stop 1: up 2: down
int currentFloor=1;
int targetFloor = 1;
int stepNumber=1;
float speed=SPEEDINIT;
int totalSteps=0;//floor detect 57:1 114:2 171:3
int motorEn=0;


//int targetFloors[7] ={0};
//int a=0;
//int b=0;


//uint8_t sen1 = "SENSOR1\n";
//uint8_t sen2 = "SENSOR2\n";
//uint8_t sen3 = "SENSOR3\n";
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_TIM2_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

void input_button(){
  if(HAL_GPIO_ReadPin(SWUP1_GPIO_Port,SWUP1_Pin)){//up1
	   	HAL_Delay(100);
	   	HAL_GPIO_WritePin(led_port_up[0],led_pin_up[0],!upButton[0]);
	   	upButton[0] = !upButton[0];
	  	while(HAL_GPIO_ReadPin(SWUP1_GPIO_Port,SWUP1_Pin)){;}
	  	HAL_Delay(100);
	  }

  if(HAL_GPIO_ReadPin(SWUP2_GPIO_Port,SWUP2_Pin)){//up2
    HAL_Delay(100);
    HAL_GPIO_WritePin(led_port_up[1],led_pin_up[1],!upButton[1]);
    upButton[1] = !upButton[1];
    while(HAL_GPIO_ReadPin(SWUP2_GPIO_Port,SWUP2_Pin)){;}
    HAL_Delay(100);
  }

  if(HAL_GPIO_ReadPin(SWDN2_GPIO_Port,SWDN2_Pin)){//down2
    HAL_Delay(100);
    HAL_GPIO_WritePin(led_port_down[1],led_pin_down[1],!downButton[1]);
    downButton[1] = !downButton[1];
    while(HAL_GPIO_ReadPin(SWDN2_GPIO_Port,SWDN2_Pin)){;}
    HAL_Delay(100);
  }

  if(HAL_GPIO_ReadPin(SWDN3_GPIO_Port,SWDN3_Pin)){//down3
    HAL_Delay(100);
    HAL_GPIO_WritePin(led_port_down[2],led_pin_down[2],!downButton[2]);
    downButton[2] = !downButton[2];
    while(HAL_GPIO_ReadPin(SWDN3_GPIO_Port,SWDN3_Pin)){;}
    HAL_Delay(100);
  }

  if(HAL_GPIO_ReadPin(SWF1_GPIO_Port,SWF1_Pin)){//f1
    HAL_Delay(100);
    HAL_GPIO_WritePin(led_port_f[0],led_pin_f[0],!fButton[0]);
    fButton[0] = !fButton[0];
    while(HAL_GPIO_ReadPin(SWF1_GPIO_Port,SWF1_Pin)){;}
    HAL_Delay(100);
  }

  if(HAL_GPIO_ReadPin(SWF2_GPIO_Port,SWF2_Pin)){//f2
    HAL_Delay(100);
    HAL_GPIO_WritePin(led_port_f[1],led_pin_f[1],!fButton[1]);
    fButton[1] = !fButton[1];
    while(HAL_GPIO_ReadPin(SWF2_GPIO_Port,SWF2_Pin)){;}
    HAL_Delay(100);
  }

  if(HAL_GPIO_ReadPin(SWF3_GPIO_Port,SWF3_Pin)){//f3
    HAL_Delay(100);
    HAL_GPIO_WritePin(led_port_f[2],led_pin_f[2],!fButton[2]);
    fButton[2] = !fButton[2];
    while(HAL_GPIO_ReadPin(SWF3_GPIO_Port,SWF3_Pin)){;}
    HAL_Delay(100);
  }
}
int button_check(){
  int i=currentFloor-1; //current index
  if(direction==0){
    while(i<MAXFLOOR){
        if(upButton[i]||downButton[i]||fButton[i]){
            return i+1;
        }
        i++;
    }
    i = currentFloor-1; //upstarit recheck
    while(i>=0){
        if(upButton[i]||downButton[i]||fButton[i]){
            return i+1;
        }
        i--;
    }
  }
  else if(direction==1){//when going up state
    while(i<MAXFLOOR){
        if(upButton[i]||fButton[i]){
            return i+1;
        }
        i++;

    }
  }
  else{//direction==2 going down state
    while(i>=0){
        if(downButton[i]||fButton[i]){
            return  i+1;
        }
        i--;
    }
  }
  direction=0;
 // HAL_UART_Transmit(&huart2,"00000000\n",sizeof("00000000\n"),100);
  return currentFloor;
}

void led_check(){
  if(direction==1){
    if(upButton[currentFloor-1]){
    HAL_Delay(1000);
      upButton[currentFloor-1] = 0;
      HAL_GPIO_WritePin(led_port_up[currentFloor-1],led_pin_up[currentFloor-1],0);
    }
    direction=2;
  }else if(direction==2){

    if(downButton[currentFloor-1]){
      HAL_Delay(1000);
      downButton[currentFloor-1] = 0;
      HAL_GPIO_WritePin(led_port_down[currentFloor-1],led_pin_down[currentFloor-1],0);
    }
    direction=1;
  }else{//direction == 0
    if(upButton[currentFloor-1]){
	  HAL_Delay(1000);
	  upButton[currentFloor-1] = 0;
	  HAL_GPIO_WritePin(led_port_up[currentFloor-1],led_pin_up[currentFloor-1],0);

    }
    if(downButton[currentFloor-1]){
		HAL_Delay(1000);
		downButton[currentFloor-1] = 0;
		HAL_GPIO_WritePin(led_port_down[currentFloor-1],led_pin_down[currentFloor-1],0);
    }
  }
  if(fButton[currentFloor-1]){
	  HAL_Delay(1000);
      fButton[currentFloor-1] = 0;
      HAL_GPIO_WritePin(led_port_f[currentFloor-1],led_pin_f[currentFloor-1],0);
  }
}

void motor_on(){
	motorEn=1;
    switch (stepNumber)
    {
    case 1:
		  HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 1);   // IN1
		  HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin,0); // IN2
		  HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin,0); // IN3
		  HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 1);   // IN4
		  HAL_Delay(5);
		break;
	  case 2:
		  HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 1);   // IN1
		  HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin,0); // IN2
		  HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 1);   // IN3
		  HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin,0); // IN4
		  HAL_Delay(5);
		break;
	  case 3:
		  HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin,0); // IN1
		  HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 1);   // IN2
		  HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 1);   // IN3
		  HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin,0); // IN4
		  HAL_Delay(5);
		break;
	  case 4:
		  HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin,0); // IN1
		  HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 1);   // IN2
		  HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin,0); // IN3
		  HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 1);   // IN4
		  HAL_Delay(5);
		break;
      default:
        break;
    }
}
void motor_off()
{
	motorEn=0;
	HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 0); // IN1
	HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 0); // IN2
	HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 0); // IN3
	HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 0); // IN4
}
void motor_delay(uint32_t delay){
//    if (delay < 60000)
//    {
//        __HAL_TIM_SET_COUNTER(&htim2, 0);
//        while (__HAL_TIM_GET_COUNTER(&htim2) < delay);
//    }
//    else
//    {
//        HAL_Delay(delay/1000);//limit lowest speed
//    }
	__HAL_TIM_SET_COUNTER(&htim2, 0);
	while (__HAL_TIM_GET_COUNTER(&htim2) < delay);

}

void up_floor(){//wheel r = 2.5cm floor step=4.5cm so 57cycle need to go up 1 floor
	motor_on();
	uint32_t delay = 60*1000*1000/200/speed;
	for(int x=0; x<STEP; x++){
		input_button();
		totalSteps++;
	// Step to the previous step
		switch (stepNumber){//counter clock wise
		case 1:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 0); // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 1);   // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 0); // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 1);   // IN4
			motor_delay(delay);
			stepNumber = 4;
			break;
		  case 2:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 1);   // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 0); // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 0); // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 1);   // IN4
			motor_delay(delay);
			stepNumber = 1;
			break;
		  case 3:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 1);   // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 0); // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 1);   // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 0); // IN4
			motor_delay(delay);
			stepNumber = 2;
			break;
		  case 4:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 0); // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 1);   // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 1);   // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 0); // IN4
			motor_delay(delay);
			stepNumber = 3;
			break;
		  default:
			break;
		}
		delay = 60*1000*1000/200/speed;
		if(x>=STEP-5){
			speed  = speed - DECREASE;
		}

	}
	speed = SPEEDINIT;
	motor_off();
}
void down_floor(){//wheel r = 2.5cm floor step=4.5cm so 57cycle need to go up 1 floor
	motor_on();
	uint32_t delay = 60*1000*1000/200/speed;
	for(int x=0; x<STEP; x++)
	  {
		input_button();
		totalSteps--;
	    // Step to the next step
	    switch (stepNumber){
	    case 1:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin,1);   // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 0); // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin,1);   // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 0); // IN4
			motor_delay(delay);
			stepNumber = 2;
			break;
		  case 2:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 0); // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin,1);   // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin,1);   // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 0); // IN4
			motor_delay(delay);
			stepNumber = 3;
			break;
		  case 3:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 0); // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin,1);   // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 0); // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 1); // IN4 checking required
			motor_delay(delay);
			stepNumber = 4;
			break;
		  case 4:
			HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin,1);   // IN1
			HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 0); // IN2
			HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 0); // IN3
			HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin,1);   // IN4
			motor_delay(delay);
			stepNumber = 1;
			break;
		  default:
			break;
	    }
	    delay = 60*1000*1000/200/speed;
	    if(x>=STEP-5){
			speed  = speed - DECREASE;
		}
	  }
	speed=SPEEDINIT;
	motor_off();
}
void go_floor(int targetFloor){//move to targetfloor
  while(targetFloor > currentFloor){
	  direction = 1;
	  up_floor();
	  update_currentFloor();
	  display_floor();
  }
  while(targetFloor < currentFloor){
	 direction = 2;
     down_floor();
     update_currentFloor();
     display_floor();
  }

}
// HAL_UART_Transmit(&huart2,"1111111\n",sizeof("11111111\n"),100);
void update_currentFloor(){
  switch (totalSteps)
  {
  case STEP: currentFloor = 1;
    break;
  case STEP*2: currentFloor = 2;
    break;
   case STEP*3: currentFloor = 3;
    break;
  default: break;

  }

}

void display_floor(){
	int i=0;
	for (i = 0; i < 6; i++) {
	   HAL_GPIO_WritePin(seg_port[i], seg_pin[i], num[currentFloor-1][i]);
	}
}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */
	//uint16_t value = 0;
  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART2_UART_Init();
  MX_TIM2_Init();
  /* USER CODE BEGIN 2 */
  HAL_TIM_Base_Start(&htim2);


  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1){//HAL_UART_Transmit(&huart2,"SENSOR\n",sizeof("SENSOR\n"),100);//HAL_UART_Transmit(&huart2,"dn3\n",sizeof("dn3\n"),100);
	input_button();
	led_check();
	targetFloor = button_check();
	go_floor(targetFloor);
	display_floor();

    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_BYPASS;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 72-1;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = 65535;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim2) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM2_Init 2 */

  /* USER CODE END TIM2_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
/* USER CODE BEGIN MX_GPIO_Init_1 */
/* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOC, LEDUP1_Pin|LEDUP2_Pin|LEDDN2_Pin|LEDDN3_Pin
                          |SEGG_Pin|SWF3_Pin|SWF2_Pin|LEDF1_Pin
                          |LEDF2_Pin|LEDF3_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, SEGE_Pin|SEGD_Pin|SEGC_Pin|SEGB_Pin
                          |SEGA_Pin|IN1_Pin|IN2_Pin|IN3_Pin
                          |IN4_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pins : LEDUP1_Pin LEDUP2_Pin LEDDN2_Pin SEGG_Pin
                           SWF3_Pin SWF2_Pin LEDF1_Pin LEDF2_Pin */
  GPIO_InitStruct.Pin = LEDUP1_Pin|LEDUP2_Pin|LEDDN2_Pin|SEGG_Pin
                          |SWF3_Pin|SWF2_Pin|LEDF1_Pin|LEDF2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : LEDDN3_Pin LEDF3_Pin */
  GPIO_InitStruct.Pin = LEDDN3_Pin|LEDF3_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pin : LD2_Pin */
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pins : SEGE_Pin SEGD_Pin SEGC_Pin SEGB_Pin
                           SEGA_Pin */
  GPIO_InitStruct.Pin = SEGE_Pin|SEGD_Pin|SEGC_Pin|SEGB_Pin
                          |SEGA_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pins : SENSOR1_Pin SENSOR2_Pin SENSOR3_Pin */
  GPIO_InitStruct.Pin = SENSOR1_Pin|SENSOR2_Pin|SENSOR3_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pins : SWF1_Pin SWDN3_Pin SWDN2_Pin SWUP2_Pin
                           SWUP1_Pin */
  GPIO_InitStruct.Pin = SWF1_Pin|SWDN3_Pin|SWDN2_Pin|SWUP2_Pin
                          |SWUP1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : IN1_Pin IN2_Pin IN3_Pin IN4_Pin */
  GPIO_InitStruct.Pin = IN1_Pin|IN2_Pin|IN3_Pin|IN4_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

/* USER CODE BEGIN MX_GPIO_Init_2 */
/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
	//if(GPIO_Pin == SW0_Pin){
		//HAL_Delay(100);
//		if(GPIO_Pin == SW0_Pin){
//			  if(led_state[0] == 1){
//				  led_state[0] = 0;
//				  HAL_UART_Transmit(&huart2,"A\n",sizeof("A\n"),100);
//			  }
//			  else{
//				  led_state[0] = 1;
//				  HAL_UART_Transmit(&huart2,"B\n",sizeof("A\n"),100);
//			  }
//		}

	  //HAL_GPIO_TogglePin(LED0_GPIO_Port, LED0_Pin);
	  //HAL_Delay(10);
  //}



	// if(GPIO_Pin == SENSOR1_Pin ){
	// 	// HAL_UART_Transmit(&huart2,"SENSOR1111\n",sizeof("SENSOR1111\n"),100);
	// 	 currentFloor=1;
	// }
	// if(GPIO_Pin == SENSOR2_Pin ){
	// 	//HAL_UART_Transmit(&huart2,"SENSOR2222\n",sizeof("SENSOR2222\n"),100);
	// 	currentFloor=2;
	// }
	// if(GPIO_Pin == SENSOR3_Pin ){
	// 	//HAL_UART_Transmit(&huart2,"SENSOR3333\n",sizeof("SENSOR3333\n"),100);
	// 	currentFloor=3;
	// }
}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
