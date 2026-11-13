
_App_UART_SendUInt:

;Programacion_PIC.c,52 :: 		void App_UART_SendUInt(unsigned int number_val)
;Programacion_PIC.c,54 :: 		unsigned short idx = 0;
	CLRF        App_UART_SendUInt_idx_L0+0 
;Programacion_PIC.c,55 :: 		WordToStr(number_val, app_num_buffer);
	MOVF        FARG_App_UART_SendUInt_number_val+0, 0 
	MOVWF       FARG_WordToStr_input+0 
	MOVF        FARG_App_UART_SendUInt_number_val+1, 0 
	MOVWF       FARG_WordToStr_input+1 
	MOVLW       _app_num_buffer+0
	MOVWF       FARG_WordToStr_output+0 
	MOVLW       hi_addr(_app_num_buffer+0)
	MOVWF       FARG_WordToStr_output+1 
	CALL        _WordToStr+0, 0
;Programacion_PIC.c,56 :: 		while(app_num_buffer[idx] == ' ')
L_App_UART_SendUInt0:
	MOVLW       _app_num_buffer+0
	MOVWF       FSR0L+0 
	MOVLW       hi_addr(_app_num_buffer+0)
	MOVWF       FSR0L+1 
	MOVF        App_UART_SendUInt_idx_L0+0, 0 
	ADDWF       FSR0L+0, 1 
	BTFSC       STATUS+0, 0 
	INCF        FSR0L+1, 1 
	MOVF        POSTINC0+0, 0 
	XORLW       32
	BTFSS       STATUS+0, 2 
	GOTO        L_App_UART_SendUInt1
;Programacion_PIC.c,58 :: 		idx++;
	INCF        App_UART_SendUInt_idx_L0+0, 1 
;Programacion_PIC.c,59 :: 		}
	GOTO        L_App_UART_SendUInt0
L_App_UART_SendUInt1:
;Programacion_PIC.c,60 :: 		UART1_Write_Text(&app_num_buffer[idx]);
	MOVLW       _app_num_buffer+0
	MOVWF       FARG_UART1_Write_Text_uart_text+0 
	MOVLW       hi_addr(_app_num_buffer+0)
	MOVWF       FARG_UART1_Write_Text_uart_text+1 
	MOVF        App_UART_SendUInt_idx_L0+0, 0 
	ADDWF       FARG_UART1_Write_Text_uart_text+0, 1 
	BTFSC       STATUS+0, 0 
	INCF        FARG_UART1_Write_Text_uart_text+1, 1 
	CALL        _UART1_Write_Text+0, 0
;Programacion_PIC.c,61 :: 		}
L_end_App_UART_SendUInt:
	RETURN      0
; end of _App_UART_SendUInt

_App_ESP_SendLine:

;Programacion_PIC.c,63 :: 		void App_ESP_SendLine(char *text_line)
;Programacion_PIC.c,65 :: 		UART1_Write_Text(text_line);
	MOVF        FARG_App_ESP_SendLine_text_line+0, 0 
	MOVWF       FARG_UART1_Write_Text_uart_text+0 
	MOVF        FARG_App_ESP_SendLine_text_line+1, 0 
	MOVWF       FARG_UART1_Write_Text_uart_text+1 
	CALL        _UART1_Write_Text+0, 0
;Programacion_PIC.c,66 :: 		UART1_Write(13); // '\r'
	MOVLW       13
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,67 :: 		UART1_Write(10); // '\n'
	MOVLW       10
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,68 :: 		}
L_end_App_ESP_SendLine:
	RETURN      0
; end of _App_ESP_SendLine

_App_ESP_ClearBuffer:

;Programacion_PIC.c,70 :: 		void App_ESP_ClearBuffer()
;Programacion_PIC.c,72 :: 		while(UART1_Data_Ready())
L_App_ESP_ClearBuffer2:
	CALL        _UART1_Data_Ready+0, 0
	MOVF        R0, 1 
	BTFSC       STATUS+0, 2 
	GOTO        L_App_ESP_ClearBuffer3
;Programacion_PIC.c,74 :: 		UART1_Read();
	CALL        _UART1_Read+0, 0
;Programacion_PIC.c,75 :: 		}
	GOTO        L_App_ESP_ClearBuffer2
L_App_ESP_ClearBuffer3:
;Programacion_PIC.c,76 :: 		}
L_end_App_ESP_ClearBuffer:
	RETURN      0
