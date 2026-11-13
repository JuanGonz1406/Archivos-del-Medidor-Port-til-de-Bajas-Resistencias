#line 1 "C:/Users/camil/OneDrive/Escritorio/UIS/2026_2/Diseño de circ/Proyecto medición de resistencias/Programacion del PIC/Programacion_PIC.c"
#line 46 "C:/Users/camil/OneDrive/Escritorio/UIS/2026_2/Diseño de circ/Proyecto medición de resistencias/Programacion del PIC/Programacion_PIC.c"
unsigned int app_seq_counter = 0;
unsigned short app_low_bat_latch = 0;

char app_num_buffer[7];
char app_cmd_buffer[120];

void App_UART_SendUInt(unsigned int number_val)
{
 unsigned short idx = 0;
 WordToStr(number_val, app_num_buffer);
 while(app_num_buffer[idx] == ' ')
 {
 idx++;
 }
 UART1_Write_Text(&app_num_buffer[idx]);
}

void App_ESP_SendLine(char *text_line)
{
 UART1_Write_Text(text_line);
 UART1_Write(13);
 UART1_Write(10);
}

void App_ESP_ClearBuffer()
{
 while(UART1_Data_Ready())
 {
 UART1_Read();
 }
}

unsigned short App_ESP_WaitFor(char *expected_str, unsigned int timeout_ms)
{
 unsigned short match_pos = 0;
 unsigned short exp_len;
 char rx_char;

 exp_len = strlen(expected_str);

 while(timeout_ms > 0)
 {
 if(UART1_Data_Ready())
 {
 rx_char = UART1_Read();
 if(rx_char == expected_str[match_pos])
 {
 match_pos++;
 if(match_pos == exp_len)
 {
 return 1;
 }
 }
 else if(rx_char == expected_str[0])
 {
 match_pos = 1;
 }
 else
 {
 match_pos = 0;
 }
 }
 Delay_ms(1);
 timeout_ms--;
 }
 return 0;
}
#line 118 "C:/Users/camil/OneDrive/Escritorio/UIS/2026_2/Diseño de circ/Proyecto medición de resistencias/Programacion del PIC/Programacion_PIC.c"
void App_ESP_InitUDP()
{
 UART1_Write_Text("+++");
 Delay_ms(500);
 App_ESP_ClearBuffer();

 App_ESP_SendLine("AT");
 App_ESP_WaitFor("OK", 400);

 App_ESP_SendLine("ATE0");
 App_ESP_WaitFor("OK", 400);

 App_ESP_SendLine("AT+CWMODE=1");
 App_ESP_WaitFor("OK", 400);

 App_ESP_SendLine("AT+CIPMUX=0");
 App_ESP_WaitFor("OK", 400);

 strcpy(app_cmd_buffer, "AT+CWJAP=\"");
 strcat(app_cmd_buffer,  "iPhone de Santiago" );
 strcat(app_cmd_buffer, "\",\"");
 strcat(app_cmd_buffer,  "pagueinternet" );
 strcat(app_cmd_buffer, "\"");
 App_ESP_SendLine(app_cmd_buffer);
 App_ESP_WaitFor("OK", 1500);

 App_ESP_SendLine("AT+CIPCLOSE");
 App_ESP_WaitFor("OK", 300);

 strcpy(app_cmd_buffer, "AT+CIPSTART=\"UDP\",\"");
 strcat(app_cmd_buffer,  "255.255.255.255" );
 strcat(app_cmd_buffer, "\",4210,4210,0");
 App_ESP_SendLine(app_cmd_buffer);
 App_ESP_WaitFor("OK", 500);

 App_ESP_SendLine("AT+CIPMODE=1");
 App_ESP_WaitFor("OK", 400);

 App_ESP_SendLine("AT+CIPSEND");
 App_ESP_WaitFor(">", 400);
}

unsigned int App_ADC_Average32(unsigned short channel)
{
 unsigned short i;
 unsigned long acc = 0;

 ADC_Read(channel);
 Delay_us(100);

 for(i = 0; i < 32; i++)
 {
 acc += ADC_Read(channel);
 Delay_us(100);
 }

 return (unsigned int)(acc >> 5);
}

void App_HardwareInit()
{
 OSCCON = 0x72;
 Delay_ms(20);

 LATA = 0x00; LATB = 0x00; LATC = 0x00; LATD = 0x00; LATE = 0x00;

 ANCON0 = 0x03;
 ANCON1 = 0x00;

 CM1CON = 0x00;
 CM2CON = 0x00;

 TRISA.B0 = 1;
 TRISA.B1 = 1;
 TRISB.B0 = 1;
 TRISC.B6 = 0;
 TRISC.B7 = 1;
 TRISD.B0 = 0;

 LATD.B0 = 0;

 ADC_Init();
 Delay_ms(10);

 UART1_Init(115200);
 Delay_ms(200);
}

void main()
{
 unsigned int adc_an0_bat;
 unsigned int adc_an1_res;
 unsigned short rb0_level;
 unsigned short med_en_state;

 App_HardwareInit();
 App_ESP_InitUDP();

 while(1)
 {

 adc_an0_bat = App_ADC_Average32(0);
 rb0_level = (PORTB.B0 == 0) ? 0 : 1;


 if(adc_an0_bat <=  2321 )
 {
 app_low_bat_latch = 1;
 }
 else if(adc_an0_bat >=  2457 )
 {
 app_low_bat_latch = 0;
 }


 if((rb0_level == 0) || (app_low_bat_latch == 1))
 {
 LATD.B0 = 0;
 med_en_state = 0;
 adc_an1_res = 0;
 }
 else
 {
 med_en_state = 1;
 LATD.B0 = 1;
 Delay_ms(10);
 adc_an1_res = App_ADC_Average32(1);
 LATD.B0 = 0;
 }


 UART1_Write_Text("D:");
 App_UART_SendUInt(app_seq_counter++);
 UART1_Write(',');
 App_UART_SendUInt(adc_an0_bat);
 UART1_Write(',');
 App_UART_SendUInt(adc_an1_res);
 UART1_Write(',');
 UART1_Write(rb0_level ? '1' : '0');
 UART1_Write(',');
 UART1_Write(med_en_state ? '1' : '0');
 UART1_Write(10);

 Delay_ms(300);
 }
}
