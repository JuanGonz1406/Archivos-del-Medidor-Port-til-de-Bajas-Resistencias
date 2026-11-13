/*
 * =============================================================
 * MEDIDOR DE BAJA RESISTENCIA (0 - 1 OHM) - FIRMWARE OPTIMIZADO
 * MCU: PIC18F45K80 (Oscilador Interno 16 MHz)
 * Compilador: mikroC PRO for PIC
 * =============================================================
 *
 * CONEXIONES DE HARDWARE:
 * - RA0 / AN0 (Pin 2)  <- N_BAT (Divisor 22k / 22k de Bateria)
 * - RA1 / AN1 (Pin 3)  <- VOLT_R (Salida del INA333, G = 41)
 * - RB0       (Pin 33) <- CHRG del TP4056 (0 = Cargando, 1 = No cargando)
 * - RC6 / TX1 (Pin 25) -> RXD del modulo Wi-Fi ESP-01S
 * - RC7 / RX1 (Pin 26) <- TXD del modulo Wi-Fi ESP-01S
 * - RD0       (Pin 19) -> MED_EN (Control fisico fuente de 60 mA)
 *
 * FORMATO DE TRAMA UDP ENVIADA (Puerto 4210):
 * D:<seq>,<adc_an0>,<adc_an1>,<rb0>,<med_en>\n
 * Ejemplo: D:104,2610,830,1,1\n
 * =============================================================
 */

/* =============================================================
   1. CONFIGURACION DE RED Y UMBRALES FISICOS DEL ADC
   ============================================================= */

#define CFG_WIFI_SSID             "iPhone de Santiago"
#define CFG_WIFI_PASSWORD         "pagueinternet"
#define CFG_UDP_BROADCAST_IP      "255.255.255.255"

/*#define CFG_WIFI_SSID             "CASA_FUNKY"
#define CFG_WIFI_PASSWORD         "CasaFunky2934"
#define CFG_UDP_BROADCAST_IP      "255.255.255.255"  */

/*#define CFG_WIFI_SSID             "ComunidadUIS"
#define CFG_WIFI_PASSWORD         "Camilo6118"
#define CFG_UDP_BROADCAST_IP      "255.255.255.255"  */

/*
 * Umbrales enteros del ADC de 12 bits (VDD = 3.000 V, Divisor = 2.0):
 * - 3.40 V en bateria -> 1.70 V en AN0 -> 2321 cuentas
 * - 3.60 V en bateria -> 1.80 V en AN0 -> 2457 cuentas
 */
#define CFG_ADC_BAT_LOW_TH        2321
#define CFG_ADC_BAT_RESTORE_TH    2457

unsigned int   app_seq_counter   = 0;
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
    UART1_Write(13); // '\r'
    UART1_Write(10); // '\n'
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

/*
 * Inicializa el ESP-01 al arrancar. Si esta en simulacion y un "OK"
 * tarda o no llega, avanza al siguiente comando sin bloquear el PIC.
 */
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
    strcat(app_cmd_buffer, CFG_WIFI_SSID);
    strcat(app_cmd_buffer, "\",\"");
    strcat(app_cmd_buffer, CFG_WIFI_PASSWORD);
    strcat(app_cmd_buffer, "\"");
    App_ESP_SendLine(app_cmd_buffer);
    App_ESP_WaitFor("OK", 1500);

    App_ESP_SendLine("AT+CIPCLOSE");
    App_ESP_WaitFor("OK", 300);

    strcpy(app_cmd_buffer, "AT+CIPSTART=\"UDP\",\"");
    strcat(app_cmd_buffer, CFG_UDP_BROADCAST_IP);
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
    OSCCON = 0x72; // Oscilador interno a 16 MHz
    Delay_ms(20);

    LATA = 0x00; LATB = 0x00; LATC = 0x00; LATD = 0x00; LATE = 0x00;

    ANCON0 = 0x03; // AN0 y AN1 analogicos
    ANCON1 = 0x00;

    CM1CON = 0x00;
    CM2CON = 0x00;

    TRISA.B0 = 1;  // RA0 / AN0 = N_BAT (Entrada)
    TRISA.B1 = 1;  // RA1 / AN1 = VOLT_R (Entrada)
    TRISB.B0 = 1;  // RB0       = CHRG TP4056 (Entrada)
    TRISC.B6 = 0;  // RC6 / TX1 = Salida UART
    TRISC.B7 = 1;  // RC7 / RX1 = Entrada UART
    TRISD.B0 = 0;  // RD0       = MED_EN (Salida control fuente 60 mA)

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
        /* 1. Leer voltaje de bateria en AN0 y nivel electrico de RB0 (CHRG) */
        adc_an0_bat = App_ADC_Average32(0);
        rb0_level   = (PORTB.B0 == 0) ? 0 : 1;

        /* 2. Histeresis de proteccion por bateria baja en el propio PIC */
        if(adc_an0_bat <= CFG_ADC_BAT_LOW_TH)
        {
            app_low_bat_latch = 1;
        }
        else if(adc_an0_bat >= CFG_ADC_BAT_RESTORE_TH)
        {
            app_low_bat_latch = 0;
        }

        /* 3. Control fisico autonomo de la fuente de corriente de 60 mA (RD0) */
        if((rb0_level == 0) || (app_low_bat_latch == 1))
        {
            LATD.B0      = 0;
            med_en_state = 0;
            adc_an1_res  = 0;
        }
        else
        {
            med_en_state = 1;
            LATD.B0      = 1;
            Delay_ms(10);
            adc_an1_res  = App_ADC_Average32(1);
            LATD.B0      = 0;
        }

        /* 4. Transmitir trama: D:<seq>,<adc_an0>,<adc_an1>,<rb0>,<med_en>\n */
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
        UART1_Write(10); // '\n'

        Delay_ms(300);
    }
}