; end of _App_ESP_ClearBuffer

_App_ESP_WaitFor:

;Programacion_PIC.c,78 :: 		unsigned short App_ESP_WaitFor(char *expected_str, unsigned int timeout_ms)
;Programacion_PIC.c,80 :: 		unsigned short match_pos = 0;
	CLRF        App_ESP_WaitFor_match_pos_L0+0 
;Programacion_PIC.c,84 :: 		exp_len = strlen(expected_str);
	MOVF        FARG_App_ESP_WaitFor_expected_str+0, 0 
	MOVWF       FARG_strlen_s+0 
	MOVF        FARG_App_ESP_WaitFor_expected_str+1, 0 
	MOVWF       FARG_strlen_s+1 
	CALL        _strlen+0, 0
	MOVF        R0, 0 
	MOVWF       App_ESP_WaitFor_exp_len_L0+0 
;Programacion_PIC.c,86 :: 		while(timeout_ms > 0)
L_App_ESP_WaitFor4:
	MOVLW       0
	MOVWF       R0 
	MOVF        FARG_App_ESP_WaitFor_timeout_ms+1, 0 
	SUBWF       R0, 0 
	BTFSS       STATUS+0, 2 
	GOTO        L__App_ESP_WaitFor44
	MOVF        FARG_App_ESP_WaitFor_timeout_ms+0, 0 
	SUBLW       0
L__App_ESP_WaitFor44:
	BTFSC       STATUS+0, 0 
	GOTO        L_App_ESP_WaitFor5
;Programacion_PIC.c,88 :: 		if(UART1_Data_Ready())
	CALL        _UART1_Data_Ready+0, 0
	MOVF        R0, 1 
	BTFSC       STATUS+0, 2 
	GOTO        L_App_ESP_WaitFor6
;Programacion_PIC.c,90 :: 		rx_char = UART1_Read();
	CALL        _UART1_Read+0, 0
	MOVF        R0, 0 
	MOVWF       App_ESP_WaitFor_rx_char_L0+0 
;Programacion_PIC.c,91 :: 		if(rx_char == expected_str[match_pos])
	MOVF        App_ESP_WaitFor_match_pos_L0+0, 0 
	ADDWF       FARG_App_ESP_WaitFor_expected_str+0, 0 
	MOVWF       FSR2L+0 
	MOVLW       0
	ADDWFC      FARG_App_ESP_WaitFor_expected_str+1, 0 
	MOVWF       FSR2L+1 
	MOVF        R0, 0 
	XORWF       POSTINC2+0, 0 
	BTFSS       STATUS+0, 2 
	GOTO        L_App_ESP_WaitFor7
;Programacion_PIC.c,93 :: 		match_pos++;
	INCF        App_ESP_WaitFor_match_pos_L0+0, 1 
;Programacion_PIC.c,94 :: 		if(match_pos == exp_len)
	MOVF        App_ESP_WaitFor_match_pos_L0+0, 0 
	XORWF       App_ESP_WaitFor_exp_len_L0+0, 0 
	BTFSS       STATUS+0, 2 
	GOTO        L_App_ESP_WaitFor8
;Programacion_PIC.c,96 :: 		return 1;
	MOVLW       1
	MOVWF       R0 
	GOTO        L_end_App_ESP_WaitFor
;Programacion_PIC.c,97 :: 		}
L_App_ESP_WaitFor8:
;Programacion_PIC.c,98 :: 		}
	GOTO        L_App_ESP_WaitFor9
L_App_ESP_WaitFor7:
;Programacion_PIC.c,99 :: 		else if(rx_char == expected_str[0])
	MOVFF       FARG_App_ESP_WaitFor_expected_str+0, FSR2L+0
	MOVFF       FARG_App_ESP_WaitFor_expected_str+1, FSR2H+0
	MOVF        App_ESP_WaitFor_rx_char_L0+0, 0 
	XORWF       POSTINC2+0, 0 
	BTFSS       STATUS+0, 2 
	GOTO        L_App_ESP_WaitFor10
;Programacion_PIC.c,101 :: 		match_pos = 1;
	MOVLW       1
	MOVWF       App_ESP_WaitFor_match_pos_L0+0 
;Programacion_PIC.c,102 :: 		}
	GOTO        L_App_ESP_WaitFor11
L_App_ESP_WaitFor10:
;Programacion_PIC.c,105 :: 		match_pos = 0;
	CLRF        App_ESP_WaitFor_match_pos_L0+0 
;Programacion_PIC.c,106 :: 		}
L_App_ESP_WaitFor11:
L_App_ESP_WaitFor9:
;Programacion_PIC.c,107 :: 		}
L_App_ESP_WaitFor6:
;Programacion_PIC.c,108 :: 		Delay_ms(1);
	MOVLW       6
	MOVWF       R12, 0
	MOVLW       48
	MOVWF       R13, 0
L_App_ESP_WaitFor12:
	DECFSZ      R13, 1, 1
	BRA         L_App_ESP_WaitFor12
	DECFSZ      R12, 1, 1
	BRA         L_App_ESP_WaitFor12
	NOP
;Programacion_PIC.c,109 :: 		timeout_ms--;
	MOVLW       1
	SUBWF       FARG_App_ESP_WaitFor_timeout_ms+0, 1 
	MOVLW       0
	SUBWFB      FARG_App_ESP_WaitFor_timeout_ms+1, 1 
;Programacion_PIC.c,110 :: 		}
	GOTO        L_App_ESP_WaitFor4
L_App_ESP_WaitFor5:
;Programacion_PIC.c,111 :: 		return 0;
	CLRF        R0 
;Programacion_PIC.c,112 :: 		}
L_end_App_ESP_WaitFor:
	RETURN      0
; end of _App_ESP_WaitFor

_App_ESP_InitUDP:

;Programacion_PIC.c,118 :: 		void App_ESP_InitUDP()
;Programacion_PIC.c,120 :: 		UART1_Write_Text("+++");
	MOVLW       ?lstr1_Programacion_PIC+0
	MOVWF       FARG_UART1_Write_Text_uart_text+0 
	MOVLW       hi_addr(?lstr1_Programacion_PIC+0)
	MOVWF       FARG_UART1_Write_Text_uart_text+1 
	CALL        _UART1_Write_Text+0, 0
;Programacion_PIC.c,121 :: 		Delay_ms(500);
	MOVLW       11
	MOVWF       R11, 0
	MOVLW       38
	MOVWF       R12, 0
	MOVLW       93
	MOVWF       R13, 0
L_App_ESP_InitUDP13:
	DECFSZ      R13, 1, 1
	BRA         L_App_ESP_InitUDP13
	DECFSZ      R12, 1, 1
	BRA         L_App_ESP_InitUDP13
	DECFSZ      R11, 1, 1
	BRA         L_App_ESP_InitUDP13
	NOP
	NOP
;Programacion_PIC.c,122 :: 		App_ESP_ClearBuffer();
	CALL        _App_ESP_ClearBuffer+0, 0
;Programacion_PIC.c,124 :: 		App_ESP_SendLine("AT");
	MOVLW       ?lstr2_Programacion_PIC+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(?lstr2_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,125 :: 		App_ESP_WaitFor("OK", 400);
	MOVLW       ?lstr3_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr3_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       144
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,127 :: 		App_ESP_SendLine("ATE0");
	MOVLW       ?lstr4_Programacion_PIC+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(?lstr4_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,128 :: 		App_ESP_WaitFor("OK", 400);
	MOVLW       ?lstr5_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr5_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       144
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,130 :: 		App_ESP_SendLine("AT+CWMODE=1");
	MOVLW       ?lstr6_Programacion_PIC+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(?lstr6_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,131 :: 		App_ESP_WaitFor("OK", 400);
	MOVLW       ?lstr7_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr7_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       144
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,133 :: 		App_ESP_SendLine("AT+CIPMUX=0");
	MOVLW       ?lstr8_Programacion_PIC+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(?lstr8_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,134 :: 		App_ESP_WaitFor("OK", 400);
	MOVLW       ?lstr9_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr9_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       144
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,136 :: 		strcpy(app_cmd_buffer, "AT+CWJAP=\"");
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcpy_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcpy_to+1 
	MOVLW       ?lstr10_Programacion_PIC+0
	MOVWF       FARG_strcpy_from+0 
	MOVLW       hi_addr(?lstr10_Programacion_PIC+0)
	MOVWF       FARG_strcpy_from+1 
	CALL        _strcpy+0, 0
;Programacion_PIC.c,137 :: 		strcat(app_cmd_buffer, CFG_WIFI_SSID);
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcat_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcat_to+1 
	MOVLW       ?lstr11_Programacion_PIC+0
	MOVWF       FARG_strcat_from+0 
	MOVLW       hi_addr(?lstr11_Programacion_PIC+0)
	MOVWF       FARG_strcat_from+1 
	CALL        _strcat+0, 0
;Programacion_PIC.c,138 :: 		strcat(app_cmd_buffer, "\",\"");
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcat_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcat_to+1 
	MOVLW       ?lstr12_Programacion_PIC+0
	MOVWF       FARG_strcat_from+0 
	MOVLW       hi_addr(?lstr12_Programacion_PIC+0)
	MOVWF       FARG_strcat_from+1 
	CALL        _strcat+0, 0
;Programacion_PIC.c,139 :: 		strcat(app_cmd_buffer, CFG_WIFI_PASSWORD);
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcat_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcat_to+1 
	MOVLW       ?lstr13_Programacion_PIC+0
	MOVWF       FARG_strcat_from+0 
	MOVLW       hi_addr(?lstr13_Programacion_PIC+0)
	MOVWF       FARG_strcat_from+1 
	CALL        _strcat+0, 0
;Programacion_PIC.c,140 :: 		strcat(app_cmd_buffer, "\"");
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcat_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcat_to+1 
	MOVLW       ?lstr14_Programacion_PIC+0
	MOVWF       FARG_strcat_from+0 
	MOVLW       hi_addr(?lstr14_Programacion_PIC+0)
	MOVWF       FARG_strcat_from+1 
	CALL        _strcat+0, 0
;Programacion_PIC.c,141 :: 		App_ESP_SendLine(app_cmd_buffer);
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,142 :: 		App_ESP_WaitFor("OK", 1500);
	MOVLW       ?lstr15_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr15_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       220
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       5
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,144 :: 		App_ESP_SendLine("AT+CIPCLOSE");
	MOVLW       ?lstr16_Programacion_PIC+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(?lstr16_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,145 :: 		App_ESP_WaitFor("OK", 300);
	MOVLW       ?lstr17_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr17_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       44
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,147 :: 		strcpy(app_cmd_buffer, "AT+CIPSTART=\"UDP\",\"");
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcpy_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcpy_to+1 
	MOVLW       ?lstr18_Programacion_PIC+0
	MOVWF       FARG_strcpy_from+0 
	MOVLW       hi_addr(?lstr18_Programacion_PIC+0)
	MOVWF       FARG_strcpy_from+1 
	CALL        _strcpy+0, 0
;Programacion_PIC.c,148 :: 		strcat(app_cmd_buffer, CFG_UDP_BROADCAST_IP);
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcat_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcat_to+1 
	MOVLW       ?lstr19_Programacion_PIC+0
	MOVWF       FARG_strcat_from+0 
	MOVLW       hi_addr(?lstr19_Programacion_PIC+0)
	MOVWF       FARG_strcat_from+1 
	CALL        _strcat+0, 0
;Programacion_PIC.c,149 :: 		strcat(app_cmd_buffer, "\",4210,4210,0");
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_strcat_to+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_strcat_to+1 
	MOVLW       ?lstr20_Programacion_PIC+0
	MOVWF       FARG_strcat_from+0 
	MOVLW       hi_addr(?lstr20_Programacion_PIC+0)
	MOVWF       FARG_strcat_from+1 
	CALL        _strcat+0, 0
;Programacion_PIC.c,150 :: 		App_ESP_SendLine(app_cmd_buffer);
	MOVLW       _app_cmd_buffer+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(_app_cmd_buffer+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,151 :: 		App_ESP_WaitFor("OK", 500);
	MOVLW       ?lstr21_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr21_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       244
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,153 :: 		App_ESP_SendLine("AT+CIPMODE=1");
	MOVLW       ?lstr22_Programacion_PIC+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(?lstr22_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,154 :: 		App_ESP_WaitFor("OK", 400);
	MOVLW       ?lstr23_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr23_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       144
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,156 :: 		App_ESP_SendLine("AT+CIPSEND");
	MOVLW       ?lstr24_Programacion_PIC+0
	MOVWF       FARG_App_ESP_SendLine_text_line+0 
	MOVLW       hi_addr(?lstr24_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_SendLine_text_line+1 
	CALL        _App_ESP_SendLine+0, 0
;Programacion_PIC.c,157 :: 		App_ESP_WaitFor(">", 400);
	MOVLW       ?lstr25_Programacion_PIC+0
	MOVWF       FARG_App_ESP_WaitFor_expected_str+0 
	MOVLW       hi_addr(?lstr25_Programacion_PIC+0)
	MOVWF       FARG_App_ESP_WaitFor_expected_str+1 
	MOVLW       144
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+0 
	MOVLW       1
	MOVWF       FARG_App_ESP_WaitFor_timeout_ms+1 
	CALL        _App_ESP_WaitFor+0, 0
;Programacion_PIC.c,158 :: 		}
L_end_App_ESP_InitUDP:
	RETURN      0
; end of _App_ESP_InitUDP

_App_ADC_Average32:

;Programacion_PIC.c,160 :: 		unsigned int App_ADC_Average32(unsigned short channel)
;Programacion_PIC.c,163 :: 		unsigned long acc = 0;
	CLRF        App_ADC_Average32_acc_L0+0 
	CLRF        App_ADC_Average32_acc_L0+1 
	CLRF        App_ADC_Average32_acc_L0+2 
	CLRF        App_ADC_Average32_acc_L0+3 
;Programacion_PIC.c,165 :: 		ADC_Read(channel);
	MOVF        FARG_App_ADC_Average32_channel+0, 0 
	MOVWF       FARG_ADC_Read_channel+0 
	CALL        _ADC_Read+0, 0
;Programacion_PIC.c,166 :: 		Delay_us(100);
	MOVLW       133
	MOVWF       R13, 0
L_App_ADC_Average3214:
	DECFSZ      R13, 1, 1
	BRA         L_App_ADC_Average3214
;Programacion_PIC.c,168 :: 		for(i = 0; i < 32; i++)
	CLRF        App_ADC_Average32_i_L0+0 
L_App_ADC_Average3215:
	MOVLW       32
	SUBWF       App_ADC_Average32_i_L0+0, 0 
	BTFSC       STATUS+0, 0 
	GOTO        L_App_ADC_Average3216
;Programacion_PIC.c,170 :: 		acc += ADC_Read(channel);
	MOVF        FARG_App_ADC_Average32_channel+0, 0 
	MOVWF       FARG_ADC_Read_channel+0 
	CALL        _ADC_Read+0, 0
	MOVF        R0, 0 
	ADDWF       App_ADC_Average32_acc_L0+0, 1 
	MOVF        R1, 0 
	ADDWFC      App_ADC_Average32_acc_L0+1, 1 
	MOVLW       0
	ADDWFC      App_ADC_Average32_acc_L0+2, 1 
	ADDWFC      App_ADC_Average32_acc_L0+3, 1 
;Programacion_PIC.c,171 :: 		Delay_us(100);
	MOVLW       133
	MOVWF       R13, 0
L_App_ADC_Average3218:
	DECFSZ      R13, 1, 1
	BRA         L_App_ADC_Average3218
;Programacion_PIC.c,168 :: 		for(i = 0; i < 32; i++)
	INCF        App_ADC_Average32_i_L0+0, 1 
;Programacion_PIC.c,172 :: 		}
	GOTO        L_App_ADC_Average3215
L_App_ADC_Average3216:
;Programacion_PIC.c,174 :: 		return (unsigned int)(acc >> 5);
	MOVLW       5
	MOVWF       R4 
	MOVF        App_ADC_Average32_acc_L0+0, 0 
	MOVWF       R0 
	MOVF        App_ADC_Average32_acc_L0+1, 0 
	MOVWF       R1 
	MOVF        App_ADC_Average32_acc_L0+2, 0 
	MOVWF       R2 
	MOVF        App_ADC_Average32_acc_L0+3, 0 
	MOVWF       R3 
	MOVF        R4, 0 
L__App_ADC_Average3247:
	BZ          L__App_ADC_Average3248
	RRCF        R3, 1 
	RRCF        R2, 1 
	RRCF        R1, 1 
	RRCF        R0, 1 
	BCF         R3, 7 
	ADDLW       255
	GOTO        L__App_ADC_Average3247
L__App_ADC_Average3248:
;Programacion_PIC.c,175 :: 		}
L_end_App_ADC_Average32:
	RETURN      0
; end of _App_ADC_Average32

_App_HardwareInit:

;Programacion_PIC.c,177 :: 		void App_HardwareInit()
;Programacion_PIC.c,179 :: 		OSCCON = 0x72; // Oscilador interno a 16 MHz
	MOVLW       114
	MOVWF       OSCCON+0 
;Programacion_PIC.c,180 :: 		Delay_ms(20);
	MOVLW       104
	MOVWF       R12, 0
	MOVLW       228
	MOVWF       R13, 0
L_App_HardwareInit19:
	DECFSZ      R13, 1, 1
	BRA         L_App_HardwareInit19
	DECFSZ      R12, 1, 1
	BRA         L_App_HardwareInit19
	NOP
;Programacion_PIC.c,182 :: 		LATA = 0x00; LATB = 0x00; LATC = 0x00; LATD = 0x00; LATE = 0x00;
	CLRF        LATA+0 
	CLRF        LATB+0 
	CLRF        LATC+0 
	CLRF        LATD+0 
	CLRF        LATE+0 
;Programacion_PIC.c,184 :: 		ANCON0 = 0x03; // AN0 y AN1 analogicos
	MOVLW       3
	MOVWF       ANCON0+0 
;Programacion_PIC.c,185 :: 		ANCON1 = 0x00;
	CLRF        ANCON1+0 
;Programacion_PIC.c,187 :: 		CM1CON = 0x00;
	CLRF        CM1CON+0 
;Programacion_PIC.c,188 :: 		CM2CON = 0x00;
	CLRF        CM2CON+0 
;Programacion_PIC.c,190 :: 		TRISA.B0 = 1;  // RA0 / AN0 = N_BAT (Entrada)
	BSF         TRISA+0, 0 
;Programacion_PIC.c,191 :: 		TRISA.B1 = 1;  // RA1 / AN1 = VOLT_R (Entrada)
	BSF         TRISA+0, 1 
;Programacion_PIC.c,192 :: 		TRISB.B0 = 1;  // RB0       = CHRG TP4056 (Entrada)
	BSF         TRISB+0, 0 
;Programacion_PIC.c,193 :: 		TRISC.B6 = 0;  // RC6 / TX1 = Salida UART
	BCF         TRISC+0, 6 
;Programacion_PIC.c,194 :: 		TRISC.B7 = 1;  // RC7 / RX1 = Entrada UART
	BSF         TRISC+0, 7 
;Programacion_PIC.c,195 :: 		TRISD.B0 = 0;  // RD0       = MED_EN (Salida control fuente 60 mA)
	BCF         TRISD+0, 0 
;Programacion_PIC.c,197 :: 		LATD.B0 = 0;
	BCF         LATD+0, 0 
;Programacion_PIC.c,199 :: 		ADC_Init();
	CALL        _ADC_Init+0, 0
;Programacion_PIC.c,200 :: 		Delay_ms(10);
	MOVLW       52
	MOVWF       R12, 0
	MOVLW       241
	MOVWF       R13, 0
L_App_HardwareInit20:
	DECFSZ      R13, 1, 1
	BRA         L_App_HardwareInit20
	DECFSZ      R12, 1, 1
	BRA         L_App_HardwareInit20
	NOP
	NOP
;Programacion_PIC.c,202 :: 		UART1_Init(115200);
	MOVLW       8
	MOVWF       SPBRG+0 
	BSF         TXSTA+0, 2, 0
	CALL        _UART1_Init+0, 0
;Programacion_PIC.c,203 :: 		Delay_ms(200);
	MOVLW       5
	MOVWF       R11, 0
	MOVLW       15
	MOVWF       R12, 0
	MOVLW       241
	MOVWF       R13, 0
L_App_HardwareInit21:
	DECFSZ      R13, 1, 1
	BRA         L_App_HardwareInit21
	DECFSZ      R12, 1, 1
	BRA         L_App_HardwareInit21
	DECFSZ      R11, 1, 1
	BRA         L_App_HardwareInit21
;Programacion_PIC.c,204 :: 		}
L_end_App_HardwareInit:
	RETURN      0
; end of _App_HardwareInit

_main:

;Programacion_PIC.c,206 :: 		void main()
;Programacion_PIC.c,213 :: 		App_HardwareInit();
	CALL        _App_HardwareInit+0, 0
;Programacion_PIC.c,214 :: 		App_ESP_InitUDP();
	CALL        _App_ESP_InitUDP+0, 0
;Programacion_PIC.c,216 :: 		while(1)
L_main22:
;Programacion_PIC.c,219 :: 		adc_an0_bat = App_ADC_Average32(0);
	CLRF        FARG_App_ADC_Average32_channel+0 
	CALL        _App_ADC_Average32+0, 0
	MOVF        R0, 0 
	MOVWF       main_adc_an0_bat_L0+0 
	MOVF        R1, 0 
	MOVWF       main_adc_an0_bat_L0+1 
;Programacion_PIC.c,220 :: 		rb0_level   = (PORTB.B0 == 0) ? 0 : 1;
	CLRF        R1 
	BTFSC       PORTB+0, 0 
	INCF        R1, 1 
	MOVF        R1, 0 
	XORLW       0
	BTFSS       STATUS+0, 2 
	GOTO        L_main24
	CLRF        ?FLOC___mainT80+0 
	GOTO        L_main25
L_main24:
	MOVLW       1
	MOVWF       ?FLOC___mainT80+0 
L_main25:
	MOVF        ?FLOC___mainT80+0, 0 
	MOVWF       main_rb0_level_L0+0 
;Programacion_PIC.c,223 :: 		if(adc_an0_bat <= CFG_ADC_BAT_LOW_TH)
	MOVF        main_adc_an0_bat_L0+1, 0 
	SUBLW       9
	BTFSS       STATUS+0, 2 
	GOTO        L__main51
	MOVF        main_adc_an0_bat_L0+0, 0 
	SUBLW       17
L__main51:
	BTFSS       STATUS+0, 0 
	GOTO        L_main26
;Programacion_PIC.c,225 :: 		app_low_bat_latch = 1;
	MOVLW       1
	MOVWF       _app_low_bat_latch+0 
;Programacion_PIC.c,226 :: 		}
	GOTO        L_main27
L_main26:
;Programacion_PIC.c,227 :: 		else if(adc_an0_bat >= CFG_ADC_BAT_RESTORE_TH)
	MOVLW       9
	SUBWF       main_adc_an0_bat_L0+1, 0 
	BTFSS       STATUS+0, 2 
	GOTO        L__main52
	MOVLW       153
	SUBWF       main_adc_an0_bat_L0+0, 0 
L__main52:
	BTFSS       STATUS+0, 0 
	GOTO        L_main28
;Programacion_PIC.c,229 :: 		app_low_bat_latch = 0;
	CLRF        _app_low_bat_latch+0 
;Programacion_PIC.c,230 :: 		}
L_main28:
L_main27:
;Programacion_PIC.c,233 :: 		if((rb0_level == 0) || (app_low_bat_latch == 1))
	MOVF        main_rb0_level_L0+0, 0 
	XORLW       0
	BTFSC       STATUS+0, 2 
	GOTO        L__main39
	MOVF        _app_low_bat_latch+0, 0 
	XORLW       1
	BTFSC       STATUS+0, 2 
	GOTO        L__main39
	GOTO        L_main31
L__main39:
;Programacion_PIC.c,235 :: 		LATD.B0      = 0;
	BCF         LATD+0, 0 
;Programacion_PIC.c,236 :: 		med_en_state = 0;
	CLRF        main_med_en_state_L0+0 
;Programacion_PIC.c,237 :: 		adc_an1_res  = 0;
	CLRF        main_adc_an1_res_L0+0 
	CLRF        main_adc_an1_res_L0+1 
;Programacion_PIC.c,238 :: 		}
	GOTO        L_main32
L_main31:
;Programacion_PIC.c,241 :: 		med_en_state = 1;
	MOVLW       1
	MOVWF       main_med_en_state_L0+0 
;Programacion_PIC.c,242 :: 		LATD.B0      = 1;
	BSF         LATD+0, 0 
;Programacion_PIC.c,243 :: 		Delay_ms(10);
	MOVLW       52
	MOVWF       R12, 0
	MOVLW       241
	MOVWF       R13, 0
L_main33:
	DECFSZ      R13, 1, 1
	BRA         L_main33
	DECFSZ      R12, 1, 1
	BRA         L_main33
	NOP
	NOP
;Programacion_PIC.c,244 :: 		adc_an1_res  = App_ADC_Average32(1);
	MOVLW       1
	MOVWF       FARG_App_ADC_Average32_channel+0 
	CALL        _App_ADC_Average32+0, 0
	MOVF        R0, 0 
	MOVWF       main_adc_an1_res_L0+0 
	MOVF        R1, 0 
	MOVWF       main_adc_an1_res_L0+1 
;Programacion_PIC.c,245 :: 		LATD.B0      = 0;
	BCF         LATD+0, 0 
;Programacion_PIC.c,246 :: 		}
L_main32:
;Programacion_PIC.c,249 :: 		UART1_Write_Text("D:");
	MOVLW       ?lstr26_Programacion_PIC+0
	MOVWF       FARG_UART1_Write_Text_uart_text+0 
	MOVLW       hi_addr(?lstr26_Programacion_PIC+0)
	MOVWF       FARG_UART1_Write_Text_uart_text+1 
	CALL        _UART1_Write_Text+0, 0
;Programacion_PIC.c,250 :: 		App_UART_SendUInt(app_seq_counter++);
	MOVF        _app_seq_counter+0, 0 
	MOVWF       FARG_App_UART_SendUInt_number_val+0 
	MOVF        _app_seq_counter+1, 0 
	MOVWF       FARG_App_UART_SendUInt_number_val+1 
	CALL        _App_UART_SendUInt+0, 0
	INFSNZ      _app_seq_counter+0, 1 
	INCF        _app_seq_counter+1, 1 
;Programacion_PIC.c,251 :: 		UART1_Write(',');
	MOVLW       44
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,252 :: 		App_UART_SendUInt(adc_an0_bat);
	MOVF        main_adc_an0_bat_L0+0, 0 
	MOVWF       FARG_App_UART_SendUInt_number_val+0 
	MOVF        main_adc_an0_bat_L0+1, 0 
	MOVWF       FARG_App_UART_SendUInt_number_val+1 
	CALL        _App_UART_SendUInt+0, 0
;Programacion_PIC.c,253 :: 		UART1_Write(',');
	MOVLW       44
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,254 :: 		App_UART_SendUInt(adc_an1_res);
	MOVF        main_adc_an1_res_L0+0, 0 
	MOVWF       FARG_App_UART_SendUInt_number_val+0 
	MOVF        main_adc_an1_res_L0+1, 0 
	MOVWF       FARG_App_UART_SendUInt_number_val+1 
	CALL        _App_UART_SendUInt+0, 0
;Programacion_PIC.c,255 :: 		UART1_Write(',');
	MOVLW       44
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,256 :: 		UART1_Write(rb0_level ? '1' : '0');
	MOVF        main_rb0_level_L0+0, 1 
	BTFSC       STATUS+0, 2 
	GOTO        L_main34
	MOVLW       49
	MOVWF       ?FLOC___mainT94+0 
	GOTO        L_main35
L_main34:
	MOVLW       48
	MOVWF       ?FLOC___mainT94+0 
L_main35:
	MOVF        ?FLOC___mainT94+0, 0 
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,257 :: 		UART1_Write(',');
	MOVLW       44
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,258 :: 		UART1_Write(med_en_state ? '1' : '0');
	MOVF        main_med_en_state_L0+0, 1 
	BTFSC       STATUS+0, 2 
	GOTO        L_main36
	MOVLW       49
	MOVWF       ?FLOC___mainT95+0 
	GOTO        L_main37
L_main36:
	MOVLW       48
	MOVWF       ?FLOC___mainT95+0 
L_main37:
	MOVF        ?FLOC___mainT95+0, 0 
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,259 :: 		UART1_Write(10); // '\n'
	MOVLW       10
	MOVWF       FARG_UART1_Write_data_+0 
	CALL        _UART1_Write+0, 0
;Programacion_PIC.c,261 :: 		Delay_ms(300);
	MOVLW       7
	MOVWF       R11, 0
	MOVLW       23
	MOVWF       R12, 0
	MOVLW       106
	MOVWF       R13, 0
L_main38:
	DECFSZ      R13, 1, 1
	BRA         L_main38
	DECFSZ      R12, 1, 1
	BRA         L_main38
	DECFSZ      R11, 1, 1
	BRA         L_main38
	NOP
;Programacion_PIC.c,262 :: 		}
	GOTO        L_main22
;Programacion_PIC.c,263 :: 		}
L_end_main:
	GOTO        $+0
; end of _main
